#!/usr/bin/env bash
# Verifica saúde local do stack PhRx (containers + API).
# NÃO contacta Cloudflare/DNS de produção por omissão.
#
# Uso:
#   ./healthcheck.sh
#   ./healthcheck.sh --dry-run
#   HEALTH_URL=http://127.0.0.1:4001/api/v1/health ./healthcheck.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

HEALTH_URL="${HEALTH_URL:-http://127.0.0.1:4001/api/v1/health}"
EXPECT_CONTAINERS=(
  phrx_backend
  phrx_backend_worker
  phrx_backend_print_worker
  phrx_mysql
  phrx_redis
)

ok=0
fail=0

check() {
  local name="$1"
  shift
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] check %s: %s\n' "$name" "$*"
    return 0
  fi
  if "$@"; then
    printf '✓ %s\n' "$name"
    ok=$((ok + 1))
  else
    printf '✗ %s\n' "$name" >&2
    fail=$((fail + 1))
  fi
}

log "Healthcheck PhRx"
log "API: $HEALTH_URL"

for c in "${EXPECT_CONTAINERS[@]}"; do
  check "container $c running" \
    bash -c "docker inspect -f '{{.State.Running}}' '$c' 2>/dev/null | grep -qx true"
done

check "mysql ping" \
  bash -c "docker exec phrx_mysql mysqladmin ping -h localhost --silent 2>/dev/null"

check "redis ping" \
  bash -c "docker exec phrx_redis redis-cli ping 2>/dev/null | grep -qx PONG"

check "API health" \
  bash -c "curl -fsS --max-time 5 '$HEALTH_URL' >/dev/null"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run: nenhum check real executado."
  exit 0
fi

log "Resultado: $ok ok, $fail falhas"
[[ "$fail" -eq 0 ]] || exit 1
