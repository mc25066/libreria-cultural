-- ============================================================================
-- LIBRERÍA CULTURAL "EL SABER"
-- Script 02: Inserción de Datos de Prueba (Mínimo 10 registros por tabla)
-- ============================================================================

-- 1. EDITORIAL (10 registros)
INSERT INTO editorial (nombre, pais, sitio_web) VALUES
('Alfaguara', 'España', 'https://www.alfaguara.com'),
('Editorial Planeta', 'España', 'https://www.planetadelibros.com'),
('Penguin Random House', 'Estados Unidos', 'https://www.penguinrandomhouse.com'),
('Editorial Anagrama', 'España', 'https://www.anagrama-ed.es'),
('Tusquets Editores', 'España', 'https://www.tusquetseditores.com'),
('Fondo de Cultura Económica', 'México', 'https://www.fondodeculturaeconomica.com'),
('Editorial Sudamericana', 'Argentina', 'https://www.penguinlibros.com/ar'),
('Seix Barral', 'España', 'https://www.planetadelibros.com/editorial/seix-barral'),
('UCA Editores', 'El Salvador', 'https://www.uca.edu.sv/publicaciones'),
('Dirección de Publicaciones e Impresos', 'El Salvador', 'https://www.cultura.gob.sv');

-- 2. GENERO (10 registros)
INSERT INTO genero (nombre, descripcion) VALUES
('Realismo Mágico', 'Narrativa que mezcla elementos fantásticos en contextos cotidianos.'),
('Novela Histórica', 'Obras de ficción ambientadas en períodos históricos reales.'),
('Ciencia Ficción', 'Especulación narrativa sobre ciencia, tecnología y sociedad.'),
('Poesía', 'Expresión literaria en verso o prosa poética.'),
('Ensayo Filosófico', 'Reflexión analítica sobre historia, humanidad y pensamiento.'),
('Literatura Infantil', 'Obras dirigidas a lectores jóvenes y niños.'),
('Misterio y Policiaca', 'Narrativa centrada en la investigación de enigmas o crímenes.'),
('Biografía', 'Relatos documentados sobre la vida de personajes relevantes.'),
('Literatura Contemporánea', 'Narrativa moderna de alta relevancia cultural.'),
('Teatro', 'Obras dramáticas escritas para su representación escénica.');

-- 3. AUTOR (13 registros)
INSERT INTO autor (nombre, apellido, nacionalidad) VALUES
('Gabriel', 'García Márquez', 'Colombiana'),
('Isabel', 'Allende', 'Chilena'),
('Jorge Luis', 'Borges', 'Argentina'),
('Mario', 'Vargas Llosa', 'Peruana'),
('Claribel', 'Alegría', 'Salvadoreña'),
('Roque', 'Dalton', 'Salvadoreña'),
('Julio', 'Cortázar', 'Argentina'),
('Yuval Noah', 'Harari', 'Israelí'),
('Ursula K.', 'Le Guin', 'Estadounidense'),
('Agatha', 'Christie', 'Británica'),
('Antoine', 'de Saint-Exupéry', 'Francesa'),
('Horacio', 'Castellanos Moya', 'Salvadoreña'),
('Darwin J.', 'Flakoll', 'Estadounidense');

-- 4. LIBRO (15 registros)
INSERT INTO libro (isbn, titulo, anio_publicacion, precio_venta, stock_venta, stock_biblioteca, id_editorial, id_genero) VALUES
('978-0307474728', 'Cien años de soledad', 1967, 22.50, 30, 6, 7, 1),
('978-0525433477', 'La casa de los espíritus', 1982, 19.00, 25, 5, 2, 1),
('978-8499089515', 'Ficciones', 1944, 16.50, 20, 5, 3, 9),
('978-8420471839', 'La ciudad y los perros', 1963, 21.00, 18, 4, 1, 9),
('978-9992334102', 'Cenizas de Izalco', 1966, 14.00, 22, 6, 9, 2),
('978-9992301548', 'Poemas clandestinos', 1975, 12.50, 28, 5, 10, 4),
('978-8437604572', 'Rayuela', 1963, 23.00, 15, 4, 1, 9),
('978-8499926223', 'Sapiens: De animales a dioses', 2011, 26.00, 35, 5, 3, 5),
('978-8445076255', 'Los desposeídos', 1974, 18.00, 16, 3, 2, 3),
('978-8467045383', 'Asesinato en el Orient Express', 1934, 15.50, 24, 4, 2, 7),
('978-0156013987', 'El principito', 1943, 11.00, 40, 8, 6, 6),
('978-8483103616', 'Insensatez', 2004, 17.50, 14, 3, 5, 9),
('978-8433971012', 'El amor en los tiempos del cólera', 1985, 21.50, 20, 4, 4, 1),
('978-8432216473', 'La fiesta del chivo', 2000, 22.00, 19, 4, 8, 2),
('978-8499089508', 'El Aleph', 1949, 16.00, 21, 5, 3, 9);

