#!/usr/bin/env bash
# Pre-flight VPS PhRx — APENAS verificação (report-only).
#
# NÃO instala pacotes, NÃO altera firewall/Nginx/DNS,
# NÃO inicia containers, NÃO faz deploy.
#
# Uso (na VPS, na próxima etapa):
#   ./vps-preflight.sh
#   ./vps-preflight.sh --dry-run
#   SKALWAY_ROOT=/opt/skalway ENV_FILE=/opt/skalway/.env ./vps-preflight.sh
#
# Exit: 0 se checks críticos OK; 1 se algum crítico falhar.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

SKALWAY_ROOT="${SKALWAY_ROOT:-/opt/skalway}"
ENV_FILE="${ENV_FILE:-${SKALWAY_ROOT}/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${SKALWAY_ROOT}/docker-compose.prod.yml}"
WWW_ROOT="${WWW_ROOT:-/var/www/phrx}"
NGINX_AVAILABLE="${NGINX_AVAILABLE:-/etc/nginx/sites-available/skalway.conf}"
NGINX_ENABLED="${NGINX_ENABLED:-/etc/nginx/sites-enabled/skalway.conf}"
SSL_CERT="${SSL_CERT:-/etc/ssl/cloudflare/origin.crt}"
SSL_KEY="${SSL_KEY:-/etc/ssl/cloudflare/origin.key}"
DOMAIN_WEB="${DOMAIN_WEB:-phrx.skalway.com}"
DOMAIN_API="${DOMAIN_API:-api.phrx.skalway.com}"

# Variáveis obrigatórias no .env de produção
REQUIRED_ENV_VARS=(
  MYSQL_ROOT_PASSWORD
  MYSQL_USER
  MYSQL_PASSWORD
  DATABASE_URL
  TENANT_DB_HOST
  TENANT_DB_PORT
  TENANT_DB_USERNAME
  TENANT_DB_PASSWORD
  JWT_SECRET_CENTRAL
  JWT_SECRET_TENANT
  ENCRYPTION_KEY
)

ok=0
warn_n=0
fail=0

pass() { printf '  [OK]   %s\n' "$*"; ok=$((ok + 1)); }
soft() { printf '  [WARN] %s\n' "$*"; warn_n=$((warn_n + 1)); }
hard() { printf '  [FAIL] %s\n' "$*"; fail=$((fail + 1)); }

check_cmd() {
  local name="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] command -v %s\n' "$name"
    return 0
  fi
  if command -v "$name" >/dev/null 2>&1; then
    pass "$name: $(command -v "$name")"
  else
    hard "$name não encontrado no PATH"
  fi
}

check_path() {
  local label="$1" path="$2" mode="${3:-}" # file|dir|any
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] path %s (%s)\n' "$path" "$label"
    return 0
  fi
  if [[ "$mode" == "dir" ]]; then
    if [[ -d "$path" ]]; then pass "$label: $path"; else hard "$label em falta: $path"; fi
  elif [[ "$mode" == "file" ]]; then
    if [[ -f "$path" ]]; then pass "$label: $path"; else hard "$label em falta: $path"; fi
  else
    if [[ -e "$path" ]]; then pass "$label: $path"; else hard "$label em falta: $path"; fi
  fi
}

check_perms() {
  local path="$1" expect="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '  [dry-run] perms %s == %s\n' "$path" "$expect"
    return 0
  fi
  if [[ ! -e "$path" ]]; then
    soft "perms: $path inexistente (skip)"
    return 0
  fi
  local actual
  actual="$(stat -c '%a' "$path" 2>/dev/null || stat -f '%OLp' "$path" 2>/dev/null || echo '?')"
  if [[ "$actual" == "$expect" ]]; then
    pass "perms $path = $expect"
  else
    soft "perms $path = $actual (esperado $expect)"
  fi
}

section() { printf '\n## %s\n' "$1"; }

log "PhRx VPS pre-flight (report-only)"
log "SKALWAY_ROOT=$SKALWAY_ROOT"
log "ENV_FILE=$ENV_FILE"
[[ "$DRY_RUN" -eq 1 ]] && log "Modo dry-run: nenhum check real."

