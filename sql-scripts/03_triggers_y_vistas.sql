-- ============================================================================
-- LIBRERÍA CULTURAL "EL SABER"
-- Script 03: Triggers de Automatización de Inventario y Vistas de Reportes
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. AUTOMATIZACIÓN DE INVENTARIO AL RECIBIR ORDEN DE COMPRA (Req. 3)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_actualizar_stock_orden_recibida()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'recibida' AND OLD.estado <> 'recibida' THEN
        -- Actualizar stock de venta
        UPDATE libro l
        SET stock_venta = l.stock_venta + d.cantidad
        FROM detalle_orden_compra d
        WHERE d.id_orden = NEW.id_orden
          AND d.id_libro = l.id_libro
          AND d.destino_stock = 'venta';

        -- Actualizar stock de biblioteca
        UPDATE libro l
        SET stock_biblioteca = l.stock_biblioteca + d.cantidad
        FROM detalle_orden_compra d
        WHERE d.id_orden = NEW.id_orden
          AND d.id_libro = l.id_libro
          AND d.destino_stock = 'biblioteca';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orden_compra_recibida
AFTER UPDATE OF estado ON orden_compra
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_stock_orden_recibida();

-- ----------------------------------------------------------------------------
-- 2. DESCUENTO AUTOMÁTICO DE STOCK EN VENTAS (Req. 2)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_descontar_stock_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_stock_actual INT;
BEGIN
    SELECT stock_venta INTO v_stock_actual
    FROM libro
    WHERE id_libro = NEW.id_libro
    FOR UPDATE;

    IF v_stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock de venta insuficiente para el libro ID % (disponible: %, solicitado: %)',
            NEW.id_libro, v_stock_actual, NEW.cantidad;
    END IF;

    UPDATE libro
    SET stock_venta = stock_venta - NEW.cantidad
    WHERE id_libro = NEW.id_libro;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_venta_descontar_stock
BEFORE INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION fn_descontar_stock_venta();

-- ----------------------------------------------------------------------------
-- 3. CONTROL AUTOMÁTICO DE STOCK EN PRÉSTAMOS DE BIBLIOTECA (Req. 4)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_gestionar_stock_prestamo()
RETURNS TRIGGER AS $$
DECLARE
    v_stock_bib INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        SELECT stock_biblioteca INTO v_stock_bib
        FROM libro
        WHERE id_libro = NEW.id_libro
        FOR UPDATE;

        IF v_stock_bib < NEW.cantidad THEN
            RAISE EXCEPTION 'No hay ejemplares disponibles en biblioteca para el libro ID %', NEW.id_libro;
        END IF;

        UPDATE libro
        SET stock_biblioteca = stock_biblioteca - NEW.cantidad
        WHERE id_libro = NEW.id_libro;

    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.estado_item = 'devuelto' AND OLD.estado_item <> 'devuelto' THEN
            UPDATE libro
            SET stock_biblioteca = stock_biblioteca + NEW.cantidad
            WHERE id_libro = NEW.id_libro;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prestamo_stock
BEFORE INSERT OR UPDATE OF estado_item ON detalle_prestamo
FOR EACH ROW
EXECUTE FUNCTION fn_gestionar_stock_prestamo();

-- ----------------------------------------------------------------------------
-- 4. ACTUALIZACIÓN DE INVENTARIO POR DEVOLUCIONES (Req. 8)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_reingresar_stock_devolucion_cliente()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reingresa_inventario = TRUE THEN
        UPDATE libro
        SET stock_venta = stock_venta + NEW.cantidad
        WHERE id_libro = NEW.id_libro;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_devolucion_cliente_stock
AFTER INSERT ON detalle_devolucion_cliente
FOR EACH ROW
EXECUTE FUNCTION fn_reingresar_stock_devolucion_cliente();

CREATE OR REPLACE FUNCTION fn_descontar_stock_devolucion_proveedor()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE libro
    SET stock_venta = GREATEST(0, stock_venta - NEW.cantidad)
    WHERE id_libro = NEW.id_libro;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_devolucion_proveedor_stock
AFTER INSERT ON detalle_devolucion_proveedor
FOR EACH ROW
EXECUTE FUNCTION fn_descontar_stock_devolucion_proveedor();

-- ----------------------------------------------------------------------------
-- 5. VISTAS PARA REPORTES DE GESTIÓN Y RECOMENDACIONES (Req. 7 + Contexto)
-- ----------------------------------------------------------------------------

-- Libros más vendidos
CREATE OR REPLACE VIEW vw_libros_mas_vendidos AS
SELECT
    l.id_libro,
    l.isbn,
    l.titulo,
    g.nombre AS genero,
    COALESCE(SUM(dv.cantidad), 0) AS total_unidades_vendidas,
    COALESCE(SUM(dv.subtotal), 0.00) AS ingresos_totales
FROM libro l
JOIN genero g ON g.id_genero = l.id_genero
LEFT JOIN detalle_venta dv ON dv.id_libro = l.id_libro
GROUP BY l.id_libro, l.isbn, l.titulo, g.nombre
ORDER BY total_unidades_vendidas DESC, ingresos_totales DESC;

-- Libros más prestados
CREATE OR REPLACE VIEW vw_libros_mas_prestados AS
SELECT
    l.id_libro,
    l.isbn,
    l.titulo,
    g.nombre AS genero,
    COALESCE(SUM(dp.cantidad), 0) AS total_prestamos
FROM libro l
JOIN genero g ON g.id_genero = l.id_genero
LEFT JOIN detalle_prestamo dp ON dp.id_libro = l.id_libro
GROUP BY l.id_libro, l.isbn, l.titulo, g.nombre
ORDER BY total_prestamos DESC;

-- Recomendaciones personalizadas por cliente según géneros favoritos
CREATE OR REPLACE VIEW vw_recomendaciones_cliente AS
SELECT
    c.id_cliente,
    c.nombre || ' ' || c.apellido AS cliente,
    g.nombre AS genero_preferido,
    l.id_libro,
    l.titulo AS libro_recomendado,
    l.precio_venta,
    l.stock_venta
FROM preferencia_cliente pc
JOIN cliente c ON c.id_cliente = pc.id_cliente
JOIN genero g  ON g.id_genero = pc.id_genero
JOIN libro l   ON l.id_genero = pc.id_genero
WHERE NOT EXISTS (
    SELECT 1
    FROM venta v
    JOIN detalle_venta dv ON dv.id_venta = v.id_venta
    WHERE v.id_cliente = c.id_cliente AND dv.id_libro = l.id_libro
)
AND NOT EXISTS (
    SELECT 1
    FROM prestamo p
    JOIN detalle_prestamo dp ON dp.id_prestamo = p.id_prestamo
    WHERE p.id_cliente = c.id_cliente AND dp.id_libro = l.id_libro
);