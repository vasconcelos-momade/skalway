#!/usr/bin/env bash
# Build Flutter Web PhRx (produção) — máquina LOCAL apenas.
# NÃO instala Flutter na VPS. NÃO faz flutter pub get por omissão.
#
# Uso:
#   ./build-web.sh
#   ./build-web.sh --clean          # flutter clean antes do build
#   ./build-web.sh --dry-run
#   ENVIRONMENT=prod ./build-web.sh
#
# Artefacto: apps/phrx/app/build/web/
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
APP_DIR="${ROOT}/apps/phrx/app"
WEB_OUT="${APP_DIR}/build/web"
ENVIRONMENT="${ENVIRONMENT:-prod}"
API_BASE_URL="${API_BASE_URL:-https://api.phrx.skalway.com}"
API_CLOUD_URL="${API_CLOUD_URL:-https://api.phrx.skalway.com}"
DO_CLEAN=0

for arg in "$@"; do
  case "$arg" in
    --clean) DO_CLEAN=1 ;;
    --dry-run|-n) ;;
    -h|--help)
      printf 'Uso: %s [--clean] [--dry-run]\n' "$0"
      exit 0
      ;;
  esac
done

[[ -d "$APP_DIR" ]] || die "App Flutter em falta: $APP_DIR"
[[ -f "${APP_DIR}/pubspec.yaml" ]] || die "pubspec.yaml em falta em $APP_DIR"

require_cmd flutter

log "Flutter: $(flutter --version 2>/dev/null | head -1 || flutter --version | head -1)"
if ! flutter config --list 2>/dev/null | grep -qi 'enable-web: true'; then
  # Fallback: tentar listar dispositivos web
  if ! flutter devices 2>/dev/null | grep -qiE 'web|chrome'; then
    warn "Não foi possível confirmar enable-web; a tentar build web mesmo assim"
  else
    log "Flutter Web disponível (devices)"
  fi
else
  log "Flutter Web: enable-web=true"
fi

log "App:            $APP_DIR"
log "ENVIRONMENT:    $ENVIRONMENT"
log "API_BASE_URL:   $API_BASE_URL"
log "API_CLOUD_URL:  $API_CLOUD_URL"
log "Clean:          $([[ "$DO_CLEAN" -eq 1 ]] && echo sim || echo não)"

(
  cd "$APP_DIR"
  if [[ "$DO_CLEAN" -eq 1 ]]; then
    log "flutter clean (explícito via --clean)"
    run flutter clean
  fi
  log "flutter build web --release"
  run flutter build web --release \
    --dart-define="ENVIRONMENT=${ENVIRONMENT}" \
    --dart-define="API_BASE_URL=${API_BASE_URL}" \
    --dart-define="API_CLOUD_URL=${API_CLOUD_URL}"
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run: skip validação de artefactos."
  exit 0
fi

[[ -f "${WEB_OUT}/index.html" ]] || die "Build inválido: falta ${WEB_OUT}/index.html"

# main.dart.js (html renderer) ou main.dart.wasm / flutter.js (canvasKit / wasm)
if [[ -f "${WEB_OUT}/main.dart.js" ]]; then
  log "Artefacto JS: main.dart.js"
elif [[ -f "${WEB_OUT}/flutter.js" ]]; then
  log "Artefacto bootstrap: flutter.js"
else
  die "Build inválido: nem main.dart.js nem flutter.js em ${WEB_OUT}"
fi

if [[ -d "${WEB_OUT}/assets" ]]; then
  log "assets/: presente"
else
  warn "assets/ ausente (pode ser normal conforme build)"
fi

size="$(du -sh "$WEB_OUT" 2>/dev/null | awk '{print $1}')"
log "Tamanho build/web: ${size:-?}"
log "Build Web OK → ${WEB_OUT}"
