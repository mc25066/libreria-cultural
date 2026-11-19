#!/usr/bin/env bash
set -euo pipefail

DB_NAME="libreria_cultural"
BACKUP_USER="usr_respaldo"     # Rol con pg_read_all_data (no superusuario)
PG_CONF_DIR="/etc/postgresql/17/main"
BACKUP_DIR="/var/backups/postgresql/libreria_cultural"
RETENTION_DAYS=30
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$BACKUP_DIR/config"

# 1. Respaldo lógico comprimido de libreria_cultural (formato custom)
pg_dump -U "$BACKUP_USER" -d "$DB_NAME" -Fc --compress=zstd \
    -f "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"

# 2. Respaldo de roles y privilegios globales
pg_dumpall -U postgres --globals-only > "$BACKUP_DIR/globals_${TIMESTAMP}.sql"

# 3. Respaldo de archivos de configuración del servidor (no incluidos en pg_dumpall)
cp "$PG_CONF_DIR"/postgresql.conf "$PG_CONF_DIR"/pg_hba.conf "$BACKUP_DIR/config/" 2>/dev/null || true

# 4. Verificación básica de integridad del archivo generado
pg_restore --list "$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump" > /dev/null

# 5. Política de retención: eliminar backups mayores a 30 días
find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "*.dump" -o -name "*.sql" \) -mtime +"$RETENTION_DAYS" -delete

echo "[$(date)] Respaldo completado y verificado: ${DB_NAME}_${TIMESTAMP}.dump"