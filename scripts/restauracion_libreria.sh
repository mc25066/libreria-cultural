#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Uso: $0 <ruta_archivo.dump> [ruta_globals.sql]"
    exit 1
fi

DUMP_FILE="$1"
GLOBALS_FILE="${2:-}"
DB_NAME="libreria_cultural"
PG_USER="postgres"

if [ ! -f "$DUMP_FILE" ]; then
    echo "Error: No existe el archivo de respaldo '$DUMP_FILE'"
    exit 1
fi

# 1. Restaurar roles globales si se proporciona globals.sql
if [ -n "$GLOBALS_FILE" ] && [ -f "$GLOBALS_FILE" ]; then
    echo "Restaurando roles y privilegios globales..."
    psql -U "$PG_USER" --set ON_ERROR_STOP=on -d postgres -f "$GLOBALS_FILE"
fi

# 2. Recrear la base de datos limpia usando plantilla template0
echo "Creando base de datos '$DB_NAME' desde template0..."
dropdb -U "$PG_USER" --if-exists "$DB_NAME"
createdb -U "$PG_USER" -T template0 "$DB_NAME"

# 3. Restaurar estructura y datos en paralelo (-j 4) deteniéndose ante errores (-e)
echo "Restaurando respaldo '$DUMP_FILE'..."
pg_restore -U "$PG_USER" -d "$DB_NAME" -j 4 -e "$DUMP_FILE"

# 4. Recalcular estadísticas para el optimizador de consultas
echo "Ejecutando ANALYZE..."
psql -U "$PG_USER" -d "$DB_NAME" -c "ANALYZE;"

echo "Restauración de '$DB_NAME' finalizada exitosamente."