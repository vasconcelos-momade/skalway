#!/usr/bin/env bash
# Restore MySQL PhRx a partir de um dump gerado por backup-mysql.sh.
# PREPARADO para futuro. Por omissão: dry-run.
#
# Uso:
#   ./restore-mysql.sh --from /path/to/backups/mysql/20260101T120000Z
#   ./restore-mysql.sh --from ... --db skalway_central --dry-run
#   ./restore-mysql.sh --from ... --apply
#
# ATENÇÃO: --apply sobrescreve dados. Nunca usar em produção sem confirmação.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

APPLY=0
FROM=""
ONLY_DB=""

for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1; DRY_RUN=0 ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --from=*) FROM="${arg#--from=}" ;;
    --db=*) ONLY_DB="${arg#--db=}" ;;
  esac
done

# Parse --from / --db com valor separado
prev=""
for arg in "$@"; do
  if [[ "$prev" == "--from" ]]; then FROM="$arg"; fi
  if [[ "$prev" == "--db" ]]; then ONLY_DB="$arg"; fi
  prev="$arg"
done

if [[ "$APPLY" -eq 0 ]]; then
  DRY_RUN=1
fi

MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"

[[ -n "$FROM" ]] || die "Indicar --from <dir-do-backup>"
[[ -d "$FROM" ]] || die "Directório em falta: $FROM"

if [[ -z "${MYSQL_ROOT_PASSWORD:-}" && -f "${PHRX_COMPOSE_DIR}/.env" ]]; then
  MYSQL_ROOT_PASSWORD="$(grep -E '^MYSQL_ROOT_PASSWORD=' "${PHRX_COMPOSE_DIR}/.env" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi

log "Origem:    $FROM"
log "Container: $MYSQL_CONTAINER"
log "Filtro DB: ${ONLY_DB:-*(todos no manifesto)}"
log "Modo:      $([[ "$DRY_RUN" -eq 1 ]] && echo DRY-RUN || echo APPLY)"

shopt -s nullglob
files=("$FROM"/*.sql.gz)
[[ "${#files[@]}" -gt 0 ]] || die "Nenhum *.sql.gz em $FROM"

log "Ficheiros:"
for f in "${files[@]}"; do
  base="$(basename "$f" .sql.gz)"
  if [[ -n "$ONLY_DB" && "$base" != "$ONLY_DB" ]]; then
    continue
  fi
  printf '  - %s\n' "$f"
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Plano: gunzip -c | mysql -uroot por cada dump seleccionado"
  log "Dry-run: nenhuma alteração. Para executar: $0 --from '$FROM' --apply"
  exit 0
fi

[[ -n "${MYSQL_ROOT_PASSWORD:-}" ]] || die "MYSQL_ROOT_PASSWORD obrigatório"
docker inspect "$MYSQL_CONTAINER" >/dev/null 2>&1 || die "Container em falta: $MYSQL_CONTAINER"

for f in "${files[@]}"; do
  base="$(basename "$f" .sql.gz)"
  if [[ -n "$ONLY_DB" && "$base" != "$ONLY_DB" ]]; then
    continue
  fi
  if [[ -f "${f}.sha256" ]]; then
    log "Verificar checksum $base"
    (cd "$(dirname "$f")" && sha256sum -c "$(basename "$f").sha256")
  fi
  log "Restore $base"
  gunzip -c "$f" | docker exec -i "$MYSQL_CONTAINER" \
    mysql -uroot -p"${MYSQL_ROOT_PASSWORD}"
done

log "Restore concluído."
