#!/usr/bin/env bash
# Deploy Flutter Web PhRx → VPS /var/www/phrx
# Compilação é LOCAL (build-web.sh). VPS só recebe ficheiros estáticos.
#
# Variáveis (obrigatórias para deploy real):
#   VPS_HOST   — hostname ou IP
#   VPS_USER   — utilizador SSH
# Opcionais:
#   VPS_WEB_ROOT=/var/www/phrx
#   VPS_SSH_PORT=22
#   WEB_BUILD_DIR  — default: <repo>/apps/phrx/app/build/web
#
# Uso:
#   VPS_HOST=… VPS_USER=vasco ./deploy-web.sh
#   VPS_HOST=… VPS_USER=vasco ./deploy-web.sh --dry-run
#
# Requer: rsync, ssh. NÃO inventa fallback inseguro sem rsync.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
WEB_BUILD_DIR="${WEB_BUILD_DIR:-${ROOT}/apps/phrx/app/build/web}"
VPS_WEB_ROOT="${VPS_WEB_ROOT:-/var/www/phrx}"
VPS_SSH_PORT="${VPS_SSH_PORT:-22}"

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) ;;
    -h|--help)
      printf 'Uso: VPS_HOST=… VPS_USER=… %s [--dry-run]\n' "$0"
      exit 0
      ;;
  esac
done

[[ -d "$WEB_BUILD_DIR" ]] || die "Build em falta: $WEB_BUILD_DIR — execute ./infra/scripts/build-web.sh primeiro"
[[ -f "${WEB_BUILD_DIR}/index.html" ]] || die "index.html em falta em $WEB_BUILD_DIR — rebuild necessário"

require_cmd rsync
require_cmd ssh

[[ -n "${VPS_HOST:-}" ]] || die "VPS_HOST não definido (ex.: VPS_HOST=phrx.example.com)"
[[ -n "${VPS_USER:-}" ]] || die "VPS_USER não definido (ex.: VPS_USER=vasco)"

SSH_TARGET="${VPS_USER}@${VPS_HOST}"
SSH_OPTS=(-p "$VPS_SSH_PORT" -o BatchMode=yes -o ConnectTimeout=15)

log "Origem:  $WEB_BUILD_DIR"
log "Destino: ${SSH_TARGET}:${VPS_WEB_ROOT}"
log "SSH:     porta $VPS_SSH_PORT"

log "Verificar SSH…"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run] ssh %s %s true\n' "${SSH_OPTS[*]}" "$SSH_TARGET"
else
  ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "true" \
    || die "SSH falhou para $SSH_TARGET — verificar chave/acesso (BatchMode)"
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REMOTE_STAGING="/tmp/phrx-web-staging-${STAMP}"
REMOTE_NEXT="${VPS_WEB_ROOT}.next-${STAMP}"

log "Staging remoto: $REMOTE_STAGING"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '[dry-run] ssh mkdir -p %s\n' "$REMOTE_STAGING"
  printf '[dry-run] rsync -az --delete %s/ %s:%s/\n' "$WEB_BUILD_DIR" "$SSH_TARGET" "$REMOTE_STAGING"
  printf '[dry-run] publicar atomicamente → %s\n' "$VPS_WEB_ROOT"
  log "Dry-run: nenhum ficheiro transferido."
  exit 0
fi

ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "mkdir -p '${REMOTE_STAGING}'"

# --delete só no staging (nunca apaga VPS_WEB_ROOT antes de ter build válido)
rsync -az --delete \
  -e "ssh -p ${VPS_SSH_PORT} -o BatchMode=yes" \
  "${WEB_BUILD_DIR}/" \
  "${SSH_TARGET}:${REMOTE_STAGING}/"

# Validar staging remoto
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "test -f '${REMOTE_STAGING}/index.html'" \
  || die "Staging sem index.html — abortar publicação"

# Publicação: copiar staging → .next, depois swap com actual (preserva anterior em .prev)
ssh "${SSH_OPTS[@]}" "$SSH_TARGET" bash -s <<EOF
set -Eeuo pipefail
WEB_ROOT='${VPS_WEB_ROOT}'
STAGING='${REMOTE_STAGING}'
NEXT='${REMOTE_NEXT}'
PREV="\${WEB_ROOT}.prev"

rm -rf "\$NEXT"
mkdir -p "\$NEXT"
# Cópia completa do staging validado
rsync -a --delete "\$STAGING"/ "\$NEXT"/
test -f "\$NEXT/index.html"

mkdir -p "\$(dirname "\$WEB_ROOT")"
if [[ -d "\$WEB_ROOT" ]]; then
  rm -rf "\$PREV"
  mv "\$WEB_ROOT" "\$PREV"
fi
mv "\$NEXT" "\$WEB_ROOT"

# Permissões típicas Nginx (best-effort; pode falhar sem sudo)
chmod -R a+rX "\$WEB_ROOT" 2>/dev/null || true

# Limpar staging
rm -rf "\$STAGING"

test -f "\$WEB_ROOT/index.html"
echo "Published \$WEB_ROOT"
EOF

log "Publicação OK: ${VPS_WEB_ROOT}/index.html"
log "Deploy Web concluído (backend Docker não foi tocado)."