-- 5. LIBRO_AUTOR (16 registros)
INSERT INTO libro_autor (id_libro, id_autor) VALUES
(1, 1), (2, 2), (3, 3), (4, 4),
(5, 5), (5, 13), -- Coautoría: Claribel Alegría y Darwin J. Flakoll
(6, 6), (7, 7), (8, 8), (9, 9),
(10, 10), (11, 11), (12, 12), (13, 1),
(14, 4), (15, 3);

-- 6. PROVEEDOR (10 registros)
INSERT INTO proveedor (razon_social, tipo_proveedor, alcance, pais, contacto, email, telefono, direccion, condiciones_pago) VALUES
('Distribuidora Literaria Ibérica S.A.', 'distribuidor', 'internacional', 'España', 'Carlos Mendoza', 'ventas@ibericalibros.es', '+34-915550101', 'Calle Alcalá 45, Madrid', 'Crédito 45 días'),
('Grupo Planeta Distribución', 'editorial', 'internacional', 'España', 'Laura Fernández', 'pedidos@planeta.es', '+34-934928000', 'Av. Diagonal 662, Barcelona', 'Crédito 30 días'),
('Penguin Random House Latam', 'editorial', 'internacional', 'México', 'Sofía Morales', 'latam@prh.com', '+52-555550202', 'Av. Insurgentes Sur 1200, CDMX', 'Crédito 60 días'),
('Distribuidora Cultural Centroamericana', 'distribuidor', 'nacional', 'El Salvador', 'Roberto Rivas', 'compras@dcc.com.sv', '+503-2222-1100', 'Col. Escalón, San Salvador', 'Crédito 30 días'),
('Editorial UCA', 'editorial', 'nacional', 'El Salvador', 'Ana María Pineda', 'editorial@uca.edu.sv', '+503-2210-6600', 'Bulevar Los Próceres, Antiguo Cuscatlán', 'Contado'),
('Ediciones El Saber Nacional', 'distribuidor', 'nacional', 'El Salvador', 'Diego Meléndez', 'contacto@elsabernac.sv', '+503-2245-3300', 'Centro Histórico, San Salvador', 'Crédito 15 días'),
('Fondo Editorial Cono Sur', 'distribuidor', 'internacional', 'Argentina', 'Lucía Pereyra', 'export@conosur.com.ar', '+54-1143210987', 'Av. Corrientes 1850, Buenos Aires', 'Crédito 45 días'),
('Distribuidora Andina de Libros', 'distribuidor', 'internacional', 'Colombia', 'Javier Gómez', 'pedidos@andinalibros.co', '+57-13456789', 'Carrera 7 #45, Bogotá', 'Crédito 30 días'),
('FCE Centroamérica', 'editorial', 'internacional', 'Guatemala', 'Marta Solís', 'ca@fce.com.gt', '+502-2360-1122', '6a Avenida, Zona 9, Guatemala', 'Crédito 30 días'),
('Importadora de Textos Norte', 'distribuidor', 'internacional', 'Estados Unidos', 'Michael Carter', 'orders@nortetext.com', '+1-305-555-0199', 'NW 79th Ave, Miami, FL', 'Contado');