section "Sistema"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] uname / mem / disk\n'
else
  pass "OS: $(uname -sr)"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pass "Distro: ${PRETTY_NAME:-unknown}"
  fi
  # Memória (MiB)
  if command -v free >/dev/null 2>&1; then
    mem_mb="$(free -m | awk '/^Mem:/{print $2}')"
    if [[ "${mem_mb:-0}" -ge 2048 ]]; then
      pass "RAM: ${mem_mb} MiB (>= 2048 recomendado)"
    else
      soft "RAM: ${mem_mb} MiB (< 2048 — pode ser apertado para MySQL+API)"
    fi
  else
    soft "free não disponível"
  fi
  # Disco em /
  if command -v df >/dev/null 2>&1; then
    avail_kb="$(df -Pk / | awk 'NR==2{print $4}')"
    avail_gb=$((avail_kb / 1024 / 1024))
    if [[ "$avail_gb" -ge 20 ]]; then
      pass "Disco /: ~${avail_gb} GiB livres (>= 20 recomendado)"
    else
      soft "Disco /: ~${avail_gb} GiB livres (< 20 recomendado)"
    fi
  fi
fi

section "Ferramentas"
check_cmd docker
if [[ "$DRY_RUN" -eq 0 ]]; then
  if docker compose version >/dev/null 2>&1; then
    pass "docker compose: $(docker compose version --short 2>/dev/null || docker compose version | head -1)"
  else
    hard "docker compose plugin em falta"
  fi
else
  printf '  [dry-run] docker compose version\n'
fi
check_cmd nginx
if command -v ufw >/dev/null 2>&1 || [[ "$DRY_RUN" -eq 1 ]]; then
  check_cmd ufw
else
  soft "ufw não encontrado (firewall pode ser nftables/iptables)"
fi

section "Directórios oficiais"
check_path "deploy root" "$SKALWAY_ROOT" dir
check_path "backups mysql" "${SKALWAY_ROOT}/backups/mysql" dir
check_path "logs" "${SKALWAY_ROOT}/logs" dir
check_path "apps/phrx" "${SKALWAY_ROOT}/apps/phrx" dir
check_path "Flutter web" "$WWW_ROOT" dir
check_path "ssl dir" "/etc/ssl/cloudflare" dir

section "Ficheiros de configuração"
check_path "compose prod" "$COMPOSE_FILE" file
check_path ".env" "$ENV_FILE" file
check_path "nginx available" "$NGINX_AVAILABLE" file
check_path "nginx enabled" "$NGINX_ENABLED" file
check_path "origin.crt" "$SSL_CERT" file
check_path "origin.key" "$SSL_KEY" file
check_perms "$ENV_FILE" "600"
check_perms "$SSL_KEY" "600"
check_perms "$SSL_CERT" "644"

section "Variáveis obrigatórias (.env)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] grep required vars in %s\n' "$ENV_FILE"
else
  if [[ ! -f "$ENV_FILE" ]]; then
    hard ".env em falta — não é possível validar variáveis"
  else
    for var in "${REQUIRED_ENV_VARS[@]}"; do
      if grep -Eq "^[[:space:]]*${var}=" "$ENV_FILE"; then
        val="$(grep -E "^[[:space:]]*${var}=" "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d '[:space:]')"
        if [[ -z "$val" ]]; then
          hard "$var definido mas vazio"
        elif [[ "$val" == *"sua-secret"* || "$val" == "password" || "$val" == "root_password" || "$val" == "0000000000000000000000000000000000000000000000000000000000000000" ]]; then
          soft "$var parece placeholder de DEV — substituir antes do go-live"
        else
          pass "$var presente"
        fi
      else
        hard "$var em falta no .env"
      fi
    done
    # Recomendados
    if grep -Eq '^[[:space:]]*CORS_ALLOWED_ORIGINS=.*phrx\.skalway\.com' "$ENV_FILE"; then
      pass "CORS_ALLOWED_ORIGINS inclui phrx.skalway.com"
    else
      soft "CORS_ALLOWED_ORIGINS — confirmar https://phrx.skalway.com"
    fi
    if grep -Eq '^[[:space:]]*PUBLIC_TENANT_REGISTRATION=false' "$ENV_FILE"; then
      pass "PUBLIC_TENANT_REGISTRATION=false"
    else
      soft "PUBLIC_TENANT_REGISTRATION — em prod preferir false"
    fi
  fi
fi

section "Docker rede / exposição (compose file)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] parse compose ports\n'
elif [[ -f "$COMPOSE_FILE" ]]; then
  if grep -qE '127\.0\.0\.1:.*4001|127\.0\.0\.1:\$\{BACKEND_PORT' "$COMPOSE_FILE"; then
    pass "API publicada em loopback 127.0.0.1:4001 (padrão no ficheiro)"
  else
    soft "Confirmar API só em 127.0.0.1:4001 no compose"
  fi
  # Heurística: ports em mysql/redis
  if awk '
    /^[[:space:]]*phrx-db:|^[[:space:]]*redis:/ {svc=$1; gsub(":","",svc)}
    svc!="" && /^[[:space:]]*ports:/ {print svc; exit 0}
  ' "$COMPOSE_FILE" | grep -q .; then
    hard "Compose parece publicar ports em MySQL/Redis — NÃO aceitável em prod"
  else
    pass "MySQL/Redis sem bloco ports óbvio no compose"
  fi
