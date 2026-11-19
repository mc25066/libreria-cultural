-- ============================================================================
-- LIBRERÍA CULTURAL "EL SABER"
-- Script 05: Seguridad, Roles (RBAC), Segregación de Funciones y Encriptación
-- Ejecutar después de 01, 02, 03 y 04 (PostgreSQL 14+ / 16 / 17)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ENDURECIMIENTO DE ESQUEMAS (Principio de Menor Privilegio)
-- ----------------------------------------------------------------------------
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA auditoria FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- 2. ROLES DE GRUPO (Alineados a empleado.cargo + Auditor)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_administrador') THEN
        CREATE ROLE rol_administrador NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_bodeguero') THEN
        CREATE ROLE rol_bodeguero NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_vendedor') THEN
        CREATE ROLE rol_vendedor NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_bibliotecario') THEN
        CREATE ROLE rol_bibliotecario NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_auditor') THEN
        CREATE ROLE rol_auditor NOLOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA public TO
    rol_administrador, rol_bodeguero, rol_vendedor, rol_bibliotecario, rol_auditor;

-- A) ADMINISTRADOR (Gestión total del negocio, DDL y mantenimiento)
GRANT ALL PRIVILEGES ON SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administrador;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO rol_administrador;
-- Segregación de funciones: solo lectura sobre la bitácora (no puede alterarla)
GRANT USAGE ON SCHEMA auditoria TO rol_administrador;
GRANT SELECT ON auditoria.bitacora_auditoria, auditoria.venta_historica TO rol_administrador;

-- B) BODEGUERO (Proveedores, órdenes de compra, recepción e inventario)
GRANT SELECT ON editorial, genero, autor, libro, libro_autor, proveedor,
    orden_compra, detalle_orden_compra, devolucion_proveedor, detalle_devolucion_proveedor
    TO rol_bodeguero;
GRANT INSERT, UPDATE ON editorial, genero, autor, libro, libro_autor, proveedor,
    orden_compra, detalle_orden_compra, devolucion_proveedor, detalle_devolucion_proveedor
    TO rol_bodeguero;
-- Requerido por trg_orden_compra_recibida y trg_devolucion_proveedor_stock
GRANT UPDATE (stock_venta, stock_biblioteca) ON libro TO rol_bodeguero;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_bodeguero;

-- C) VENDEDOR (Ventas, clientes, recomendaciones y devoluciones de cliente)
GRANT SELECT ON editorial, genero, autor, libro, libro_autor, cliente,
    preferencia_cliente, venta, detalle_venta, devolucion_cliente, detalle_devolucion_cliente,
    vw_libros_mas_vendidos, vw_recomendaciones_cliente
    TO rol_vendedor;
GRANT INSERT, UPDATE ON cliente, preferencia_cliente TO rol_vendedor;
GRANT INSERT ON venta, detalle_venta, devolucion_cliente, detalle_devolucion_cliente TO rol_vendedor;
-- Requerido por trg_venta_descontar_stock (FOR UPDATE) y trg_devolucion_cliente_stock
GRANT UPDATE (stock_venta) ON libro TO rol_vendedor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_vendedor;

-- D) BIBLIOTECARIO (Socios, préstamos, devoluciones de biblioteca y multas)
GRANT SELECT ON editorial, genero, autor, libro, libro_autor, cliente,
    membresia_socio, preferencia_cliente, prestamo, detalle_prestamo, multa,
    vw_libros_mas_prestados, vw_recomendaciones_cliente
    TO rol_bibliotecario;
GRANT INSERT, UPDATE ON cliente, membresia_socio, preferencia_cliente,
    prestamo, detalle_prestamo, multa TO rol_bibliotecario;
-- Requerido por trg_prestamo_stock (FOR UPDATE + UPDATE)
GRANT UPDATE (stock_biblioteca) ON libro TO rol_bibliotecario;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO rol_bibliotecario;

-- E) AUDITOR INDEPENDIENTE (Solo lectura en tablas, vistas y bitácora)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;
GRANT USAGE ON SCHEMA auditoria TO rol_auditor;
GRANT SELECT ON auditoria.bitacora_auditoria, auditoria.venta_historica TO rol_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON auditoria.bitacora_auditoria
    FROM PUBLIC, rol_administrador, rol_bodeguero, rol_vendedor, rol_bibliotecario, rol_auditor;

