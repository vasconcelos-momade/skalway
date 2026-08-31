#!/usr/bin/env bash
# Cópia sanitizada tenant produção → teste (VPS / produção).
#
# Pré-requisitos:
#   - phrx_backend com docker.sock montado (docker-compose.prod.yml)
#   - Imagem skalway-phrx-backend:prod com docker.io + default-mysql-client
#
# Uso (na VPS):
#   cd /opt/skalway-repo
#   cp infra/docker/phrx/tenant-clone.prod.env.example infra/docker/phrx/tenant-clone.prod.env
#   source infra/docker/phrx/tenant-clone.prod.env
#   ./infra/scripts/backup-before-tenant-clone.sh --apply    # backup antes do clone
#   ./infra/scripts/tenant-clone-sanitized.sh --list-tenants
#   ./infra/scripts/tenant-clone-sanitized.sh --source-db=phrx_tenant_2_branch_3 --target-db=phrx_tenant_1_branch_1 --dry-run
#   ./infra/scripts/tenant-clone-sanitized.sh --source-db=phrx_tenant_2_branch_3 --target-db=phrx_tenant_1_branch_1 --yes
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
  warn "Criado ${TENANT_CLONE_ENV} a partir do example — confirme source/target antes de --yes"
fi

if [[ -f "$TENANT_CLONE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$TENANT_CLONE_ENV"
fi

# Valores por omissão VPS (cliente real protegido)
PROTECTED_DATABASES="${PROTECTED_DATABASES:-phrx_tenant_2_branch_3,skalway_central,production,prod}"
export PROTECTED_DATABASES

BACKEND_CONTAINER="${BACKEND_CONTAINER:-phrx_backend}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"
BACKUP_ROOT="${SKALWAY_ROOT:-/opt/skalway}/backups/tenant-clone"

load_mysql_root_password() {
  if [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]]; then
    return 0
  fi
  if [[ -f "${COMPOSE_DIR}/.env" ]]; then
    MYSQL_ROOT_PASSWORD="$(grep -E '^MYSQL_ROOT_PASSWORD=' "${COMPOSE_DIR}/.env" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
    export MYSQL_ROOT_PASSWORD
  fi
}

list_tenants() {
  load_mysql_root_password
  [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || die "MYSQL_ROOT_PASSWORD não definido (export ou ${COMPOSE_DIR}/.env)"

  log "Tenants activos (Central + bases MySQL):"
  docker exec "$MYSQL_CONTAINER" mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" skalway_central --batch -e "
SELECT
  t.id AS tenant_id,
  t.tenantKey,
  t.tenantName,
  b.id AS branch_id,
  b.codigo AS branch_code,
  b.nome AS branch_name,
  b.dbName,
  b.ativo AS branch_active,
  IFNULL(
    (SELECT COUNT(*)
     FROM information_schema.SCHEMATA s
     WHERE s.SCHEMA_NAME = b.dbName),
    0
  ) AS db_exists
FROM tenants t
JOIN branches b ON b.tenantId = t.id
WHERE t.deletedAt IS NULL
  AND b.deletedAt IS NULL
ORDER BY t.id, b.id;
" 2>/dev/null
}

if [[ "${1:-}" == "--list-tenants" ]]; then
  require_cmd docker
  list_tenants
  exit 0
fi

require_cmd docker

if ! docker inspect -f '{{.State.Running}}' "$BACKEND_CONTAINER" 2>/dev/null | grep -q true; then
  die "Container ${BACKEND_CONTAINER} não está a correr."
fi
if ! docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER" 2>/dev/null | grep -q true; then
  die "Container ${MYSQL_CONTAINER} não está a correr."
fi

load_mysql_root_password

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_DIR:-${BACKUP_ROOT}/${STAMP}}"

log "Backend:  ${BACKEND_CONTAINER}"
log "MySQL:    ${MYSQL_CONTAINER}"
log "Backups:  ${BACKUP_DIR} (no container: /usr/src/app/backups/tenant-clone/${STAMP})"

exec docker exec \
  -e MYSQL_CONTAINER="$MYSQL_CONTAINER" \
  -e TENANT_CLONE_USE_DOCKER=1 \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-}" \
  -e PROTECTED_DATABASES="${PROTECTED_DATABASES:-}" \
  -e BACKUP_DIR="/usr/src/app/backups/tenant-clone/${STAMP}" \
  "$BACKEND_CONTAINER" \
  bun run tenant:clone-sanitized -- --backup-dir="/usr/src/app/backups/tenant-clone/${STAMP}" "$@"
