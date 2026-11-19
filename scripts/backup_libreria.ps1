$ErrorActionPreference = "Stop"

$PgBin = "C:\Program Files\PostgreSQL\17\bin"
$PgData = "C:\Program Files\PostgreSQL\17\data"
$DbName = "libreria_cultural"
$BackupUser = "usr_respaldo"
$BackupDir = "C:\Backups\PostgreSQL\libreria_cultural"
$RetentionDays = 30
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

New-Item -ItemType Directory -Force -Path "$BackupDir\config" | Out-Null

# 1. Respaldo lógico de libreria_cultural
& "$PgBin\pg_dump.exe" -U $BackupUser -d $DbName -Fc --compress=zstd -f "$BackupDir\${DbName}_$Timestamp.dump"

# 2. Respaldo de roles globales
& "$PgBin\pg_dumpall.exe" -U postgres --globals-only -f "$BackupDir\globals_$Timestamp.sql"

# 3. Copia de archivos de configuración
Copy-Item "$PgData\postgresql.conf", "$PgData\pg_hba.conf" -Destination "$BackupDir\config\" -ErrorAction SilentlyContinue

# 4. Verificación de integridad
& "$PgBin\pg_restore.exe" --list "$BackupDir\${DbName}_$Timestamp.dump" | Out-Null

# 5. Política de retención
Get-ChildItem -Path $BackupDir -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    Remove-Item -Force

Write-Host "[$Timestamp] Respaldo completado: ${DbName}_$Timestamp.dump"