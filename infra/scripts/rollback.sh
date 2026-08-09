#!/usr/bin/env bash
# Rollback PhRx — imagem Docker anterior e/ou restore MySQL.
# PREPARADO para futuro. Por omissão: dry-run.
#
# Uso:
#   ./rollback.sh                              # mostra plano
#   ./rollback.sh --image skalway-phrx-backend:prod-prev
#   ./rollback.sh --from-backup DIR --apply
#
# NÃO executar contra VPS de produção nesta fase.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

APPLY=0
IMAGE=""
FROM_BACKUP=""

prev=""
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1; DRY_RUN=0 ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --image=*) IMAGE="${arg#--image=}" ;;
    --from-backup=*) FROM_BACKUP="${arg#--from-backup=}" ;;
  esac
  if [[ "$prev" == "--image" ]]; then IMAGE="$arg"; fi
  if [[ "$prev" == "--from-backup" ]]; then FROM_BACKUP="$arg"; fi
  prev="$arg"
done

if [[ "$APPLY" -eq 0 ]]; then
  DRY_RUN=1
fi

COMPOSE_FILE="${PHRX_COMPOSE_DIR}/docker-compose.prod.yml"
IMAGE="${IMAGE:-skalway-phrx-backend:prod-prev}"

log "Compose: $COMPOSE_FILE"
log "Imagem:  $IMAGE"
log "Backup:  ${FROM_BACKUP:-(nenhum)}"
log "Modo:    $([[ "$DRY_RUN" -eq 1 ]] && echo DRY-RUN || echo APPLY)"

log "Plano de rollback:"
printf '  1) Marcar/retagar imagem anterior → skalway-phrx-backend:prod\n'
printf '  2) docker compose -f docker-compose.prod.yml up -d (backend + workers)\n'
printf '  3) (opcional) restore-mysql.sh --from <backup>\n'
printf '  4) healthcheck.sh\n'
printf '  5) (opcional) republicar Flutter Web anterior em /var/www/phrx\n'

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run: nenhuma alteração. Para executar: $0 --apply [--image TAG] [--from-backup DIR]"
  exit 0
fi

[[ -f "$COMPOSE_FILE" ]] || die "Compose prod em falta: $COMPOSE_FILE"
require_cmd docker

if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  log "Retag $IMAGE → skalway-phrx-backend:prod"
  run docker tag "$IMAGE" skalway-phrx-backend:prod
else
  warn "Imagem $IMAGE não encontrada localmente — compose usará o que existir"
fi

(
  cd "$PHRX_COMPOSE_DIR"
  [[ -f .env ]] || die ".env obrigatório"
  docker compose -f docker-compose.prod.yml --env-file .env up -d \
    phrx-backend phrx-backend-worker phrx-backend-print-worker
)

if [[ -n "$FROM_BACKUP" ]]; then
  log "Restore MySQL a partir de $FROM_BACKUP"
  "${SCRIPT_DIR}/restore-mysql.sh" --from "$FROM_BACKUP" --apply
fi

"${SCRIPT_DIR}/healthcheck.sh" || warn "Healthcheck falhou — investigar antes de tráfego"

log "Rollback local concluído."
