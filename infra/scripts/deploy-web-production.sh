#!/usr/bin/env bash
# Orquestrador: build Flutter Web → (opcional commit/push) → deploy VPS → testes.
#
# Uso:
#   VPS_HOST=… VPS_USER=… ./deploy-web-production.sh
#   VPS_HOST=… VPS_USER=… ./deploy-web-production.sh --commit
#   ./deploy-web-production.sh --dry-run
#   ./deploy-web-production.sh --build-only
#
# --commit: se houver alterações locais relevantes, commit + push origin main
#           (nunca force-push; nunca reset --hard; nunca .env).
# Sem --commit: só build + deploy + testes (requer VPS_HOST/VPS_USER para deploy).
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
DO_COMMIT=0
BUILD_ONLY=0
SKIP_DEPLOY=0
SKIP_TEST=0

for arg in "$@"; do
  case "$arg" in
    --commit) DO_COMMIT=1 ;;
    --build-only) BUILD_ONLY=1; SKIP_DEPLOY=1; SKIP_TEST=1 ;;
    --skip-deploy) SKIP_DEPLOY=1 ;;
    --skip-test) SKIP_TEST=1 ;;
    --dry-run|-n) ;;
    -h|--help)
      printf 'Uso: VPS_HOST=… VPS_USER=… %s [--commit] [--dry-run] [--build-only]\n' "$0"
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
[[ -n "$remote" ]] || warn "Remote origin não configurado"
log "Origin: ${remote:-(nenhum)}"

log "2) Build Flutter Web"
if [[ "$DRY_RUN" -eq 1 ]]; then
  "${SCRIPT_DIR}/build-web.sh" --dry-run
else
  "${SCRIPT_DIR}/build-web.sh"
fi

log "3) Validar build"
WEB_OUT="${ROOT}/apps/phrx/app/build/web"
if [[ "$DRY_RUN" -eq 0 ]]; then
  [[ -f "${WEB_OUT}/index.html" ]] || die "Build inválido após build-web.sh"
  log "build/web OK"
fi

log "4) Git status"
git status -sb || true

if [[ "$DO_COMMIT" -eq 1 ]]; then
  log "5) Commit/push (--commit)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] git add/commit/push (se houver alterações)\n'
  else
    # Não incluir secrets / build
    if git status --porcelain | grep -qE '(^.. \.env|/\.env$|\.pem$|\.key$|id_rsa|credentials)'; then
      die "Alterações sensíveis detectadas (.env/keys) — remova do staging antes de --commit"
    fi

    # Só ficheiros de código/config (excluir build/ que já está no gitignore)
    dirty="$(git status --porcelain | grep -vE '^\?\? ' || true)"
    untracked_ok="$(git status --porcelain | grep -E '^\?\?' | grep -vE '\.env|\.pem|\.key|build/' || true)"

    if [[ -z "$dirty" && -z "$untracked_ok" ]]; then
      log "Sem alterações para commit — a continuar"
    else
      git add -A
      # Garantir que nada sensível entrou
      if git diff --cached --name-only | grep -qiE '(^|/)\.env(\.|$)|\.pem$|\.key$|id_rsa|credentials|cloudflare/origin'; then
        git reset HEAD -- .env .env.* '*.pem' '*.key' 2>/dev/null || true
        die "Staging continha secrets — abortado. Reveja git status."
      fi
      if git diff --cached --quiet; then
        log "Nada staged após filtros — skip commit"
      else
        git commit -m "$(cat <<'EOF'
chore(phrx): prepare flutter web production release

EOF
)"
        [[ "$branch" == "main" ]] || warn "Branch actual é '$branch' (não main)"
        git push origin HEAD
        log "Push OK"
      fi
    fi
  fi
else
  log "5) Skip commit (passe --commit para commit+push explícito)"
fi

if [[ "$SKIP_DEPLOY" -eq 1 ]]; then
  log "6) Skip deploy (--build-only / --skip-deploy)"
else
  log "6) Deploy Web → VPS"
  [[ -n "${VPS_HOST:-}" ]] || die "VPS_HOST obrigatório para deploy"
  [[ -n "${VPS_USER:-}" ]] || die "VPS_USER obrigatório para deploy"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    VPS_HOST="$VPS_HOST" VPS_USER="$VPS_USER" "${SCRIPT_DIR}/deploy-web.sh" --dry-run
  else
    VPS_HOST="$VPS_HOST" VPS_USER="$VPS_USER" "${SCRIPT_DIR}/deploy-web.sh"
  fi
fi

if [[ "$SKIP_TEST" -eq 1 ]]; then
  log "7) Skip testes"
else
  log "7) Testes"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] ./test-web.sh\n'
  else
    "${SCRIPT_DIR}/test-web.sh"
  fi
fi

log "Resumo"
printf '  build:  apps/phrx/app/build/web\n'
printf '  commit: %s\n' "$([[ "$DO_COMMIT" -eq 1 ]] && echo sim || echo não)"
printf '  deploy: %s\n' "$([[ "$SKIP_DEPLOY" -eq 1 ]] && echo skip || echo "${VPS_HOST:-?}→/var/www/phrx")"
printf '  testes: %s\n' "$([[ "$SKIP_TEST" -eq 1 ]] && echo skip || echo executados)"
log "Concluído."
