#!/usr/bin/env bash
# Orquestrador LOCAL: build Flutter Web → (opcional commit/push) → lembrar publish na VPS.
#
# Fluxo Git (fonte de verdade):
#   local: build-web.sh → versionar apps/phrx/app/build/web/ → push
#   VPS:   git pull → ./infra/scripts/deploy-web.sh → /var/www/phrx
#
# Uso:
#   ./deploy-web-production.sh --build-only
#   ./deploy-web-production.sh --commit          # build + commit/push (sem SSH)
#   ./deploy-web-production.sh --dry-run
#
# NÃO faz rsync/SSH. Publicação na VPS é separada (deploy-web.sh no servidor).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
DO_COMMIT=0
BUILD_ONLY=0

for arg in "$@"; do
  case "$arg" in
    --commit) DO_COMMIT=1 ;;
    --build-only) BUILD_ONLY=1 ;;
    --dry-run|-n) ;;
    -h|--help)
      printf 'Uso: %s [--build-only] [--commit] [--dry-run]\n' "$0"
      printf '  Na VPS depois do push:\n'
      printf '    cd /opt/skalway-repo && git pull origin main && ./infra/scripts/deploy-web.sh\n'
      exit 0
      ;;
  esac
done

cd "$ROOT"

log "1) Validar Git"
require_cmd git
[[ -d .git ]] || die "Não é um repositório Git"
branch="$(git branch --show-current)"
log "Branch: $branch"
remote="$(git remote get-url origin 2>/dev/null || true)"
log "Origin: ${remote:-(nenhum)}"

log "2) Build Flutter Web"
if [[ "$DRY_RUN" -eq 1 ]]; then
  "${SCRIPT_DIR}/build-web.sh" --dry-run
else
  "${SCRIPT_DIR}/build-web.sh"
fi

WEB_OUT="${ROOT}/apps/phrx/app/build/web"
log "3) Validar build"
if [[ "$DRY_RUN" -eq 0 ]]; then
  [[ -f "${WEB_OUT}/index.html" ]] || die "Build inválido"
  if [[ ! -f "${WEB_OUT}/main.dart.js" && ! -f "${WEB_OUT}/flutter.js" ]]; then
    die "Build inválido: falta main.dart.js / flutter.js"
  fi
  log "build/web OK ($(du -sh "$WEB_OUT" | awk '{print $1}'))"
fi

log "4) Git status"
git status -sb || true

if [[ "$DO_COMMIT" -eq 1 ]]; then
  log "5) Commit/push (--commit) incluindo apps/phrx/app/build/web/"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] git add build/web + alterações; commit; push origin\n'
  else
    if git status --porcelain | grep -qE '(^.. \.env|/\.env$|\.pem$|\.key$|id_rsa|credentials)'; then
      die "Alterações sensíveis detectadas (.env/keys) — abortar"
    fi
    git add -A -- \
      .gitignore \
      apps/phrx/.gitignore \
      apps/phrx/app/.gitignore \
      apps/phrx/app/build/web \
      infra/scripts/deploy-web.sh \
      infra/scripts/deploy-web-production.sh \
      docs/deployment/production.md \
      infra/README.md \
      2>/dev/null || true
    git add apps/phrx/app/build/web/
    # Rejeitar secrets no staging
    if git diff --cached --name-only | grep -qiE '(^|/)\.env(\.|$)|\.pem$|\.key$|id_rsa|credentials|cloudflare/origin'; then
      die "Staging contém secrets — abortado"
    fi
    if git diff --cached --quiet; then
      log "Nada novo para commit"
    else
      git commit -m "$(cat <<'EOF'
chore(phrx): update flutter web production build

EOF
)"
      git push origin HEAD
      log "Push OK → origin/${branch}"
    fi
  fi
else
  log "5) Sem --commit: adicione build/web e faça push manualmente quando pronto"
  printf '  git add apps/phrx/app/build/web/ .gitignore apps/phrx/.gitignore apps/phrx/app/.gitignore infra/scripts docs\n'
  printf '  git commit -m "chore(phrx): update flutter web production build"\n'
  printf '  git push origin main\n'
fi

log "6) Publicação na VPS (manual / no servidor)"
printf '  cd /opt/skalway-repo\n'
printf '  git pull origin main\n'
printf '  ./infra/scripts/deploy-web.sh\n'
printf '  ./infra/scripts/test-web.sh\n'

if [[ "$BUILD_ONLY" -eq 1 ]]; then
  log "Modo --build-only: concluído após build."
fi

log "Resumo"
printf '  build:   apps/phrx/app/build/web (versionável no Git)\n'
printf '  commit:  %s\n' "$([[ "$DO_COMMIT" -eq 1 ]] && echo sim || echo não)"
printf '  deploy:  na VPS via git pull + deploy-web.sh (sem rsync remoto)\n'
log "Concluído."
