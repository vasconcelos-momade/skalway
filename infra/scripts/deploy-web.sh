#!/usr/bin/env bash
# Publicar Flutter Web PhRx na VPS a partir do monorepo (git pull).
# CORRER NA VPS (não usa rsync/SSH a partir da máquina local).
#
# Pré-requisito: apps/phrx/app/build/web/ já versionado e presente após git pull.
#
# Uso (na VPS):
#   cd /opt/skalway-repo
#   git pull origin main
#   ./infra/scripts/deploy-web.sh
#   ./infra/scripts/deploy-web.sh --dry-run
#   WEB_ROOT=/var/www/phrx ./infra/scripts/deploy-web.sh
#
# Fluxo: validar build/web → staging → swap atómico → /var/www/phrx → nginx -t/reload
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
WEB_SRC="${WEB_SRC:-${ROOT}/apps/phrx/app/build/web}"
WEB_ROOT="${WEB_ROOT:-/var/www/phrx}"
RELOAD_NGINX=1

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) ;;
    --no-nginx-reload) RELOAD_NGINX=0 ;;
    -h|--help)
      printf 'Uso (na VPS): %s [--dry-run] [--no-nginx-reload]\n' "$0"
      printf '  WEB_SRC=%s\n' "$WEB_SRC"
      printf '  WEB_ROOT=%s\n' "$WEB_ROOT"
      exit 0
      ;;
  esac
done

[[ -d "$WEB_SRC" ]] || die "Build em falta: $WEB_SRC — faça git pull (build/web versionado) ou build local + push"
[[ -f "${WEB_SRC}/index.html" ]] || die "index.html em falta em $WEB_SRC"
if [[ ! -f "${WEB_SRC}/main.dart.js" && ! -f "${WEB_SRC}/flutter.js" ]]; then
  die "Artefactos Flutter em falta em $WEB_SRC (main.dart.js / flutter.js)"
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
NEXT="${WEB_ROOT}.next-${STAMP}"
PREV="${WEB_ROOT}.prev"

log "Origem:  $WEB_SRC"
log "Destino: $WEB_ROOT"
log "Staging: $NEXT"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run] rsync/cp %s/ → %s/\n' "$WEB_SRC" "$NEXT"
  printf '[dry-run] swap atómico → %s (backup %s)\n' "$WEB_ROOT" "$PREV"
  printf '[dry-run] nginx -t && systemctl reload nginx\n'
  log "Dry-run: nenhuma alteração em $WEB_ROOT"
  exit 0
fi

# Nunca apagar WEB_ROOT antes de ter staging válido
rm -rf "$NEXT"
mkdir -p "$NEXT"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${WEB_SRC}/" "${NEXT}/"
else
  # Fallback local (mesma máquina): cp -a
  (
    cd "$WEB_SRC"
    tar cf - .
  ) | (
    cd "$NEXT"
    tar xf -
  )
fi

[[ -f "${NEXT}/index.html" ]] || die "Staging inválido (sem index.html) — $WEB_ROOT intacto"

mkdir -p "$(dirname "$WEB_ROOT")"
if [[ -d "$WEB_ROOT" ]]; then
  rm -rf "$PREV"
  mv "$WEB_ROOT" "$PREV"
fi
mv "$NEXT" "$WEB_ROOT"

# Permissões para Nginx (best-effort)
chmod -R a+rX "$WEB_ROOT" 2>/dev/null || true
if command -v sudo >/dev/null 2>&1; then
  sudo chown -R www-data:www-data "$WEB_ROOT" 2>/dev/null \
    || sudo chown -R nginx:nginx "$WEB_ROOT" 2>/dev/null \
    || true
fi

[[ -f "${WEB_ROOT}/index.html" ]] || die "Publicação falhou: falta ${WEB_ROOT}/index.html"

log "Publicado: ${WEB_ROOT}/index.html"

if [[ "$RELOAD_NGINX" -eq 1 ]]; then
  if command -v nginx >/dev/null 2>&1 || command -v sudo >/dev/null 2>&1; then
    if sudo nginx -t 2>/tmp/phrx-nginx-t.txt; then
      log "nginx -t OK"
      sudo systemctl reload nginx
      log "nginx reloaded"
    else
      warn "nginx -t falhou — site publicado mas reload não feito"
      head -20 /tmp/phrx-nginx-t.txt 2>/dev/null || true
      exit 1
    fi
  else
    warn "nginx/sudo indisponível — skip reload"
  fi
fi

log "Deploy Web (git→/var/www/phrx) concluído. Backend Docker não foi tocado."
