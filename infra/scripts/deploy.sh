#!/usr/bin/env bash
# Deploy PhRx (compose prod) — PREPARADO para futuro.
# Por omissão: DRY-RUN obrigatório fora de --apply (segurança).
#
# Uso:
#   ./deploy.sh                 # dry-run (mostra o plano)
#   ./deploy.sh --dry-run
#   ./deploy.sh --apply         # executa localmente compose prod (CUIDADO)
#
# NÃO usar contra VPS de produção nesta fase de organização.
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

# Sem --apply, forçar dry-run
if [[ "$APPLY" -eq 0 ]]; then
  DRY_RUN=1
fi

ENV_FILE="${PHRX_COMPOSE_DIR}/.env"
COMPOSE_FILE="${PHRX_COMPOSE_DIR}/docker-compose.prod.yml"

[[ -f "$COMPOSE_FILE" ]] || die "Compose prod em falta: $COMPOSE_FILE"

log "Compose: $COMPOSE_FILE"
log "Env:     $ENV_FILE"
log "Modo:    $([[ "$DRY_RUN" -eq 1 ]] && echo DRY-RUN || echo APPLY)"

if [[ ! -f "$ENV_FILE" ]]; then
  warn ".env em falta — criar a partir de .env.example antes de --apply"
fi

run docker compose -f "$COMPOSE_FILE" --env-file "${ENV_FILE:-/dev/null}" config >/dev/null

log "Plano:"
printf '  1) docker compose -f docker-compose.prod.yml pull/build\n'
printf '  2) docker compose -f docker-compose.prod.yml up -d\n'
printf '  3) healthcheck.sh\n'
printf '  4) (opcional) rsync build/web → /var/www/phrx\n'

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run: nenhuma alteração. Para executar localmente: $0 --apply"
  exit 0
fi

[[ -f "$ENV_FILE" ]] || die ".env obrigatório para --apply"

(
  cd "$PHRX_COMPOSE_DIR"
  docker compose -f docker-compose.prod.yml --env-file .env up -d --build
)

log "Deploy local apply concluído. Correr: ./healthcheck.sh"
