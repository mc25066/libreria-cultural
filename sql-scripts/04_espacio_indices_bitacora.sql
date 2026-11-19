-- ============================================================================
-- LIBRERÍA CULTURAL "EL SABER"
-- Script 04: Espacio en Disco, Particionamiento, Índices y Bitácora
-- Ejecutar después de 01, 02 y 03 (PostgreSQL 14+ / 16 / 17)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. OPTIMIZACIÓN DE ALMACENAMIENTO Y CONTROL DE BLOAT (FILLFACTOR)
-- ----------------------------------------------------------------------------
-- 'libro' recibe actualizaciones constantes en stock_venta y stock_biblioteca.
-- 'prestamo' y 'multa' actualizan su columna 'estado' durante su ciclo de vida.
ALTER TABLE libro    SET (fillfactor = 85);
ALTER TABLE prestamo SET (fillfactor = 90);
ALTER TABLE multa    SET (fillfactor = 90);

-- ----------------------------------------------------------------------------
-- 2. MANEJO AVANZADO DE ÍNDICES (Ahorro de espacio y aceleración de consultas)
-- ----------------------------------------------------------------------------
-- Nota: En producción activa, usar CREATE INDEX CONCURRENTLY fuera de bloques BEGIN/COMMIT.

-- Reemplazar índices completos de baja cardinalidad (definidos en script 01)
-- por índices parciales que solo almacenan filas activas/pendientes.
DROP INDEX IF EXISTS idx_orden_compra_estado;
DROP INDEX IF EXISTS idx_prestamo_estado;

-- A) Índices parciales
CREATE INDEX IF NOT EXISTS idx_orden_compra_pendiente
    ON orden_compra (fecha_orden, id_proveedor)
    WHERE estado = 'pendiente';

CREATE INDEX IF NOT EXISTS idx_prestamo_activo_vencido
    ON prestamo (fecha_devolucion_estimada, id_cliente)
    WHERE estado IN ('activo', 'vencido');

CREATE INDEX IF NOT EXISTS idx_multa_pendiente
    ON multa (id_prestamo, fecha_generacion)
    WHERE estado = 'pendiente';

CREATE INDEX IF NOT EXISTS idx_libro_stock_venta
    ON libro (titulo)
    WHERE stock_venta > 0;

CREATE INDEX IF NOT EXISTS idx_libro_stock_biblioteca
    ON libro (titulo)
    WHERE stock_biblioteca > 0;

-- B) Índice multicolumna (compuesto) para historial de compras por cliente
CREATE INDEX IF NOT EXISTS idx_venta_cliente_fecha
    ON venta (id_cliente, fecha_venta DESC);

-- C) Índices de expresión (búsquedas insensibles a mayúsculas/minúsculas)
CREATE INDEX IF NOT EXISTS idx_libro_titulo_lower
    ON libro (LOWER(titulo));

CREATE INDEX IF NOT EXISTS idx_cliente_nombre_lower
    ON cliente (LOWER(apellido), LOWER(nombre));

-- D) Índice GIN con trigramas para búsquedas parciales (ILIKE '%palabra%')
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_libro_titulo_trgm
    ON libro USING gin (titulo gin_trgm_ops);

