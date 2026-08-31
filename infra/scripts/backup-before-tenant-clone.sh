#!/usr/bin/env bash
# Backup MySQL antes de tenant-clone-sanitized.
#
# Faz dump (read-only) da origem (cliente real) e do destino (teste) antes do clone.
# Por omissão: dry-run. Use --apply para executar.
#
# Uso (VPS):
#   cd /opt/skalway-repo
#   source infra/docker/phrx/tenant-clone.prod.env
#   ./infra/scripts/backup-before-tenant-clone.sh --dry-run
#   ./infra/scripts/backup-before-tenant-clone.sh --apply
#
# Uso (explícito):
#   ./infra/scripts/backup-before-tenant-clone.sh \
#     --source-db=phrx_tenant_2_branch_3 \
#     --target-db=phrx_tenant_1_branch_1 \
#     --apply
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

COMPOSE_DIR="${PHRX_COMPOSE_DIR}"
TENANT_CLONE_ENV="${COMPOSE_DIR}/tenant-clone.prod.env"
TENANT_CLONE_ENV_EXAMPLE="${COMPOSE_DIR}/tenant-clone.prod.env.example"

if [[ ! -f "$TENANT_CLONE_ENV" && -f "$TENANT_CLONE_ENV_EXAMPLE" ]]; then
  cp "$TENANT_CLONE_ENV_EXAMPLE" "$TENANT_CLONE_ENV"
  chmod 600 "$TENANT_CLONE_ENV"
fi

if [[ -f "$TENANT_CLONE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$TENANT_CLONE_ENV"
fi

MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"
BACKUP_ROOT="${SKALWAY_ROOT:-/opt/skalway}/backups/pre-tenant-clone"
if [[ ! -d "$(dirname "$BACKUP_ROOT")" ]] && [[ -d "$COMPOSE_DIR" ]]; then
  BACKUP_ROOT="${COMPOSE_DIR}/backups/pre-tenant-clone"
fi

SOURCE_DB="${TENANT_CLONE_SOURCE_DB:-}"
TARGET_DB="${TENANT_CLONE_TARGET_DB:-}"
INCLUDE_CENTRAL=0
APPLY=0

usage() {
  cat <<'EOF'
Backup antes de tenant-clone-sanitized

Uso:
  ./infra/scripts/backup-before-tenant-clone.sh [opções]

Opções:
  --source-db=<nome>    Base de origem (cliente real)
  --target-db=<nome>    Base de destino (teste)
  --include-central     Incluir skalway_central no backup
  --apply               Executar dumps (sem isto: dry-run)
  --dry-run, -n         Mostrar plano (omissão)
  --help, -h            Ajuda

Variáveis (tenant-clone.prod.env):
  TENANT_CLONE_SOURCE_DB   ex: phrx_tenant_2_branch_3
  TENANT_CLONE_TARGET_DB   ex: phrx_tenant_1_branch_1
  SKALWAY_ROOT             ex: /opt/skalway
  MYSQL_CONTAINER          ex: phrx_mysql
  MYSQL_ROOT_PASSWORD

Exemplo VPS:
  source infra/docker/phrx/tenant-clone.prod.env
  ./infra/scripts/backup-before-tenant-clone.sh --apply
  ./infra/scripts/tenant-clone-sanitized.sh --source-db=... --target-db=... --yes
EOF
}

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --dry-run|-n) APPLY=0 ;;
    --include-central) INCLUDE_CENTRAL=1 ;;
    --source-db=*) SOURCE_DB="${arg#--source-db=}" ;;
    --target-db=*) TARGET_DB="${arg#--target-db=}" ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Argumento desconhecido: $arg (use --help)"
      ;;
  esac
done

load_mysql_root_password() {
  if [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]]; then
    return 0
  fi
  if [[ -f "${COMPOSE_DIR}/.env" ]]; then
    MYSQL_ROOT_PASSWORD="$(grep -E '^MYSQL_ROOT_PASSWORD=' "${COMPOSE_DIR}/.env" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
    export MYSQL_ROOT_PASSWORD
  fi
}

assert_safe_db_name() {
  local db="$1"
  [[ "$db" =~ ^[a-zA-Z0-9_]+$ ]] || die "Nome de base inválido: $db"
}