else
  soft "Compose em falta — skip análise de ports"
fi

section "Portas no host (listen)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] ss listen 22/80/443/4001/3306/6379\n'
else
  listen_check() {
    local port="$1" expect="$2" # open|closed|loopback
    local lines=""
    if command -v ss >/dev/null 2>&1; then
      lines="$(ss -ltn 2>/dev/null | grep -E ":${port}\\b" || true)"
    elif command -v netstat >/dev/null 2>&1; then
      lines="$(netstat -ltn 2>/dev/null | grep -E ":${port}\\b" || true)"
    else
      soft "ss/netstat em falta — skip porta $port"
      return 0
    fi
    if [[ "$expect" == "closed" ]]; then
      if [[ -z "$lines" ]]; then
        pass ":$port não em listen (ok)"
      else
        hard ":$port em listen (não deveria ser público): $lines"
      fi
    elif [[ "$expect" == "loopback" ]]; then
      if echo "$lines" | grep -qE '127\.0\.0\.1:'"$port"'|\[::1\]:'"$port"; then
        if echo "$lines" | grep -qE '0\.0\.0\.0:'"$port"'|\*:'"$port"'|\[::\]:'"$port"; then
          hard ":$port também em 0.0.0.0 (deve ser só 127.0.0.1)"
        else
          pass ":$port só em loopback"
        fi
      elif [[ -z "$lines" ]]; then
        soft ":$port ainda não em listen (normal antes do deploy)"
      else
        soft ":$port listen: $lines"
      fi
    else
      if [[ -n "$lines" ]]; then
        pass ":$port em listen"
      else
        soft ":$port não em listen (normal se Nginx ainda não activo)"
      fi
    fi
  }
  listen_check 22 open
  listen_check 80 open
  listen_check 443 open
  listen_check 4001 loopback
  listen_check 3306 closed
  listen_check 6379 closed
  listen_check 3312 closed
  listen_check 6380 closed
fi

section "UFW (status apenas)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] ufw status\n'
elif command -v ufw >/dev/null 2>&1; then
  status="$(ufw status 2>/dev/null | head -1 || true)"
  if echo "$status" | grep -qi active; then
    pass "UFW: $status"
    ufw status numbered 2>/dev/null | head -20 || true
  else
    soft "UFW inactivo ou sem permissão de leitura — confirmar regras 22/80/443"
  fi
else
  soft "ufw ausente"
fi

section "Nginx / TLS (existência)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] nginx -t (read-only attempt)\n'
elif command -v nginx >/dev/null 2>&1; then
  if nginx -t 2>/tmp/phrx-nginx-t.txt; then
    pass "nginx -t OK"
  else
    soft "nginx -t falhou (ficheiro em falta ou cert em falta) — ver /tmp/phrx-nginx-t.txt"
    head -5 /tmp/phrx-nginx-t.txt 2>/dev/null || true
  fi
else
  soft "nginx bin ausente"
fi

section "DNS (read-only)"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '  [dry-run] getent/dig %s %s\n' "$DOMAIN_WEB" "$DOMAIN_API"
else
  for host in "$DOMAIN_WEB" "$DOMAIN_API"; do
    ips=""
    if command -v getent >/dev/null 2>&1; then
      ips="$(getent ahostsv4 "$host" 2>/dev/null | awk '{print $1}' | sort -u | tr '\n' ' ')"
    fi
    if [[ -z "$ips" ]] && command -v dig >/dev/null 2>&1; then
      ips="$(dig +short "$host" A 2>/dev/null | tr '\n' ' ')"
    fi
    if [[ -n "$ips" ]]; then
      pass "$host → $ips"
    else
      soft "$host sem resolução A (DNS ainda não configurado ou sem dig/getent)"
    fi
  done
fi

section "Resumo"
printf '  OK=%s  WARN=%s  FAIL=%s\n' "$ok" "$warn_n" "$fail"
if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run concluído."
  exit 0
fi
if [[ "$fail" -gt 0 ]]; then
  log "Pre-flight: FALHOU ($fail críticos). Corrigir antes do deploy."
  exit 1
fi
log "Pre-flight: sem falhas críticas ($warn_n avisos). Pronto para revisão humana antes do deploy."
exit 0
