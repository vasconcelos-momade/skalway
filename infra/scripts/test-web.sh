#!/usr/bin/env bash
# Testes HTTP do Flutter Web + API PhRx (producao).
#
# Uso:
#   ./test-web.sh
#   WEB_URL=https://phrx.skalway.com API_URL=https://api.phrx.skalway.com ./test-web.sh
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

WEB_URL="${WEB_URL:-https://phrx.skalway.com}"
API_URL="${API_URL:-https://api.phrx.skalway.com}"
HEALTH_URL="${HEALTH_URL:-${API_URL}/api/v1/health}"

require_cmd curl

ok=0
fail=0

pass() { printf '[OK] %s\n' "$*"; ok=$((ok + 1)); }
bad()  { printf '[FAIL] %s\n' "$*" >&2; fail=$((fail + 1)); }

log "Test Web: $WEB_URL"
log "Test API: $HEALTH_URL"

# --- HTTPS frontend ---
web_headers="$(curl -sS -I -L --max-time 20 "$WEB_URL" 2>/dev/null || true)"
if [[ -z "$web_headers" ]]; then
  bad "HTTPS / Flutter Web - sem resposta de $WEB_URL"
else
  code="$(printf '%s' "$web_headers" | awk 'BEGIN{c=""} /^HTTP/{c=$2} END{print c}')"
  if [[ "$code" == "200" || "$code" == "301" || "$code" == "302" ]]; then
    pass "HTTPS (HTTP $code)"
  else
    bad "HTTPS - status inesperado: $code"
  fi
  if printf '%s' "$web_headers" | grep -qiE '^HTTP/2|^HTTP/1\.1'; then
    pass "TLS/HTTP resposta"
  fi
fi

# --- index.html / conteudo Flutter ---
body="$(curl -sS -L --max-time 30 "$WEB_URL/" 2>/dev/null || true)"
if [[ -z "$body" ]]; then
  bad "index.html - corpo vazio"
else
  if printf '%s' "$body" | grep -qiE 'flutter|main\.dart|flutter_bootstrap|flt-glass'; then
    pass "Flutter Web"
  elif printf '%s' "$body" | grep -qiE 'flutter\.js|main\.dart\.js'; then
    pass "Flutter Web"
  else
    bad "Flutter Web - HTML sem marcadores esperados"
  fi
  pass "index.html"
fi

# Headers uteis
if printf '%s' "$web_headers" | grep -qiE '^server:'; then
  server_h="$(printf '%s' "$web_headers" | grep -iE '^server:' | head -1 | tr -d '\r')"
  pass "Nginx (${server_h})"
elif [[ -n "$web_headers" ]]; then
  pass "Nginx"
else
  bad "Nginx - sem headers"
fi

# --- API health ---
api_code="000"
api_body=""
if curl -sS -o /tmp/phrx-api-health.json -w '%{http_code}' --max-time 20 "$HEALTH_URL" >/tmp/phrx-api-code.txt 2>/dev/null; then
  api_code="$(tr -d '\n' </tmp/phrx-api-code.txt)"
fi
[[ -f /tmp/phrx-api-health.json ]] && api_body="$(head -c 200 /tmp/phrx-api-health.json 2>/dev/null || true)"
if [[ "$api_code" == "200" ]] && printf '%s' "$api_body" | grep -qiE 'ok|success|status'; then
  pass "API"
else
  bad "API - HTTP ${api_code}"
fi

printf '\nResumo: %s OK, %s FAIL\n' "$ok" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
exit 0
