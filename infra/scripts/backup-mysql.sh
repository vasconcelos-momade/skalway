#!/usr/bin/env bash
# Backup MySQL PhRx — descobre skalway_central + phrx_tenant_*_branch_* automaticamente.
# PREPARADO para futuro. Por omissão: dry-run (mostra o plano).
#
# Uso:
#   ./backup-mysql.sh                 # dry-run
#   ./backup-mysql.sh --dry-run
#   ./backup-mysql.sh --apply         # executa dump local via container
#
# Variáveis:
#   MYSQL_CONTAINER   (default: phrx_mysql)
#   MYSQL_ROOT_PASSWORD
#   BACKUP_DIR        (default: ./backups/mysql relativo ao compose dir)
#   RETENTION_DAYS    (default: 14)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

APPLY=0
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1; DRY_RUN=0 ;;
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

if [[ "$APPLY" -eq 0 ]]; then
  DRY_RUN=1
fi

MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"
BACKUP_DIR="${BACKUP_DIR:-${PHRX_COMPOSE_DIR}/backups/mysql}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${BACKUP_DIR}/${STAMP}"

require_cmd docker

log "Container: $MYSQL_CONTAINER"
log "Destino:   $OUT_DIR"
log "Retenção:  ${RETENTION_DAYS} dias"
log "Modo:      $([[ "$DRY_RUN" -eq 1 ]] && echo DRY-RUN || echo APPLY)"

if [[ -z "${MYSQL_ROOT_PASSWORD:-}" ]]; then
  if [[ -f "${PHRX_COMPOSE_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    # Carregar só MYSQL_ROOT_PASSWORD sem source completo (evitar overrides)
    MYSQL_ROOT_PASSWORD="$(grep -E '^MYSQL_ROOT_PASSWORD=' "${PHRX_COMPOSE_DIR}/.env" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
    set +a
  fi
fi

[[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || warn "MYSQL_ROOT_PASSWORD não definido — necessário para --apply"

list_dbs() {
  docker exec "$MYSQL_CONTAINER" mysql -N -uroot -p"${MYSQL_ROOT_PASSWORD}" \
    -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA
        WHERE SCHEMA_NAME = 'skalway_central'
           OR SCHEMA_NAME LIKE 'phrx_tenant\\_%\\_branch\\_%'
        ORDER BY SCHEMA_NAME;"
}

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Plano:"
  printf '  1) mkdir -p %s\n' "$OUT_DIR"
  printf '  2) listar bases: skalway_central + phrx_tenant_*_branch_*\n'
  printf '  3) mysqldump --single-transaction --routines --triggers por base\n'
  printf '  4) gzip + checksum\n'
  printf '  5) apagar backups > %s dias em %s\n' "$RETENTION_DAYS" "$BACKUP_DIR"
  if docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1 && [[ -n "${MYSQL_ROOT_PASSWORD:-}" ]]; then
    log "Bases detectáveis agora:"
    list_dbs 2>/dev/null | while read -r db; do
      [[ -n "$db" ]] && printf '    - %s\n' "$db"
    done || warn "Não foi possível listar bases (container/password)."
  else
    warn "Skip listagem (container em baixo ou password em falta)."
  fi
  log "Dry-run: nenhuma alteração. Para executar: $0 --apply"
  exit 0
fi

[[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || die "MYSQL_ROOT_PASSWORD obrigatório para --apply"
docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1 || die "Container em falta: $MYSQL_CONTAINER"

mkdir -p "$OUT_DIR"
mapfile -t DBS < <(list_dbs)
[[ "${#DBS[@]}" -gt 0 ]] || die "Nenhuma base PhRx encontrada (skalway_central / phrx_tenant_*)."

for db in "${DBS[@]}"; do
  [[ -n "$db" ]] || continue
  log "Dump $db"
  dump_file="${OUT_DIR}/${db}.sql"
  docker exec "$MYSQL_CONTAINER" mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction --routines --triggers --databases "$db" >"$dump_file"
  gzip -f "$dump_file"
  sha256sum "${dump_file}.gz" >"${dump_file}.gz.sha256"
done

printf '%s\n' "${DBS[@]}" >"${OUT_DIR}/MANIFEST.txt"
log "Backup concluído: $OUT_DIR (${#DBS[@]} bases)"

# Retenção
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime "+${RETENTION_DAYS}" -print -exec rm -rf {} + 2>/dev/null || true
log "Retenção aplicada (>${RETENTION_DAYS}d)."
