# Plan de Gestión de Espacio en Disco, Mantenibilidad y Seguridad
**Proyecto:** Librería Cultural "El Saber" — Base de Datos `libreria_cultural` (PostgreSQL 14+/16/17)

---

## 1. Gestión del Crecimiento y Uso Eficiente del Espacio en Disco

### 1.1 Proyección de Crecimiento de Tablas
Las 21 tablas operativas del modelo 3NF y el esquema `auditoria` se clasifican según su tasa de crecimiento:
* **Catálogo y Maestros (Crecimiento bajo/moderado):** `editorial`, `genero`, `autor`, `libro`, `libro_autor`, `empleado`, `proveedor`. Crecen según nuevas adquisiciones editoriales (~1,000 a 5,000 registros/año).
* **Clientes y Socios (Crecimiento moderado):** `cliente`, `membresia_socio`, `preferencia_cliente`.
* **Transaccionales y Bitácora (Crecimiento alto):** `venta`, `detalle_venta`, `prestamo`, `detalle_prestamo`, `multa`, `orden_compra`, `auditoria.bitacora_auditoria`, `auditoria.venta_historica`.

### 1.2 Estrategias Implementadas (`04_espacio_indices_bitacora.sql`)
1. **Particionamiento Declarativo (`RANGE`):**
   * `auditoria.bitacora_auditoria` se particiona anualmente por `fecha_hora` (incluyendo la clave de partición en su llave primaria `(id_bitacora, fecha_hora)`). Esto permite desvincular (`DETACH PARTITION`) y archivar o eliminar registros históricos sin afectar el rendimiento operativo ni generar fragmentación (*bloat*).
   * Se incorpora `auditoria.venta_historica` particionada por `fecha_venta` para trasladar y archivar ventas de años cerrados sin modificar las llaves foráneas de la tabla operativa `venta`.
2. **Índices Parciales, Compuestos, de Expresión y `pg_trgm`:**
   * Se eliminan índices completos de baja cardinalidad (`idx_orden_compra_estado`, `idx_prestamo_estado`) y se reemplazan por **índices parciales** que indexan únicamente subconjuntos activos: `orden_compra` (`estado = 'pendiente'`), `prestamo` (`estado IN ('activo', 'vencido')`), `multa` (`estado = 'pendiente'`) y `libro` (`stock_venta > 0` / `stock_biblioteca > 0`), reduciendo el tamaño de índices en disco entre un 60% y 90%.
   * Se añaden índices **compuestos** (`idx_venta_cliente_fecha`), **de expresión** (`LOWER(titulo)`, `LOWER(apellido), LOWER(nombre)`) e **índices GIN con trigramas** (`pg_trgm`) para búsquedas parciales tolerantes a errores.
3. **Optimización de Páginas (`FILLFACTOR`):**
   * `libro` utiliza `fillfactor = 85`, mientras `prestamo` y `multa` utilizan `fillfactor = 90`, reservando espacio libre por página para soportar actualizaciones frecuentes de stock y estado mediante *HOT Updates* bajo MVCC sin provocar división prematura de páginas.
4. **Bitácoras (Motor PostgreSQL + Auditoría de Negocio):**
   * **Logs de PostgreSQL (`postgresql.conf`):**
     ```ini
     logging_collector = on
     log_directory = 'log'
     log_rotation_age = 1d
     log_rotation_size = 50MB
     log_min_duration_statement = 500   # Registra consultas lentas > 500ms
     log_statement = 'ddl'              # Audita cambios estructurales (CREATE/ALTER/DROP)
     log_connections = on
     log_disconnections = on
     wal_compression = zstd             # Comprime registros WAL (PG 15+; usar 'on' en PG 14)

     # Auditoría complementaria de sesión/objetos con extensión oficial pgAudit:
     shared_preload_libraries = 'pgaudit'
     pgaudit.log = 'ddl, write, role'
     ```
   * **Bitácora de Auditoría (`auditoria.bitacora_auditoria`):** Registra `id_transaccion`, usuario, aplicación, IP y valores previos/nuevos en formato `JSONB` ante operaciones `INSERT`, `UPDATE` y `DELETE` sobre `libro`, `venta`, `multa`, `orden_compra` y `empleado`. Sus registros son inmutables gracias al trigger `trg_proteger_bitacora`.

---

## 2. Plan de Mantenibilidad, Monitoreo, Backups y Restauración