-- 7. EMPLEADO (10 registros)
INSERT INTO empleado (nombre, apellido, cargo, email, telefono, activo) VALUES
('Valeria', 'Hernández', 'vendedor', 'vhernandez@elsaber.sv', '7101-1001', TRUE),
('Mateo', 'Campos', 'vendedor', 'mcampos@elsaber.sv', '7101-1002', TRUE),
('Camila', 'Navarro', 'vendedor', 'cnavarro@elsaber.sv', '7101-1003', TRUE),
('Andrés', 'Flores', 'vendedor', 'aflores@elsaber.sv', '7101-1004', TRUE),
('Elena', 'Portillo', 'bibliotecario', 'eportillo@elsaber.sv', '7101-1005', TRUE),
('Gabriel', 'Benítez', 'bibliotecario', 'gbenitez@elsaber.sv', '7101-1006', TRUE),
('Patricia', 'Cañas', 'bibliotecario', 'pcanas@elsaber.sv', '7101-1007', TRUE),
('Fernando', 'Aguilar', 'bodeguero', 'faguilar@elsaber.sv', '7101-1008', TRUE),
('Ricardo', 'Vásquez', 'bodeguero', 'rvasquez@elsaber.sv', '7101-1009', TRUE),
('Mónica', 'Escobar', 'administrador', 'mescobar@elsaber.sv', '7101-1010', TRUE);

-- 8. CLIENTE (15 registros)
INSERT INTO cliente (nombre, apellido, email, telefono, direccion, tipo_cliente, fecha_registro) VALUES
('Sofía', 'Ramírez', 'sofia.ramirez@mail.com', '7200-0001', 'Col. San Benito, San Salvador', 'socio', '2024-03-10'),
('Alejandro', 'Cruz', 'alejandro.cruz@mail.com', '7200-0002', 'Santa Tecla, La Libertad', 'socio', '2024-05-18'),
('Luciana', 'Martínez', 'luciana.mtz@mail.com', '7200-0003', 'Col. Escalón, San Salvador', 'socio', '2024-07-22'),
('Daniel', 'Orellana', 'daniel.orellana@mail.com', '7200-0004', 'Antiguo Cuscatlán', 'socio', '2024-09-05'),
('Gabriela', 'Mejía', 'gabriela.mejia@mail.com', '7200-0005', 'Col. Miramonte, San Salvador', 'socio', '2025-01-12'),
('Sebastián', 'Reyes', 'sebastian.reyes@mail.com', '7200-0006', 'Mejicanos, San Salvador', 'socio', '2025-02-20'),
('Natalia', 'Zelaya', 'natalia.zelaya@mail.com', '7200-0007', 'Soyapango, San Salvador', 'socio', '2025-04-11'),
('Óscar', 'Guevara', 'oscar.guevara@mail.com', '7200-0008', 'Lourdes Colón, La Libertad', 'socio', '2025-06-15'),
('Claudia', 'Alfaro', 'claudia.alfaro@mail.com', '7200-0009', 'Col. Flor Blanca, San Salvador', 'socio', '2025-08-03'),
('Rodrigo', 'Salazar', 'rodrigo.salazar@mail.com', '7200-0010', 'Santa Ana Centro', 'socio', '2025-10-19'),
('Andrea', 'Morán', 'andrea.moran@mail.com', '7200-0011', 'San Miguel Centro', 'frecuente', '2026-01-15'),
('Javier', 'Cortez', 'javier.cortez@mail.com', '7200-0012', 'Col. Médica, San Salvador', 'frecuente', '2026-02-28'),
('Paula', 'Quinteros', 'paula.quinteros@mail.com', '7200-0013', 'Nuevo Cuscatlán', 'frecuente', '2026-03-14'),
('Luis', 'Pacheco', 'luis.pacheco@mail.com', '7200-0014', 'Ilopango, San Salvador', 'ocasional', '2026-05-09'),
('Carmen', 'Villatoro', 'carmen.villatoro@mail.com', '7200-0015', 'Apopa, San Salvador', 'ocasional', '2026-07-01');

-- 9. MEMBRESIA_SOCIO (10 registros)
INSERT INTO membresia_socio (id_cliente, numero_carnet, fecha_inicio, fecha_vencimiento, estado) VALUES
(1, 'SOC-2024-001', '2024-03-10', '2027-03-10', 'activa'),
(2, 'SOC-2024-002', '2024-05-18', '2027-05-18', 'activa'),
(3, 'SOC-2024-003', '2024-07-22', '2027-07-22', 'activa'),
(4, 'SOC-2024-004', '2024-09-05', '2026-09-05', 'vencida'),
(5, 'SOC-2025-005', '2025-01-12', '2027-01-12', 'activa'),
(6, 'SOC-2025-006', '2025-02-20', '2027-02-20', 'activa'),
(7, 'SOC-2025-007', '2025-04-11', '2027-04-11', 'activa'),
(8, 'SOC-2025-008', '2025-06-15', '2027-06-15', 'suspendida'),
(9, 'SOC-2025-009', '2025-08-03', '2027-08-03', 'activa'),
(10, 'SOC-2025-010', '2025-10-19', '2027-10-19', 'activa');

