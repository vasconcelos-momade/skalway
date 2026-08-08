#!/usr/bin/env bash
# Prepara estrutura local/futura de deploy (idempotente).
# NÃO configura VPS remota. NÃO altera Cloudflare/DNS.
#
# Uso:
#   ./bootstrap.sh --dry-run
#   ./bootstrap.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
log "Repo: $ROOT"
log "Compose PhRx: $PHRX_COMPOSE_DIR"

run mkdir -p \
  "${ROOT}/infra/docker/phrx" \
  "${ROOT}/infra/nginx" \
  "${ROOT}/infra/scripts" \
  "${ROOT}/infra/cloudflare" \
  "${ROOT}/infra/compose" \
  "${ROOT}/docs/architecture" \
  "${ROOT}/docs/infrastructure" \
  "${ROOT}/docs/database" \
  "${ROOT}/docs/deployment" \
  "${ROOT}/docs/operations"

ENV_EXAMPLE="${PHRX_COMPOSE_DIR}/.env.example"
ENV_FILE="${PHRX_COMPOSE_DIR}/.env"

if [[ ! -f "$ENV_FILE" && -f "$ENV_EXAMPLE" ]]; then
  log "Criar .env a partir de .env.example (local)"
  run cp "$ENV_EXAMPLE" "$ENV_FILE"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod 600 "$ENV_FILE" 2>/dev/null || true
  else
    printf '[dry-run] chmod 600 %s\n' "$ENV_FILE"
  fi
else
  log ".env já existe ou .env.example em falta — skip"
fi

log "Bootstrap concluído (apenas repositório / local)."
[[ "$DRY_RUN" -eq 1 ]] && log "Modo dry-run: nenhuma alteração destrutiva."
