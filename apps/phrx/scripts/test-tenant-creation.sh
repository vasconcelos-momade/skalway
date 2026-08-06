#!/usr/bin/env bash
# Teste fim-a-fim: criar tenant (CreateTenantUseCase já aplica seeders estruturais), validar login.
# Uso (raiz apps/phrx): bash scripts/test-tenant-creation.sh
# Variáveis: RUN_DEMO_SEED=1 para carregar dados de demonstração (~25 min).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="${INFRA_DIR:-$(cd "${SCRIPT_DIR}/../../../infra/docker/phrx" && pwd)}"
# shellcheck source=lib/docker.sh
source "${SCRIPT_DIR}/lib/docker.sh"
# shellcheck source=lib/mysql-tenants.sh
source "${SCRIPT_DIR}/lib/mysql-tenants.sh"

ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT"

BASE_URL="${BASE_URL:-http://localhost:4001/api/v1}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-phrx_backend}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password}"
MYSQL_USER="${MYSQL_USER:-admin}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-password}"
# Compat: SKIP_SEEDS=1 (legado) e RUN_DEMO_SEED=1 (novo)
RUN_DEMO_SEED="${RUN_DEMO_SEED:-0}"
if [[ "${SKIP_SEEDS:-1}" == "0" ]]; then
  RUN_DEMO_SEED=1
fi

TS=$(date +%s)
TENANT_SLUG="farmacia_${TS}"
DB_NAME="tenant_${TENANT_SLUG}"
OWNER_EMAIL="dono.${TS}@demo.com"
OWNER_PASSWORD="123456"

echo "==> 1. Health"
curl -sf "${BASE_URL}/health" | grep -q '"status":"ok"' && echo "    OK" || { echo "    FALHA"; exit 1; }

echo "==> 2. Criar tenant (POST /central/tenants) — estrutural via CreateTenantUseCase"
RESP=$(curl -s -i -X POST "${BASE_URL}/central/tenants" \
  -H "Content-Type: application/json" \
  -d "{
    \"tenantName\": \"${TENANT_SLUG}\",
    \"branches\": [{ \"name\": \"${TENANT_SLUG}\" }],
    \"adminName\": \"Admin Tenant\",
    \"adminEmail\": \"admin.${TS}@demo.com\",
    \"adminPassword\": \"${OWNER_PASSWORD}\",
    \"ownerUser\": {
      \"name\": \"${TENANT_SLUG}\",
      \"email\": \"${OWNER_EMAIL}\",
      \"password\": \"${OWNER_PASSWORD}\",
      \"role\": \"admin\"
    }
  }")

HTTP_CODE=$(echo "$RESP" | head -1 | awk '{print $2}')
BODY=$(echo "$RESP" | sed -n '/^{/,$p' | head -1)

if [[ "$HTTP_CODE" != "201" ]]; then
  echo "    Esperado 201, obteve ${HTTP_CODE}"
  echo "$RESP"
  exit 1
fi

echo "    201 Created — base: ${DB_NAME}"

if command -v jq >/dev/null 2>&1; then
  TENANT_ID=$(echo "$BODY" | jq -r '.data.id // .id')
  BRANCH_ID=$(echo "$BODY" | jq -r '.data.branch.id // .branch.id')
else
  TENANT_ID=$(echo "$BODY" | sed -n 's/.*"id":"\?\([^",}]*\)".*/\1/p' | head -1)
  BRANCH_ID=$(echo "$BODY" | sed -n 's/.*"branch":{[^}]*"id":"\?\([^",}]*\)".*/\1/p' | head -1)
fi

echo "==> 3. MySQL"
if tenant_database_exists "${DB_NAME}"; then
  echo "    Base ${DB_NAME} existe"
else
  echo "    Base em falta"
  exit 1
fi

echo "==> 4. Login central"
LOGIN=$(curl -s -X POST "${BASE_URL}/central/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${OWNER_EMAIL}\", \"password\": \"${OWNER_PASSWORD}\"}")

if command -v jq >/dev/null 2>&1; then
  TOKEN=$(echo "$LOGIN" | jq -r '.data.token // .token // empty')
else
  TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
fi

[[ -n "$TOKEN" ]] || { echo "    Sem token: $LOGIN"; exit 1; }
echo "    Token obtido"

echo "==> 5. GET /tenant/produtos"
HTTP_PROD=$(curl -s -o /tmp/produtos.json -w "%{http_code}" "${BASE_URL}/tenant/produtos" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "x-tenant-id: ${TENANT_ID}" \
  -H "x-branch-id: ${BRANCH_ID}")

[[ "$HTTP_PROD" == "200" ]] || { echo "    HTTP ${HTTP_PROD}"; exit 1; }
echo "    HTTP 200 ($(wc -c < /tmp/produtos.json) bytes)"

if [[ "$RUN_DEMO_SEED" == "1" ]]; then
  echo "==> 6. Seed demo (medicamentos, serviços, terminais, estoque) — pode demorar vários minutos"
  DB_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@phrx-db:3306/${DB_NAME}"
  docker exec -e DATABASE_URL_TENANT="${DB_URL}" "$BACKEND_CONTAINER" bun run seed:demo "${DB_NAME}"
  COUNT=$(docker exec "$MYSQL_CONTAINER" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N \
    -e "SELECT COUNT(*) FROM \`${DB_NAME}\`.produtos;" 2>/dev/null)
  echo "    Produtos na base: ${COUNT}"
else
  echo "==> 6. Seed demo omitido (RUN_DEMO_SEED=0). Estrutural já aplicado na criação."
fi

echo ""
echo "==> Sucesso"
echo "    Tenant:   ${TENANT_SLUG}"
echo "    Email:    ${OWNER_EMAIL}"
echo "    Password: ${OWNER_PASSWORD}"
echo "    DB:       ${DB_NAME}"
echo ""
echo "    export LOGIN_EMAIL='${OWNER_EMAIL}'"
echo "    export LOGIN_PASSWORD='${OWNER_PASSWORD}'"
echo "    bash scripts/test-login-and-products.sh"