-- 10. PREFERENCIA_CLIENTE (15 registros)
INSERT INTO preferencia_cliente (id_cliente, id_genero) VALUES
(1, 1), (1, 9), (2, 1), (2, 4), (3, 9),
(4, 2), (5, 5), (6, 3), (7, 6), (8, 7),
(9, 1), (10, 2), (11, 9), (12, 3), (13, 4);

-- 11. VENTA (12 registros; incluye ventas con id_cliente NULL para público general)
INSERT INTO venta (id_cliente, id_empleado, fecha_venta, metodo_pago, total) VALUES
(1,    1, '2026-08-02 10:15:00', 'tarjeta',       56.00),
(2,    2, '2026-08-05 14:30:00', 'efectivo',      19.00),
(NULL, 1, '2026-08-08 16:45:00', 'efectivo',      41.50),
(3,    3, '2026-08-12 11:20:00', 'transferencia', 33.00),
(4,    4, '2026-08-15 17:05:00', 'tarjeta',       46.00),
(5,    2, '2026-08-19 09:50:00', 'efectivo',      14.00),
(11,   1, '2026-09-01 13:10:00', 'tarjeta',       23.00),
(12,   3, '2026-09-04 15:40:00', 'tarjeta',       36.00),
(NULL, 4, '2026-09-10 12:00:00', 'efectivo',      33.00),
(6,    2, '2026-09-14 18:15:00', 'transferencia', 39.00),
(13,   1, '2026-09-20 11:30:00', 'tarjeta',       22.00),
(7,    3, '2026-09-25 16:20:00', 'efectivo',      32.00);

-- 12. DETALLE_VENTA (16 registros)
INSERT INTO detalle_venta (id_venta, id_libro, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 2, 22.50, 45.00),
(1, 11, 1, 11.00, 11.00),
(2, 2, 1, 19.00, 19.00),
(3, 8, 1, 26.00, 26.00),
(3, 10, 1, 15.50, 15.50),
(4, 3, 2, 16.50, 33.00),
(5, 4, 1, 21.00, 21.00),
(5, 6, 2, 12.50, 25.00),
(6, 5, 1, 14.00, 14.00),
(7, 7, 1, 23.00, 23.00),
(8, 9, 2, 18.00, 36.00),
(9, 11, 3, 11.00, 33.00),
(10, 12, 1, 17.50, 17.50),
(10, 13, 1, 21.50, 21.50),
(11, 14, 1, 22.00, 22.00),
(12, 15, 2, 16.00, 32.00);

-- 13. ORDEN_COMPRA (12 registros)
INSERT INTO orden_compra (id_proveedor, id_empleado, fecha_orden, fecha_recepcion, estado, total) VALUES
(1,  8, '2026-06-01', '2026-06-15', 'recibida',  200.00),
(2,  8, '2026-06-05', '2026-06-18', 'recibida',  110.00),
(3,  9, '2026-06-10', '2026-06-25', 'recibida',  245.00),
(4,  8, '2026-07-02', '2026-07-06', 'recibida',  100.00),
(5,  9, '2026-07-08', '2026-07-10', 'recibida',   96.00),
(6,  8, '2026-07-12', '2026-07-15', 'recibida',  105.00),
(7,  9, '2026-07-20', '2026-08-02', 'recibida',  135.00),
(8,  8, '2026-08-01', '2026-08-12', 'recibida',  105.00),
(9,  9, '2026-08-05', '2026-08-14', 'recibida',  108.00),
(10, 8, '2026-08-10', '2026-08-22', 'recibida',  130.00),
(1,  9, '2026-10-28', NULL,         'pendiente', 130.00),
(2,  8, '2026-10-05', NULL,         'cancelada',  95.00);

