#!/usr/bin/env bash
# Testes HTTP do Flutter Web + API PhRx (producao).
#
# Sucesso somente se:
#   - frontend HTTP 200
#   - API /api/v1/health HTTP 200 + success=true
#   - sem erro TLS
#
# Uso:
#   ./test-web.sh
#   WEB_URL=https://phrx.skalway.com API_URL=https://api-phrx.skalway.com ./test-web.sh
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

WEB_URL="${WEB_URL:-https://phrx.skalway.com}"
API_URL="${API_URL:-https://api-phrx.skalway.com}"
HEALTH_URL="${HEALTH_URL:-${API_URL}/api/v1/health}"

require_cmd curl

ok=0
fail=0

pass() { printf '[OK] %s\n' "$*"; ok=$((ok + 1)); }
bad()  { printf '[FAIL] %s\n' "$*" >&2; fail=$((fail + 1)); }

TMPDIR_TEST="$(mktemp -d "${TMPDIR:-/tmp}/phrx-test-web.XXXXXX")"
cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

log "Test Web: $WEB_URL"
log "Test API: $HEALTH_URL"

# --- HTTPS frontend (exige 200; falha em TLS) ---
web_hdr="${TMPDIR_TEST}/web.hdr"
web_err="${TMPDIR_TEST}/web.err"
web_code="$(curl -sS -o /dev/null -D "$web_hdr" -w '%{http_code}' \
  --max-time 20 "$WEB_URL" 2>"$web_err" || true)"
if [[ -s "$web_err" ]] && grep -qiE 'SSL|TLS|certificate|handshake' "$web_err"; then
  bad "TLS frontend: $(tr '\n' ' ' <"$web_err")"
elif [[ "$web_code" == "200" ]]; then
  pass "Frontend HTTPS (HTTP 200)"
else
  bad "Frontend HTTPS - status inesperado: ${web_code:-sem resposta}"
  [[ -s "$web_err" ]] && bad "curl: $(tr '\n' ' ' <"$web_err")"
fi

# --- index.html / conteudo Flutter ---
body="$(curl -sS -L --max-time 30 "$WEB_URL/" 2>/dev/null || true)"
if [[ -z "$body" ]]; then
  bad "index.html - corpo vazio"
elif printf '%s' "$body" | grep -qiE 'flutter|main\.dart|flutter_bootstrap|flt-glass|flutter\.js|main\.dart\.js'; then
  pass "Flutter Web"
else
  bad "Flutter Web - HTML sem marcadores esperados"
fi

# --- main.dart.js ---
js_code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 \
  "${WEB_URL%/}/main.dart.js" 2>/dev/null || true)"
if [[ "$js_code" == "200" ]]; then
  pass "main.dart.js (HTTP 200)"
else
  bad "main.dart.js - HTTP ${js_code:-sem resposta}"
fi

# --- API health ---
api_body_file="${TMPDIR_TEST}/health.json"
api_err="${TMPDIR_TEST}/api.err"
api_code="$(curl -sS -o "$api_body_file" -w '%{http_code}' --max-time 20 \
  "$HEALTH_URL" 2>"$api_err" || true)"
api_body="$(head -c 500 "$api_body_file" 2>/dev/null || true)"

if [[ -s "$api_err" ]] && grep -qiE 'SSL|TLS|certificate|handshake' "$api_err"; then
  bad "TLS API: $(tr '\n' ' ' <"$api_err")"
elif [[ "$api_code" == "200" ]] && printf '%s' "$api_body" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
  pass "API health (HTTP 200, success=true)"
else
  bad "API health - HTTP ${api_code:-000}; body=${api_body:-(vazio)}"
  [[ -s "$api_err" ]] && bad "curl: $(tr '\n' ' ' <"$api_err")"
fi

printf '\nResumo: %s OK, %s FAIL\n' "$ok" "$fail"
[[ "$fail" -eq 0 ]] || exit 1
exit 0
