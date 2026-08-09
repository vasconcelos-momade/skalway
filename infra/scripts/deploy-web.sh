#!/usr/bin/env bash
# Publicar Flutter Web PhRx na VPS a partir do monorepo (git pull).
# CORRER NA VPS (não usa rsync/SSH a partir da máquina local).
#
# Pré-requisito: apps/phrx/app/build/web/ já versionado e presente após git pull.
#
# Uso (na VPS):
#   cd /opt/skalway-repo
#   git pull origin main
#   sudo ./infra/scripts/deploy-web.sh
#   sudo ./infra/scripts/deploy-web.sh --dry-run
#   WEB_ROOT=/var/www/phrx sudo ./infra/scripts/deploy-web.sh
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

# Staging junto ao destino (mesmo FS) — evita /tmp e permite sudo em /var/www
WEB_PARENT="$(dirname "$WEB_ROOT")"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
NEXT="${WEB_ROOT}.next-${STAMP}"
PREV="${WEB_ROOT}.prev"
NGINX_LOG="$(mktemp "${TMPDIR:-/tmp}/phrx-nginx-t.XXXXXX" 2>/dev/null \
  || mktemp "${WEB_PARENT}/.phrx-nginx-t.XXXXXX" 2>/dev/null \
  || echo "${WEB_PARENT}/.phrx-nginx-t.${STAMP}")"

cleanup_staging_on_fail() {
  local ec=$?
  if [[ "$ec" -ne 0 && -d "$NEXT" && ! -e "$WEB_ROOT" ]]; then
    # Se o swap falhou a meio e WEB_ROOT sumiu, tentar restaurar PREV
    if [[ -d "$PREV" ]]; then
      mv "$PREV" "$WEB_ROOT" 2>/dev/null || true
    fi
  fi
  if [[ "$ec" -ne 0 && -d "$NEXT" ]]; then
    rm -rf "$NEXT" 2>/dev/null || true
  fi
  rm -f "$NGINX_LOG" 2>/dev/null || true
}
trap cleanup_staging_on_fail EXIT

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
mkdir -p "$NEXT" || die "Sem permissão para criar staging $NEXT (use sudo)"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${WEB_SRC}/" "${NEXT}/"
else
  (
    cd "$WEB_SRC"
    tar cf - .
  ) | (
    cd "$NEXT"
    tar xf -
  )
fi

[[ -f "${NEXT}/index.html" ]] || die "Staging inválido (sem index.html) — $WEB_ROOT intacto"

mkdir -p "$WEB_PARENT"
if [[ -d "$WEB_ROOT" ]]; then
  rm -rf "$PREV"
  mv "$WEB_ROOT" "$PREV"
fi
mv "$NEXT" "$WEB_ROOT"

# Permissões para Nginx (best-effort)
chmod -R a+rX "$WEB_ROOT" 2>/dev/null || true
if command -v chown >/dev/null 2>&1; then
  chown -R www-data:www-data "$WEB_ROOT" 2>/dev/null \
    || chown -R nginx:nginx "$WEB_ROOT" 2>/dev/null \
    || true
fi

[[ -f "${WEB_ROOT}/index.html" ]] || die "Publicação falhou: falta ${WEB_ROOT}/index.html"

log "Publicado: ${WEB_ROOT}/index.html"

if [[ "$RELOAD_NGINX" -eq 1 ]]; then
  if command -v nginx >/dev/null 2>&1; then
    if nginx -t >"$NGINX_LOG" 2>&1; then
      log "nginx -t OK"
      if command -v systemctl >/dev/null 2>&1; then
        systemctl reload nginx
        log "nginx reloaded"
      else
        nginx -s reload
        log "nginx reloaded (-s reload)"
      fi
    else
      warn "nginx -t falhou — site publicado mas reload não feito"
      head -20 "$NGINX_LOG" 2>/dev/null || true
      exit 1
    fi
  else
    warn "nginx indisponível — skip reload (correu sem privilégios? use sudo)"
  fi
fi

log "Deploy Web (git→/var/www/phrx) concluído. Backend Docker não foi tocado."