-- ----------------------------------------------------------------------------
-- 3. USUARIOS FINALES Y USUARIO DEDICADO A RESPALDOS
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_admin_saber') THEN
        CREATE USER usr_admin_saber WITH PASSWORD 'CAMBIAR_Admin#2026!' IN ROLE rol_administrador;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_bodeguero_1') THEN
        CREATE USER usr_bodeguero_1 WITH PASSWORD 'CAMBIAR_Bodega#2026!' IN ROLE rol_bodeguero;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_vendedor_1') THEN
        CREATE USER usr_vendedor_1 WITH PASSWORD 'CAMBIAR_Venta#2026!' IN ROLE rol_vendedor;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_biblio_1') THEN
        CREATE USER usr_biblio_1 WITH PASSWORD 'CAMBIAR_Biblio#2026!' IN ROLE rol_bibliotecario;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_auditor_1') THEN
        CREATE USER usr_auditor_1 WITH PASSWORD 'CAMBIAR_Auditor#2026!' IN ROLE rol_auditor;
    END IF;

    -- Usuario dedicado exclusivamente a backups con pg_read_all_data (PG 14+)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_respaldo') THEN
        CREATE USER usr_respaldo WITH PASSWORD 'CAMBIAR_Respaldo#2026!' IN ROLE pg_read_all_data;
    END IF;
END
$$;

-- ----------------------------------------------------------------------------
-- 4. ENCRIPTACIÓN DE DATOS SENSIBLES (pgcrypto)
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- A) Credenciales seguras para empleados (Hash Bcrypt irreversible)
ALTER TABLE empleado
    ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Ejemplo de registro y validación de contraseña:
-- UPDATE empleado SET password_hash = crypt('ClaveEmpleado2026', gen_salt('bf', 10)) WHERE id_empleado = 10;
-- SELECT (password_hash = crypt('ClaveEmpleado2026', password_hash)) AS acceso_valido FROM empleado WHERE id_empleado = 10;

-- B) Cifrado simétrico AES-256 para datos de contacto (PII) en 'cliente'
ALTER TABLE cliente
    ADD COLUMN IF NOT EXISTS telefono_cifrado  BYTEA,
    ADD COLUMN IF NOT EXISTS direccion_cifrada BYTEA;

-- Funciones de cifrado/descifrado usando llave de sesión (evita exponer la llave en el código)
CREATE OR REPLACE FUNCTION fn_cifrar_dato(texto TEXT)
RETURNS BYTEA
LANGUAGE plpgsql
AS $$
DECLARE
    v_clave TEXT;
BEGIN
    IF texto IS NULL THEN RETURN NULL; END IF;
    v_clave := current_setting('app.clave_cifrado', true);
    IF v_clave IS NULL OR v_clave = '' THEN
        RAISE EXCEPTION 'Debe configurar app.clave_cifrado en la sesión antes de cifrar.';
    END IF;
    RETURN pgp_sym_encrypt(texto, v_clave, 'cipher-algo=aes256');
END;
$$;

CREATE OR REPLACE FUNCTION fn_descifrar_dato(dato_cifrado BYTEA)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_clave TEXT;
BEGIN
    IF dato_cifrado IS NULL THEN RETURN NULL; END IF;
    v_clave := current_setting('app.clave_cifrado', true);
    IF v_clave IS NULL OR v_clave = '' THEN
        RETURN '*** ENCRIPTADO ***';
    END IF;
    RETURN pgp_sym_decrypt(dato_cifrado, v_clave);
END;
$$;

GRANT EXECUTE ON FUNCTION fn_cifrar_dato(TEXT), fn_descifrar_dato(BYTEA)
    TO rol_administrador, rol_vendedor, rol_bibliotecario;

-- Ejemplo para migrar los teléfonos y direcciones ya insertados en 02_datos_prueba.sql:
/*
BEGIN;
SET LOCAL app.clave_cifrado = 'LlaveMaestra_ElSaber_2026';
UPDATE cliente
SET telefono_cifrado  = fn_cifrar_dato(telefono),
    direccion_cifrada = fn_cifrar_dato(direccion)
WHERE telefono_cifrado IS NULL;
COMMIT;
*/

-- Vista con enmascaramiento de PII para reportes y auditoría
CREATE OR REPLACE VIEW vw_clientes_enmascarados AS
SELECT
    c.id_cliente,
    c.nombre,
    c.apellido,
    c.tipo_cliente,
    c.fecha_registro,
    CASE
        WHEN pg_has_role(CURRENT_USER, 'rol_administrador', 'MEMBER') THEN c.email
        ELSE regexp_replace(c.email, '(^.).*(@.*$)', '\1***\2')
    END AS email_visible,
    CASE
        WHEN current_setting('app.clave_cifrado', true) IS NOT NULL
             AND pg_has_role(CURRENT_USER, 'rol_administrador', 'MEMBER')
        THEN fn_descifrar_dato(c.telefono_cifrado)
        ELSE '****-****'
    END AS telefono_visible,
    CASE
        WHEN current_setting('app.clave_cifrado', true) IS NOT NULL
             AND pg_has_role(CURRENT_USER, 'rol_administrador', 'MEMBER')
        THEN fn_descifrar_dato(c.direccion_cifrada)
        ELSE '[DIRECCIÓN PROTEGIDA]'
    END AS direccion_visible
FROM cliente c;

GRANT SELECT ON vw_clientes_enmascarados TO
    rol_administrador, rol_vendedor, rol_bibliotecario, rol_auditor;