### 2.1 Rutinas de Mantenimiento Periódico
| Frecuencia | Tarea | Comando / Herramienta | Objetivo |
| :--- | :--- | :--- | :--- |
| **Diaria (02:00)** | Backup automático completo + roles + configuración | `scripts/backup_libreria.sh` / `.ps1` | Garantizar punto de recuperación (RPO ≤ 24h). |
| **Continua** | Limpieza automática de tuplas muertas | `autovacuum = on` | Evitar *bloat* y *transaction ID wraparound*. |
| **Semanal** | Monitoreo de tamaño, conexiones, tuplas muertas y WAL | Consultas a `pg_stat_*` | Detectar crecimiento anómalo, saturación de `max_connections` o rezagos de archivado. |
| **Mensual** | Estadísticas y reconstrucción de índices | `VACUUM ANALYZE;` / `REINDEX (VERBOSE) TABLE ...` (o `CONCURRENTLY`) | Eliminar fragmentación en índices y mantener óptimos los planes de ejecución. |
| **Mensual** | Prueba de restauración | `scripts/restauracion_libreria.sh` en entorno de pruebas | Verificar que los volcados sean 100% restaurables. |
| **Anual (Dic.)** | Creación de particiones del nuevo año y archivado | `CREATE TABLE ... PARTITION OF ...` / `DETACH PARTITION` | Evitar acumulación en la partición `DEFAULT`. |

#### Consultas de Monitoreo (Espacio en Disco, Sesiones y Salud)
```sql
-- 1. Top 10 tablas más grandes (incluyendo datos e índices en esquemas public y auditoria)
SELECT
    schemaname || '.' || relname AS tabla,
    pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total,
    pg_size_pretty(pg_relation_size(relid)) AS solo_datos,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS solo_indices
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- 2. Revisar necesidad de VACUUM (tuplas muertas acumuladas por MVCC)
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- 3. Monitoreo de índices sin uso o poco eficientes
SELECT schemaname, relname AS tabla, indexrelname AS indice, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS tamano_indice
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;

-- 4. Monitoreo de conexiones concurrentes frente a max_connections
SELECT
    count(*) AS conexiones_activas,
    current_setting('max_connections')::int AS limite_maximo
FROM pg_stat_activity;

-- 5. Monitoreo del archivado continuo WAL
SELECT * FROM pg_stat_archiver;
```

### 2.2 Estrategia de Backups y Restauración
Se implementa una estrategia híbrida bajo la regla **3-2-1**:

1. **Respaldo Lógico Diario (`scripts/backup_libreria.sh` y `scripts/backup_libreria.ps1`):**
   * Ejecuta `pg_dump -Fc --compress=zstd` sobre `libreria_cultural` usando el usuario dedicado **`usr_respaldo`** (rol predefinido `pg_read_all_data`, sin privilegios de superusuario).
   * Respalda roles y privilegios globales con `pg_dumpall --globals-only`.
   * Copia por separado los archivos de configuración del servidor (`postgresql.conf` y `pg_hba.conf`), ya que `pg_dumpall` no los incluye.
   * Valida la legibilidad del respaldo mediante `pg_restore --list` y aplica una retención local de **30 días** (con copia externa fuera del servidor).

2. **Respaldo Físico y Recuperación en un Punto en el Tiempo (PITR — Entorno Productivo):**
   * Configuración en `postgresql.conf`:
     ```ini
     wal_level = replica
     archive_mode = on
     archive_command = 'test ! -f /backups/wal/%f && cp %p /backups/wal/%f'
     # Alternativa nativa desde PG 15+ (no combinar con archive_command):
     # archive_library = 'basic_archive'
     # basic_archive.archive_directory = '/backups/wal'
     archive_timeout = 60
     summarize_wal = on     # Habilita copias incrementales en PostgreSQL 17
     ```
   * Copia base semanal y verificación de integridad:
     ```bash
     pg_basebackup -h localhost -U postgres -D /backups/base -Fp -Xs -P
     pg_verifybackup /backups/base
     # Respaldo incremental (PostgreSQL 17):
     pg_basebackup -D /backups/incr1 --incremental=/backups/base/backup_manifest
     pg_combinebackup /backups/base /backups/incr1 -o /backups/combinada
     ```