-- E) Mantenimiento de fillfactor en índice + reconstrucción (Unidad #4)
-- Cambiar fillfactor en un índice no aplica hasta ejecutar REINDEX:
-- ALTER INDEX idx_libro_titulo_lower SET (fillfactor = 80);
-- REINDEX (VERBOSE) INDEX idx_libro_titulo_lower;

-- ----------------------------------------------------------------------------
-- 3. BITÁCORA DE AUDITORÍA PARTICIONADA (Esquema aislado e inmutable)
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS auditoria;

-- La PK incluye obligatoriamente la columna de partición (fecha_hora)
CREATE TABLE IF NOT EXISTS auditoria.bitacora_auditoria (
    id_bitacora      BIGSERIAL,
    id_transaccion   BIGINT      NOT NULL DEFAULT txid_current(),
    fecha_hora       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario_bd       NAME        NOT NULL DEFAULT CURRENT_USER,
    aplicacion       TEXT                 DEFAULT current_setting('application_name', true),
    ip_cliente       INET                 DEFAULT inet_client_addr(),
    tabla_afectada   TEXT        NOT NULL,
    operacion        CHAR(6)     NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    datos_anteriores JSONB,
    datos_nuevos     JSONB,
    PRIMARY KEY (id_bitacora, fecha_hora)
) PARTITION BY RANGE (fecha_hora);

-- Particiones anuales (crear la del año siguiente antes de diciembre)
CREATE TABLE IF NOT EXISTS auditoria.bitacora_auditoria_2025
    PARTITION OF auditoria.bitacora_auditoria
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS auditoria.bitacora_auditoria_2026
    PARTITION OF auditoria.bitacora_auditoria
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS auditoria.bitacora_auditoria_2027
    PARTITION OF auditoria.bitacora_auditoria
    FOR VALUES FROM ('2027-01-01 00:00:00+00') TO ('2028-01-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS auditoria.bitacora_auditoria_default
    PARTITION OF auditoria.bitacora_auditoria DEFAULT;

CREATE INDEX IF NOT EXISTS idx_bitacora_tabla_fecha
    ON auditoria.bitacora_auditoria (tabla_afectada, fecha_hora DESC);

-- Función trigger para registrar valor antiguo y valor nuevo
CREATE OR REPLACE FUNCTION auditoria.fn_registrar_bitacora()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auditoria, pg_temp
AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO auditoria.bitacora_auditoria (tabla_afectada, operacion, datos_anteriores)
        VALUES (TG_TABLE_NAME, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO auditoria.bitacora_auditoria (tabla_afectada, operacion, datos_anteriores, datos_nuevos)
        VALUES (TG_TABLE_NAME, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO auditoria.bitacora_auditoria (tabla_afectada, operacion, datos_nuevos)
        VALUES (TG_TABLE_NAME, 'INSERT', to_jsonb(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;

-- Protección de trazas: impedir UPDATE o DELETE sobre la bitácora
CREATE OR REPLACE FUNCTION auditoria.fn_proteger_bitacora()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'Operación denegada: las trazas de auditoría son inmutables.';
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_bitacora ON auditoria.bitacora_auditoria;
CREATE TRIGGER trg_proteger_bitacora
    BEFORE UPDATE OR DELETE ON auditoria.bitacora_auditoria
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_proteger_bitacora();

-- Activar bitácora en tablas críticas de negocio
DROP TRIGGER IF EXISTS trg_audit_libro ON libro;
CREATE TRIGGER trg_audit_libro
    AFTER INSERT OR UPDATE OR DELETE ON libro
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_bitacora();

DROP TRIGGER IF EXISTS trg_audit_venta ON venta;
CREATE TRIGGER trg_audit_venta
    AFTER INSERT OR UPDATE OR DELETE ON venta
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_bitacora();

DROP TRIGGER IF EXISTS trg_audit_multa ON multa;
CREATE TRIGGER trg_audit_multa
    AFTER INSERT OR UPDATE OR DELETE ON multa
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_bitacora();

DROP TRIGGER IF EXISTS trg_audit_orden_compra ON orden_compra;
CREATE TRIGGER trg_audit_orden_compra
    AFTER INSERT OR UPDATE OR DELETE ON orden_compra
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_bitacora();

DROP TRIGGER IF EXISTS trg_audit_empleado ON empleado;
CREATE TRIGGER trg_audit_empleado
    AFTER INSERT OR UPDATE OR DELETE ON empleado
    FOR EACH ROW EXECUTE FUNCTION auditoria.fn_registrar_bitacora();

-- ----------------------------------------------------------------------------
-- 4. PARTICIONAMIENTO HISTÓRICO DE VENTAS (Ejemplo compatible con script 01)
-- ----------------------------------------------------------------------------
-- Permite archivar ventas antiguas por año usando DETACH PARTITION sin afectar
-- la operación de la tabla 'venta' actual ni sus llaves foráneas.
CREATE TABLE IF NOT EXISTS auditoria.venta_historica (
    id_venta    INT            NOT NULL,
    id_cliente  INT,
    id_empleado INT            NOT NULL,
    fecha_venta TIMESTAMP      NOT NULL,
    metodo_pago VARCHAR(30)    NOT NULL,
    total       NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (id_venta, fecha_venta)
) PARTITION BY RANGE (fecha_venta);

CREATE TABLE IF NOT EXISTS auditoria.venta_historica_2025
    PARTITION OF auditoria.venta_historica
    FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00');

CREATE TABLE IF NOT EXISTS auditoria.venta_historica_2026
    PARTITION OF auditoria.venta_historica
    FOR VALUES FROM ('2026-01-01 00:00:00') TO ('2027-01-01 00:00:00');

-- Ejemplo de archivado anual de una partición (desmontar sin bloquear toda la BD):
-- ALTER TABLE auditoria.bitacora_auditoria DETACH PARTITION auditoria.bitacora_auditoria_2025;