-- 14. DETALLE_ORDEN_COMPRA (14 registros)
INSERT INTO detalle_orden_compra (id_orden, id_libro, cantidad, costo_unitario, destino_stock, subtotal) VALUES
(1, 1, 10, 13.50, 'venta', 135.00),
(1, 13, 5, 13.00, 'venta', 65.00),
(2, 2, 10, 11.00, 'venta', 110.00),
(3, 3, 10, 9.50, 'venta', 95.00),
(3, 8, 10, 15.00, 'venta', 150.00),
(4, 4, 8, 12.50, 'venta', 100.00),
(5, 5, 12, 8.00, 'venta', 96.00),
(6, 6, 15, 7.00, 'biblioteca', 105.00),
(7, 7, 10, 13.50, 'venta', 135.00),
(8, 9, 10, 10.50, 'venta', 105.00),
(9, 10, 12, 9.00, 'venta', 108.00),
(10, 11, 20, 6.50, 'biblioteca', 130.00),
(11, 14, 10, 13.00, 'venta', 130.00),
(12, 15, 10, 9.50, 'venta', 95.00);

-- 15. PRESTAMO (12 registros)
INSERT INTO prestamo (id_cliente, id_empleado, tipo_prestamo, fecha_prestamo, fecha_devolucion_estimada, estado) VALUES
(1,  5, 'domicilio',    '2026-07-01', '2026-07-15', 'devuelto'),
(2,  6, 'domicilio',    '2026-07-05', '2026-07-19', 'devuelto'),
(3,  5, 'domicilio',    '2026-07-10', '2026-07-24', 'devuelto'),
(4,  7, 'domicilio',    '2026-08-01', '2026-08-15', 'vencido'),
(5,  5, 'domicilio',    '2026-08-10', '2026-08-24', 'vencido'),
(6,  6, 'sala_lectura', '2026-08-15', '2026-08-15', 'devuelto'),
(7,  7, 'domicilio',    '2026-08-20', '2026-09-03', 'devuelto'),
(8,  5, 'domicilio',    '2026-09-01', '2026-09-15', 'vencido'),
(9,  6, 'domicilio',    '2026-09-10', '2026-09-24', 'vencido'),
(10, 7, 'domicilio',    '2026-09-18', '2026-10-02', 'devuelto'),
(1,  5, 'domicilio',    '2026-11-05', '2026-11-19', 'activo'),
(11, 6, 'sala_lectura', '2026-11-12', '2026-11-12', 'activo');

-- 16. DETALLE_PRESTAMO (15 registros)
INSERT INTO detalle_prestamo (id_prestamo, id_libro, cantidad, fecha_devolucion_real, estado_item) VALUES
(1, 1, 1, '2026-07-18', 'devuelto'),
(1, 3, 1, '2026-07-18', 'devuelto'),
(2, 2, 1, '2026-07-23', 'devuelto'),
(3, 5, 1, '2026-07-29', 'devuelto'),
(4, 4, 1, NULL,         'vencido'),
(5, 7, 1, NULL,         'vencido'),
(5, 8, 1, NULL,         'vencido'),
(6, 6, 1, '2026-08-17', 'devuelto'),
(7, 9, 1, '2026-09-08', 'devuelto'),
(8, 10, 1, NULL,        'vencido'),
(9, 12, 1, NULL,        'vencido'),
(10, 11, 1, '2026-10-06', 'devuelto'),
(10, 13, 1, '2026-10-06', 'devuelto'),
(11, 14, 1, NULL,       'prestado'),
(12, 15, 1, NULL,       'prestado');

-- 17. MULTA (10 registros)
INSERT INTO multa (id_prestamo, monto, fecha_generacion, fecha_pago, estado, motivo) VALUES
(1,  3.00, '2026-07-18', '2026-07-18', 'pagada',    'Devolución con 3 días de retraso'),
(2,  4.00, '2026-07-23', '2026-07-25', 'pagada',    'Devolución con 4 días de retraso'),
(3,  5.00, '2026-07-29', NULL,         'exonerada', 'Exoneración por evento cultural de lectura'),
(4, 15.00, '2026-08-16', NULL,         'pendiente', 'Préstamo vencido sin devolución'),
(5, 12.00, '2026-08-25', NULL,         'pendiente', 'Préstamo vencido de 2 ejemplares'),
(6,  2.00, '2026-08-17', '2026-08-17', 'pagada',    'Retraso en entrega de libro de sala de lectura'),
(7,  5.00, '2026-09-08', '2026-09-10', 'pagada',    'Devolución con 5 días de retraso'),
(8, 10.00, '2026-09-16', NULL,         'pendiente', 'Préstamo vencido sin devolución'),
(9, 10.00, '2026-09-25', NULL,         'pendiente', 'Préstamo vencido sin devolución'),
(10, 4.00, '2026-10-06', '2026-10-06', 'pagada',    'Devolución con 4 días de retraso');

