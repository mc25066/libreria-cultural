-- ============================================================================
-- LIBRERÍA CULTURAL "EL SABER"
-- Script 01: Creación de Tablas, Restricciones e Índices (PostgreSQL)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- MÓDULO A: Catálogo e Inventario de Libros
-- ----------------------------------------------------------------------------

CREATE TABLE editorial (
    id_editorial SERIAL PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL,
    pais         VARCHAR(80)  NOT NULL,
    sitio_web    VARCHAR(200)
);

CREATE TABLE genero (
    id_genero   SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE autor (
    id_autor     SERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(80)
);

CREATE TABLE libro (
    id_libro         SERIAL PRIMARY KEY,
    isbn             VARCHAR(20)    NOT NULL UNIQUE,
    titulo           VARCHAR(250)   NOT NULL,
    anio_publicacion INT            NOT NULL CHECK (anio_publicacion BETWEEN 1450 AND 2100),
    precio_venta     NUMERIC(10, 2) NOT NULL CHECK (precio_venta > 0),
    stock_venta      INT            NOT NULL DEFAULT 0 CHECK (stock_venta >= 0),
    stock_biblioteca INT            NOT NULL DEFAULT 0 CHECK (stock_biblioteca >= 0),
    id_editorial     INT            NOT NULL REFERENCES editorial(id_editorial) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_genero        INT            NOT NULL REFERENCES genero(id_genero)       ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE libro_autor (
    id_libro INT NOT NULL REFERENCES libro(id_libro) ON UPDATE CASCADE ON DELETE CASCADE,
    id_autor INT NOT NULL REFERENCES autor(id_autor) ON UPDATE CASCADE ON DELETE RESTRICT,
    PRIMARY KEY (id_libro, id_autor)
);

-- ----------------------------------------------------------------------------
-- MÓDULO B: Clientes, Socios y Preferencias
-- ----------------------------------------------------------------------------

CREATE TABLE cliente (
    id_cliente     SERIAL PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    apellido       VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    telefono       VARCHAR(30),
    direccion      VARCHAR(250),
    tipo_cliente   VARCHAR(20)  NOT NULL CHECK (tipo_cliente IN ('ocasional', 'frecuente', 'socio')),
    fecha_registro DATE         NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE membresia_socio (
    id_membresia      SERIAL PRIMARY KEY,
    id_cliente        INT         NOT NULL UNIQUE REFERENCES cliente(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE,
    numero_carnet     VARCHAR(30) NOT NULL UNIQUE,
    fecha_inicio      DATE        NOT NULL,
    fecha_vencimiento DATE        NOT NULL CHECK (fecha_vencimiento > fecha_inicio),
    estado            VARCHAR(20) NOT NULL CHECK (estado IN ('activa', 'suspendida', 'vencida'))
);

CREATE TABLE preferencia_cliente (
    id_cliente INT NOT NULL REFERENCES cliente(id_cliente) ON UPDATE CASCADE ON DELETE CASCADE,
    id_genero  INT NOT NULL REFERENCES genero(id_genero)   ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (id_cliente, id_genero)
);

-- ----------------------------------------------------------------------------
-- MÓDULO C: Empleados y Proveedores
-- ----------------------------------------------------------------------------

CREATE TABLE empleado (
    id_empleado SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    cargo       VARCHAR(30)  NOT NULL CHECK (cargo IN ('vendedor', 'bibliotecario', 'bodeguero', 'administrador')),
    email       VARCHAR(150) NOT NULL UNIQUE,
    telefono    VARCHAR(30),
    activo      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE proveedor (
    id_proveedor     SERIAL PRIMARY KEY,
    razon_social     VARCHAR(180) NOT NULL,
    tipo_proveedor   VARCHAR(20)  NOT NULL CHECK (tipo_proveedor IN ('editorial', 'distribuidor')),
    alcance          VARCHAR(20)  NOT NULL CHECK (alcance IN ('nacional', 'internacional')),
    pais             VARCHAR(80)  NOT NULL,
    contacto         VARCHAR(120) NOT NULL,
    email            VARCHAR(150) NOT NULL,
    telefono         VARCHAR(30)  NOT NULL,
    direccion        VARCHAR(250),
    condiciones_pago VARCHAR(100) NOT NULL
);

-- ----------------------------------------------------------------------------
-- MÓDULO D: Ventas al Público y Compras a Proveedores
-- ----------------------------------------------------------------------------

CREATE TABLE venta (
    id_venta    SERIAL PRIMARY KEY,
    id_cliente  INT            REFERENCES cliente(id_cliente)   ON UPDATE CASCADE ON DELETE SET NULL,
    id_empleado INT            NOT NULL REFERENCES empleado(id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_venta TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago VARCHAR(30)    NOT NULL CHECK (metodo_pago IN ('efectivo', 'tarjeta', 'transferencia')),
    total       NUMERIC(10, 2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE detalle_venta (
    id_detalle_venta SERIAL PRIMARY KEY,
    id_venta         INT            NOT NULL REFERENCES venta(id_venta) ON UPDATE CASCADE ON DELETE CASCADE,
    id_libro         INT            NOT NULL REFERENCES libro(id_libro) ON UPDATE CASCADE ON DELETE RESTRICT,
    cantidad         INT            NOT NULL CHECK (cantidad > 0),
    precio_unitario  NUMERIC(10, 2) NOT NULL CHECK (precio_unitario > 0),
    subtotal         NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0)
);

CREATE TABLE orden_compra (
    id_orden        SERIAL PRIMARY KEY,
    id_proveedor    INT            NOT NULL REFERENCES proveedor(id_proveedor) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_empleado     INT            NOT NULL REFERENCES empleado(id_empleado)   ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_orden     DATE           NOT NULL DEFAULT CURRENT_DATE,
    fecha_recepcion DATE,
    estado          VARCHAR(20)    NOT NULL CHECK (estado IN ('pendiente', 'recibida', 'cancelada')),
    total           NUMERIC(10, 2) NOT NULL CHECK (total >= 0)
);

CREATE TABLE detalle_orden_compra (
    id_detalle_orden SERIAL PRIMARY KEY,
    id_orden         INT            NOT NULL REFERENCES orden_compra(id_orden) ON UPDATE CASCADE ON DELETE CASCADE,
    id_libro         INT            NOT NULL REFERENCES libro(id_libro)        ON UPDATE CASCADE ON DELETE RESTRICT,
    cantidad         INT            NOT NULL CHECK (cantidad > 0),
    costo_unitario   NUMERIC(10, 2) NOT NULL CHECK (costo_unitario > 0),
    destino_stock    VARCHAR(20)    NOT NULL DEFAULT 'venta' CHECK (destino_stock IN ('venta', 'biblioteca')),
    subtotal         NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0)
);

-- ----------------------------------------------------------------------------
-- MÓDULO E: Préstamos de Biblioteca y Multas
-- ----------------------------------------------------------------------------

CREATE TABLE prestamo (
    id_prestamo               SERIAL PRIMARY KEY,
    id_cliente                INT         NOT NULL REFERENCES cliente(id_cliente)   ON UPDATE CASCADE ON DELETE RESTRICT,
    id_empleado               INT         NOT NULL REFERENCES empleado(id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT,
    tipo_prestamo             VARCHAR(20) NOT NULL CHECK (tipo_prestamo IN ('domicilio', 'sala_lectura')),
    fecha_prestamo            DATE        NOT NULL DEFAULT CURRENT_DATE,
    fecha_devolucion_estimada DATE        NOT NULL CHECK (fecha_devolucion_estimada >= fecha_prestamo),
    estado                    VARCHAR(20) NOT NULL CHECK (estado IN ('activo', 'devuelto', 'vencido'))
);

CREATE TABLE detalle_prestamo (
    id_detalle_prestamo   SERIAL PRIMARY KEY,
    id_prestamo           INT         NOT NULL REFERENCES prestamo(id_prestamo) ON UPDATE CASCADE ON DELETE CASCADE,
    id_libro              INT         NOT NULL REFERENCES libro(id_libro)       ON UPDATE CASCADE ON DELETE RESTRICT,
    cantidad              INT         NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    fecha_devolucion_real DATE,
    estado_item           VARCHAR(20) NOT NULL CHECK (estado_item IN ('prestado', 'devuelto', 'vencido'))
);

CREATE TABLE multa (
    id_multa         SERIAL PRIMARY KEY,
    id_prestamo      INT            NOT NULL REFERENCES prestamo(id_prestamo) ON UPDATE CASCADE ON DELETE CASCADE,
    monto            NUMERIC(10, 2) NOT NULL CHECK (monto > 0),
    fecha_generacion DATE           NOT NULL DEFAULT CURRENT_DATE,
    fecha_pago       DATE,
    estado           VARCHAR(20)    NOT NULL CHECK (estado IN ('pendiente', 'pagada', 'exonerada')),
    motivo           VARCHAR(200)   NOT NULL
);

-- ----------------------------------------------------------------------------
-- MÓDULO F: Gestión de Devoluciones (Clientes y Proveedores)
-- ----------------------------------------------------------------------------

CREATE TABLE devolucion_cliente (
    id_devolucion_cli SERIAL PRIMARY KEY,
    id_venta          INT            NOT NULL REFERENCES venta(id_venta)       ON UPDATE CASCADE ON DELETE RESTRICT,
    id_empleado       INT            NOT NULL REFERENCES empleado(id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_devolucion  TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo            VARCHAR(250)   NOT NULL,
    monto_reembolso   NUMERIC(10, 2) NOT NULL CHECK (monto_reembolso >= 0)
);

CREATE TABLE detalle_devolucion_cliente (
    id_det_dev_cli       SERIAL PRIMARY KEY,
    id_devolucion_cli    INT         NOT NULL REFERENCES devolucion_cliente(id_devolucion_cli) ON UPDATE CASCADE ON DELETE CASCADE,
    id_libro             INT         NOT NULL REFERENCES libro(id_libro)                       ON UPDATE CASCADE ON DELETE RESTRICT,
    cantidad             INT         NOT NULL CHECK (cantidad > 0),
    estado_libro         VARCHAR(20) NOT NULL CHECK (estado_libro IN ('buen_estado', 'danado')),
    reingresa_inventario BOOLEAN     NOT NULL
);

CREATE TABLE devolucion_proveedor (
    id_devolucion_prov SERIAL PRIMARY KEY,
    id_orden           INT          NOT NULL REFERENCES orden_compra(id_orden) ON UPDATE CASCADE ON DELETE RESTRICT,
    id_empleado        INT          NOT NULL REFERENCES empleado(id_empleado)  ON UPDATE CASCADE ON DELETE RESTRICT,
    fecha_devolucion   DATE         NOT NULL DEFAULT CURRENT_DATE,
    motivo             VARCHAR(250) NOT NULL,
    estado             VARCHAR(20)  NOT NULL CHECK (estado IN ('pendiente', 'acreditada', 'reemplazada'))
);

CREATE TABLE detalle_devolucion_proveedor (
    id_det_dev_prov    SERIAL PRIMARY KEY,
    id_devolucion_prov INT          NOT NULL REFERENCES devolucion_proveedor(id_devolucion_prov) ON UPDATE CASCADE ON DELETE CASCADE,
    id_libro           INT          NOT NULL REFERENCES libro(id_libro)                           ON UPDATE CASCADE ON DELETE RESTRICT,
    cantidad           INT          NOT NULL CHECK (cantidad > 0),
    motivo_defecto     VARCHAR(200) NOT NULL
);

-- ----------------------------------------------------------------------------
-- ÍNDICES PARA CONSULTAS Y REPORTES
-- ----------------------------------------------------------------------------
CREATE INDEX idx_libro_titulo         ON libro(titulo);
CREATE INDEX idx_libro_genero         ON libro(id_genero);
CREATE INDEX idx_venta_fecha          ON venta(fecha_venta);
CREATE INDEX idx_venta_cliente        ON venta(id_cliente);
CREATE INDEX idx_detalle_venta_libro  ON detalle_venta(id_libro);
CREATE INDEX idx_prestamo_estado      ON prestamo(estado);
CREATE INDEX idx_prestamo_cliente     ON prestamo(id_cliente);
CREATE INDEX idx_det_prestamo_libro   ON detalle_prestamo(id_libro);
CREATE INDEX idx_orden_compra_estado  ON orden_compra(estado);