3. **Procedimiento de Restauración Lógica (`scripts/restauracion_libreria.sh`):**
   * Crea la base de destino limpia a partir de **`template0`** (evitando conflictos con `template1`), restaura roles globales previos si aplica, ejecuta `pg_restore -j 4 -e` (deteniéndose ante el primer error) y finaliza con `ANALYZE;` para actualizar estadísticas del optimizador:
     ```bash
     ./scripts/restauracion_libreria.sh \
         /var/backups/postgresql/libreria_cultural/libreria_cultural_YYYYMMDD_HHMMSS.dump \
         /var/backups/postgresql/libreria_cultural/globals_YYYYMMDD_HHMMSS.sql
     ```
   * *Nota:* En caso de requerir recuperación granular ante borrado accidental por hora exacta (PITR), se detiene el servicio, se restaura la copia base, se limpia `pg_wal/`, se crea el archivo `recovery.signal` y se configuran `restore_command`, `recovery_target_time` y `recovery_target_action = 'promote'` en `postgresql.conf`.

---

## 3. Políticas de Seguridad y Encriptación (`05_seguridad_roles_encriptacion.sql`)

### 3.1 Matriz de Control de Acceso (RBAC) y Segregación de Funciones
Se revocan todos los privilegios del rol `PUBLIC` sobre `public` y `auditoria`, asignando permisos estrictos por puesto de trabajo (alineados con `empleado.cargo`):

| Rol de Grupo | Usuario Asignado | Alcance Principal | Restricciones Clave |
| :--- | :--- | :--- | :--- |
| `rol_administrador` | `usr_admin_saber` | DDL, mantenimiento y operación completa de `public` | Solo `SELECT` sobre `auditoria.bitacora_auditoria` (trazas protegidas por trigger). |
| `rol_bodeguero` | `usr_bodeguero_1` | Catálogo, proveedores, órdenes de compra y devoluciones a proveedor | Actualiza `stock_venta`/`stock_biblioteca` solo vía recepción/devolución; sin acceso a ventas ni multas. |
| `rol_vendedor` | `usr_vendedor_1` | Ventas, clientes, recomendaciones y devoluciones de clientes | Solo descuenta `stock_venta`; prohibido `DELETE` sobre `venta`. |
| `rol_bibliotecario` | `usr_biblio_1` | Socios (`membresia_socio`), préstamos y multas | Solo actualiza `stock_biblioteca`; sin acceso a compras ni proveedores. |
| `rol_auditor` | `usr_auditor_1` | Lectura de tablas, vistas y `auditoria.bitacora_auditoria` | Segregación de funciones: únicamente `SELECT`, sin escritura en ninguna tabla. |
| `pg_read_all_data` | `usr_respaldo` | Ejecución exclusiva de `pg_dump` en backups automáticos | Lectura global sin privilegios de superusuario ni escritura. |

### 3.2 Estrategia de Encriptación
1. **Encriptación en Tránsito (SSL/TLS) y Autenticación:**
   * En `postgresql.conf`: `ssl = on`, `ssl_min_protocol_version = 'TLSv1.2'`, `password_encryption = 'scram-sha-256'`.
   * En `pg_hba.conf`: exigir conexiones cifradas rechazando `trust` o `md5`:
     ```text
     hostssl  libreria_cultural  all  192.168.1.0/24  scram-sha-256
     ```
2. **Encriptación a Nivel de Columna (`pgcrypto`):**
   * **Credenciales de empleados (`empleado.password_hash`):** Almacenadas con *hash* irreversible **Bcrypt** (`crypt(..., gen_salt('bf', 10))`).
   * **Datos personales de clientes (`cliente.telefono_cifrado`, `cliente.direccion_cifrada`):** Cifrados simétricamente con **AES-256** (`pgp_sym_encrypt` / `pgp_sym_decrypt`). La llave maestra se pasa por sesión (`SET LOCAL app.clave_cifrado = '...'`) sin quedar almacenada en el código SQL.
   * **Enmascaramiento (`vw_clientes_enmascarados`):** Oculta parcialmente `email`, `telefono` y `direccion` a usuarios que no poseen el rol administrativo o la llave de descifrado activa.
3. **Encriptación en Reposo (Sistema Operativo y Backups):**
   * Almacenar el directorio de datos (`PGDATA`) en volúmenes cifrados (LUKS en Linux / BitLocker en Windows) y cifrar las copias externas de `.dump` con `gpg` antes de subirlas a almacenamiento en la nube.