-- 18. DEVOLUCION_CLIENTE (10 registros)
INSERT INTO devolucion_cliente (id_venta, id_empleado, fecha_devolucion, motivo, monto_reembolso) VALUES
(1,  1, '2026-08-04 11:00:00', 'Cliente compró ejemplar repetido', 11.00),
(2,  2, '2026-08-07 15:10:00', 'Hojas despegadas de fábrica', 19.00),
(3,  1, '2026-08-10 12:30:00', 'Cambio por otro título', 15.50),
(4,  3, '2026-08-14 10:20:00', 'Compró 2 copias por error', 16.50),
(5,  4, '2026-08-18 16:00:00', 'Portada manchada', 12.50),
(6,  2, '2026-08-21 14:15:00', 'Cliente ya poseía la edición', 14.00),
(7,  1, '2026-09-03 11:45:00', 'Regalo duplicado', 23.00),
(8,  3, '2026-09-06 17:20:00', 'Defecto de impresión en capítulo 3', 18.00),
(9,  4, '2026-09-12 09:40:00', 'Devolución parcial escolar', 11.00),
(10, 2, '2026-09-16 13:50:00', 'Preferencia por otra edición', 17.50);

-- 19. DETALLE_DEVOLUCION_CLIENTE (10 registros)
INSERT INTO detalle_devolucion_cliente (id_devolucion_cli, id_libro, cantidad, estado_libro, reingresa_inventario) VALUES
(1,  11, 1, 'buen_estado', TRUE),
(2,   2, 1, 'danado',      FALSE),
(3,  10, 1, 'buen_estado', TRUE),
(4,   3, 1, 'buen_estado', TRUE),
(5,   6, 1, 'danado',      FALSE),
(6,   5, 1, 'buen_estado', TRUE),
(7,   7, 1, 'buen_estado', TRUE),
(8,   9, 1, 'danado',      FALSE),
(9,  11, 1, 'buen_estado', TRUE),
(10, 12, 1, 'buen_estado', TRUE);

-- 20. DEVOLUCION_PROVEEDOR (10 registros)
INSERT INTO devolucion_proveedor (id_orden, id_empleado, fecha_devolucion, motivo, estado) VALUES
(1,  8, '2026-06-20', 'Lote con fallas de impresión', 'acreditada'),
(2,  8, '2026-06-22', 'Daño en transporte internacional', 'reemplazada'),
(3,  9, '2026-06-29', 'Falla de encuadernación', 'acreditada'),
(4,  8, '2026-07-09', 'Ejemplares con humedad', 'reemplazada'),
(5,  9, '2026-07-13', 'Error de compaginación de imprenta', 'acreditada'),
(6,  8, '2026-07-18', 'Lomo despegado en recepción', 'reemplazada'),
(7,  9, '2026-08-05', 'Pliegos en blanco', 'acreditada'),
(8,  8, '2026-08-15', 'Cubierta rasgada en empaque', 'pendiente'),
(9,  9, '2026-08-18', 'Tinta corrida en primeras páginas', 'pendiente'),
(10, 8, '2026-08-26', 'Esquinas golpeadas en caja', 'acreditada');

-- 21. DETALLE_DEVOLUCION_PROVEEDOR (10 registros)
INSERT INTO detalle_devolucion_proveedor (id_devolucion_prov, id_libro, cantidad, motivo_defecto) VALUES
(1,  1, 2, 'Páginas mal impresas'),
(2,  2, 1, 'Portada rasgada'),
(3,  8, 1, 'Encuadernación defectuosa'),
(4,  4, 1, 'Humedad en embalaje'),
(5,  5, 2, 'Error de compaginación'),
(6,  6, 1, 'Lomo despegado'),
(7,  7, 1, 'Páginas en blanco'),
(8,  9, 1, 'Cubierta dañada'),
(9, 10, 2, 'Impresión borrosa'),
(10, 11, 2, 'Esquinas dobladas');