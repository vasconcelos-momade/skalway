#!/usr/bin/env bash
# Auditoria local do stack PhRx (preparado para futuro uso em VPS).
# NÃO altera Cloudflare/DNS/firewall. Só reporta.
#
# Uso:
#   ./check-stack.sh
#   ./check-stack.sh --dry-run
#   ./check-stack.sh --full   # inclui DNS lookups (não destrutivo)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

FULL=0
for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --dry-run|-n) ;;
  esac
done

section() { printf '\n## %s\n' "$1"; }

report() {
  local label="$1"
  shift
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s → %s\n' "$label" "$*"
    return 0
  fi
  printf '%-28s ' "$label:"
  if out="$("$@" 2>/dev/null)"; then
    printf '%s\n' "${out:-ok}"
  else
    printf 'N/A ou falhou\n'
  fi
}

log "check-stack PhRx (modo report-only)"
[[ "$DRY_RUN" -eq 1 ]] && log "Dry-run: comandos não executados."

section "Sistema"
report "OS" uname -sr
report "Docker" docker --version
report "Compose" docker compose version

section "Containers PhRx"
if [[ "$DRY_RUN" -eq 0 ]]; then
  docker ps -a --filter "name=phrx_" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
else
  printf '[dry-run] docker ps -a --filter name=phrx_\n'
fi

section "Networks / volumes"
report "network phrx_net" docker network inspect phrx_net -f '{{.Name}} {{.Driver}}'
report "vol mysql" docker volume inspect phrx_mysql_data -f '{{.Name}}' || \
  docker volume inspect phrx_mysql -f '{{.Name}}'
report "vol redis" docker volume inspect phrx_redis_data -f '{{.Name}}'

section "Portas locais (esperadas)"
if [[ "$DRY_RUN" -eq 0 ]]; then
  for p in 4001 8280 3312 6380 8686; do
    if ss -ltn 2>/dev/null | grep -qE ":${p}\\b" || netstat -ltn 2>/dev/null | grep -qE ":${p}\\b"; then
      printf '  :%s LISTEN\n' "$p"
    else
      printf '  :%s (não em listen)\n' "$p"
    fi
  done
else
  printf '[dry-run] verificar listen 4001/8280/3312/6380/8686\n'
fi

section "Nginx host (futuro)"
report "nginx bin" bash -c 'command -v nginx || echo absent'
report "sites-enabled" bash -c 'ls /etc/nginx/sites-enabled 2>/dev/null | head -5 || echo N/A'
report "origin.crt" bash -c 'test -f /etc/ssl/cloudflare/origin.crt && echo present || echo absent'
report "origin.key" bash -c 'test -f /etc/ssl/cloudflare/origin.key && echo present || echo absent'

section "UFW"
report "ufw status" bash -c 'command -v ufw >/dev/null && sudo -n ufw status 2>/dev/null | head -3 || echo N/A'

section "MySQL / Redis (containers)"
report "mysql ping" bash -c 'docker exec phrx_mysql mysqladmin ping -h localhost --silent && echo ok'
report "redis ping" bash -c 'docker exec phrx_redis redis-cli ping'

section "Backend"
report "health" bash -c 'curl -fsS --max-time 3 http://127.0.0.1:4001/api/v1/health | head -c 200'

section "Flutter Web (host)"
report "/var/www/phrx" bash -c 'test -d /var/www/phrx && ls /var/www/phrx | head -5 || echo absent'

if [[ "$FULL" -eq 1 ]]; then
  section "DNS (read-only)"
  for host in phrx.skalway.com api-phrx.skalway.com; do
    report "$host" bash -c "getent hosts $host || dig +short $host A || true"
  done
fi

section "Ficheiros infra no repo"
report "compose prod" test -f "${PHRX_COMPOSE_DIR}/docker-compose.prod.yml" && echo ok
report "nginx ref" test -f "$(repo_root)/infra/nginx/skalway.conf" && echo ok
report ".env.example" test -f "${PHRX_COMPOSE_DIR}/.env.example" && echo ok

log "check-stack concluído (report-only)."
