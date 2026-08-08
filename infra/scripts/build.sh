#!/usr/bin/env bash
# Build de artefactos PhRx (backend image + Flutter web).
# NÃO faz push nem deploy remoto.
#
# Uso:
#   ./build.sh --dry-run
#   ./build.sh
#   ./build.sh --backend-only
#   ./build.sh --web-only
#   API_BASE_URL=https://api.phrx.skalway.com ./build.sh --web-only
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
DO_BACKEND=1
DO_WEB=1
API_BASE_URL="${API_BASE_URL:-https://api.phrx.skalway.com}"
API_CLOUD_URL="${API_CLOUD_URL:-$API_BASE_URL}"

for arg in "$@"; do
  case "$arg" in
    --backend-only) DO_WEB=0 ;;
    --web-only) DO_BACKEND=0 ;;
    --dry-run|-n) ;;
  esac
done

if [[ "$DO_BACKEND" -eq 1 ]]; then
  log "Build imagem Docker backend (Dockerfile prod)"
  run docker build \
    -f "${ROOT}/apps/phrx/backend/Dockerfile" \
    -t skalway-phrx-backend:prod \
    "${ROOT}"
fi

if [[ "$DO_WEB" -eq 1 ]]; then
  if ! command -v flutter >/dev/null 2>&1; then
    warn "flutter não encontrado — skip web"
  else
    log "Flutter web release → apps/phrx/app/build/web"
    log "API_BASE_URL=$API_BASE_URL API_CLOUD_URL=$API_CLOUD_URL"
    (
      cd "${ROOT}/apps/phrx/app"
      run flutter build web --release \
        --dart-define="API_BASE_URL=${API_BASE_URL}" \
        --dart-define="API_CLOUD_URL=${API_CLOUD_URL}"
    )
  fi
fi

log "Build concluído."
[[ "$DRY_RUN" -eq 1 ]] && log "Modo dry-run activo."