db_exists() {
  local db="$1"
  docker exec "$MYSQL_CONTAINER" mysql -N -uroot -p"${MYSQL_ROOT_PASSWORD}" \
    -e "SELECT COUNT(*) FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='${db}';" \
    2>/dev/null | tr -d '[:space:]'
}

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_DIR:-${BACKUP_ROOT}/${STAMP}}"

[[ -n "$SOURCE_DB" ]] || die "Defina --source-db ou TENANT_CLONE_SOURCE_DB"
[[ -n "$TARGET_DB" ]] || die "Defina --target-db ou TENANT_CLONE_TARGET_DB"
[[ "$SOURCE_DB" != "$TARGET_DB" ]] || die "Origem e destino são iguais: $SOURCE_DB"

assert_safe_db_name "$SOURCE_DB"
assert_safe_db_name "$TARGET_DB"

require_cmd docker

load_mysql_root_password
[[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || die "MYSQL_ROOT_PASSWORD não definido"

docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1 || die "Container em falta: $MYSQL_CONTAINER"

DBS=("$SOURCE_DB" "$TARGET_DB")
if [[ "$INCLUDE_CENTRAL" -eq 1 ]]; then
  DBS=("skalway_central" "${DBS[@]}")
fi

log "Container:  $MYSQL_CONTAINER"
log "Origem:     $SOURCE_DB (read-only dump)"
log "Destino:    $TARGET_DB"
log "Destino fs: $OUT_DIR"
log "Modo:       $([[ "$APPLY" -eq 1 ]] && echo APPLY || echo DRY-RUN)"

for db in "${DBS[@]}"; do
  count="$(db_exists "$db")"
  [[ "$count" == "1" ]] || die "Base não encontrada: $db"
done

if [[ "$APPLY" -eq 0 ]]; then
  log "Plano:"
  printf '  1) mkdir -p %s\n' "$OUT_DIR"
  for db in "${DBS[@]}"; do
    printf '  2) mysqldump --single-transaction %s → %s/%s.sql.gz\n' "$db" "$OUT_DIR" "$db"
  done
  printf '  3) sha256sum + MANIFEST.txt + RESTORE.md\n'
  log "Dry-run: nenhuma alteração. Para executar: $0 --apply"
  exit 0
fi

mkdir -p "$OUT_DIR"

for db in "${DBS[@]}"; do
  log "Dump $db"
  dump_file="${OUT_DIR}/${db}.sql"
  docker exec "$MYSQL_CONTAINER" mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD}" \
    --ssl-mode=DISABLED \
    --single-transaction \
    --routines \
    --triggers \
    --databases "$db" >"$dump_file"
  gzip -f "$dump_file"
  sha256sum "${dump_file}.gz" >"${dump_file}.gz.sha256"
done

{
  echo "# Backup pré tenant-clone — ${STAMP}"
  echo "source_db=${SOURCE_DB}"
  echo "target_db=${TARGET_DB}"
  echo "include_central=${INCLUDE_CENTRAL}"
  echo ""
  echo "# Bases incluídas:"
  for db in "${DBS[@]}"; do
    echo "$db"
  done
} >"${OUT_DIR}/MANIFEST.txt"

cat >"${OUT_DIR}/RESTORE.md" <<EOF
# Restaurar backup pré-clone (${STAMP})

## Destino de teste (rollback do clone)
\`\`\`bash
gunzip -c ${OUT_DIR}/${TARGET_DB}.sql.gz | \\
  docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p"\$MYSQL_ROOT_PASSWORD" --ssl-mode=DISABLED
\`\`\`

## Origem (só se necessário — não deveria ser alterada pelo clone)
\`\`\`bash
gunzip -c ${OUT_DIR}/${SOURCE_DB}.sql.gz | \\
  docker exec -i ${MYSQL_CONTAINER} mysql -uroot -p"\$MYSQL_ROOT_PASSWORD" --ssl-mode=DISABLED
\`\`\`

Verificar checksum antes de restaurar:
\`\`\`bash
cd ${OUT_DIR} && sha256sum -c *.sha256
\`\`\`
EOF

log "Backup concluído: $OUT_DIR"
log "Próximo passo:"
printf '  ./infra/scripts/tenant-clone-sanitized.sh --source-db=%s --target-db=%s --dry-run\n' "$SOURCE_DB" "$TARGET_DB"
