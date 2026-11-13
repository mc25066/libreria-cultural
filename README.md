# Librería Cultural "El Saber" — Diseño e Implementación de Base de Datos en PostgreSQL

Solución de base de datos relacional desarrollada en **PostgreSQL** para **La Librería Cultural "El Saber"**, diseñada para integrar la gestión de inventario, ventas al público, compras a proveedores nacionales e internacionales, sistema de préstamos bibliotecarios (a domicilio y en sala de lectura), control de devoluciones y recomendaciones personalizadas para sus lectores.

## 👥 Integrantes del Grupo

- **Jorge Meléndez** — *MC25066*
- **Integrante 2** — *CARNET*
- **Integrante 3** — *CARNET*
- **Integrante 4** — *CARNET*

---

## Descripción y Requerimientos Funcionales

El modelo responde integralmente a los requerimientos del establecimiento:

1. **Gestión de Inventario de Libros (`libro`, `editorial`, `genero`, `autor`, `libro_autor`):** Registro del catálogo con ISBN, título, año de publicación, múltiples autores, editorial, género, precio de venta y control separado de existencias para venta (`stock_venta`) y para biblioteca (`stock_biblioteca`).
2. **Proceso de Ventas al Público (`venta`, `detalle_venta`):** Registro de ventas con fecha, cliente (opcional si no está registrado), vendedor (`empleado`), método de pago, detalle de libros, cantidades y precio unitario histórico.
3. **Gestión de Compras a Proveedores (`orden_compra`, `detalle_orden_compra`):** Control de órdenes de compra a editoriales y distribuidores (`pendiente`, `recibida`, `cancelada`) con actualización automática del inventario al recibir los ejemplares.
4. **Sistema de Préstamos de Biblioteca (`prestamo`, `detalle_prestamo`, `multa`):** Registro de préstamos a domicilio y en sala de lectura (`domicilio`, `sala_lectura`), fechas de salida y devolución, estados (`activo`, `devuelto`, `vencido`) y gestión de multas por retraso (`pendiente`, `pagada`, `exonerada`).
5. **Registro de Clientes, Socios y Recomendaciones (`cliente`, `membresia_socio`, `preferencia_cliente`):** Mantenimiento de clientes ocasionales, frecuentes y socios con carnet de biblioteca, historial completo de compras y préstamos, y preferencias de lectura por género.
6. **Control de Proveedores (`proveedor`):** Registro de editoriales y distribuidores (nacionales e internacionales), datos de contacto, condiciones de pago e historial de órdenes de compra.
7. **Reportes de Gestión (Vistas SQL):** Generación de reportes de libros más vendidos, libros más prestados y recomendaciones personalizadas.
8. **Gestión de Devoluciones (`devolucion_cliente`, `detalle_devolucion_cliente`, `devolucion_proveedor`, `detalle_devolucion_proveedor`):** Registro de devoluciones de clientes (con reingreso al inventario si el libro está en buen estado) y devoluciones a proveedores por defectos de fábrica o transporte.

---

## Estructura del Repositorio

```text
├── sql/
│   ├── 01_crear_tablas.sql        # DDL: 21 tablas, claves primarias, foráneas, CHECKs e índices
│   ├── 02_datos_prueba.sql        # DML: Datos de prueba
│   └── 03_triggers_y_vistas.sql   # PL/pgSQL: Triggers de inventario y vistas de reportes
└── README.md                      # Documentación general y diagrama ER
```

---

## Modelo Entidad-Relación

Revisa el [Diagrama ER](diagrama-er.md).

---

## Arquitectura de Tablas (Tercera Forma Normal - 3FN)

El esquema está compuesto por **21 tablas normalizadas** distribuidas en 6 módulos funcionales:

| Módulo | Tablas |
| :--- | :--- |
| **Catálogo e Inventario** | `editorial`, `genero`, `autor`, `libro`, `libro_autor` |
| **Clientes, Socios y Preferencias** | `cliente`, `membresia_socio`, `preferencia_cliente` |
| **Personal y Proveedores** | `empleado`, `proveedor` |
| **Ventas y Compras** | `venta`, `detalle_venta`, `orden_compra`, `detalle_orden_compra` |
| **Préstamos y Multas** | `prestamo`, `detalle_prestamo`, `multa` |
| **Gestión de Devoluciones** | `devolucion_cliente`, `detalle_devolucion_cliente`, `devolucion_proveedor`, `detalle_devolucion_proveedor` |

---

## Justificación de las Decisiones de Diseño

1. **Normalización hasta Tercera Forma Normal (3FN):**
   - Se separaron `editorial`, `genero` y `autor` de la tabla `libro` para evitar redundancia textual y anomalías de actualización.
   - La relación muchos a muchos ($N:M$) entre libros y autores se resolvió mediante la tabla intermedia `libro_autor`, permitiendo registrar coautorías.
   - En `devolucion_proveedor` no se almacena `id_proveedor` directamente, ya que este depende transitivamente de `id_orden` $\rightarrow$ `orden_compra.id_proveedor`, respetando estrictamente la 3FN.

2. **Separación entre `editorial` (bibliográfico) y `proveedor` (comercial):**
   - La editorial que publica un libro no siempre es el distribuidor que lo vende a la librería (especialmente en importaciones internacionales). Mantener ambas entidades separadas evita mezclar metadatos bibliográficos con condiciones comerciales de compra.

3. **Inventario Dual (`stock_venta` vs. `stock_biblioteca`):**
   - Al combinar librería comercial y biblioteca con sala de lectura, mezclar las existencias en un solo campo provocaría errores operativos (como vender el último ejemplar destinado a préstamo). Separar ambos contadores —junto con `destino_stock` en `detalle_orden_compra`— garantiza control exacto para cada línea de negocio.

4. **Cliente Opcional en Ventas (`venta.id_cliente` nulable):**
   - Permite registrar ventas rápidas al público general sin obligar al cliente a registrarse, manteniendo al mismo tiempo el historial detallado para clientes frecuentes y socios.

5. **Integridad Histórica de Precios y Costos:**
   - Almacenar `precio_unitario` en `detalle_venta` y `costo_unitario` en `detalle_orden_compra` asegura que los totales históricos de facturas y órdenes no cambien si el precio actual del libro se actualiza en el catálogo.

6. **Patrón Maestro-Detalle en Todas las Transacciones:**
   - Las operaciones de ventas, compras, préstamos y devoluciones utilizan tablas de encabezado y detalle, lo que permite incluir múltiples títulos en una misma transacción, gestionar devoluciones parciales y facilitar consultas analíticas para reportes.

7. **Extensión 1:0..1 para Socios (`membresia_socio`) y Preferencias (`preferencia_cliente`):**
   - Evita almacenar valores `NULL` en clientes ocasionales y permite generar recomendaciones personalizadas cruzando los géneros favoritos del lector con su historial de compras y préstamos.

8. **Separación de Devoluciones de Clientes y Proveedores:**
   - En lugar de una tabla polimórfica con claves foráneas opcionales, `devolucion_cliente` y `devolucion_proveedor` garantizan integridad referencial estricta y modelan flujos distintos (`reingresa_inventario` vs. reclamos por defecto).

---

## Requisitos Previos

- **PostgreSQL** versión 12 o superior.
- **pgAdmin 4** (interfaz gráfica) o cliente de línea de comandos **`psql`**.

---

## Instalación y Ejecución

> **Importante:** Ejecutar los scripts en orden estricto (`01` $\rightarrow$ `02` $\rightarrow$ `03`) para que la carga inicial de datos históricos no dispare doblemente los triggers sobre el stock inicial.

### Opción A: Usando pgAdmin 4
1. Abrir **pgAdmin 4** y conectarse al servidor PostgreSQL.
2. Hacer clic derecho en **Databases** $\rightarrow$ **Create** $\rightarrow$ **Database...**, asignar el nombre `libreria-cultural` y guardar.
3. Hacer clic derecho sobre `libreria-cultural` $\rightarrow$ **Query Tool**.
4. Abrir y ejecutar los scripts en el siguiente orden:
   1. `sql/01_crear_tablas.sql`
   2. `sql/02_datos_prueba.sql`
   3. `sql/03_triggers_y_vistas.sql`

### Opción B: Usando la terminal (`psql`)
```bash
createdb -U postgres libreria-cultural
psql -U postgres -d libreria-cultural -f sql/01_crear_tablas.sql
psql -U postgres -d libreria-cultural -f sql/02_datos_prueba.sql
psql -U postgres -d libreria-cultural -f sql/03_triggers_y_vistas.sql
```

---

## ⚡ Automatización (Triggers) y Vistas de Reportes

### Triggers Implementados (`03_triggers_y_vistas.sql`)
- `trg_orden_compra_recibida`: Suma automáticamente los ejemplares recibidos a `stock_venta` o `stock_biblioteca` cuando una orden pasa a estado `'recibida'`.
- `trg_venta_descontar_stock`: Verifica disponibilidad en `stock_venta` y descuenta las unidades vendidas al registrar cada línea en `detalle_venta`.
- `trg_prestamo_stock`: Descuenta ejemplares de `stock_biblioteca` al registrar un préstamo y los reintegra automáticamente cuando el ítem pasa a estado `'devuelto'`.
- `trg_devolucion_cliente_stock`: Reingresa a `stock_venta` los ejemplares devueltos por clientes cuando `reingresa_inventario = TRUE`.
- `trg_devolucion_proveedor_stock`: Descuenta de `stock_venta` los ejemplares defectuosos devueltos al proveedor.
