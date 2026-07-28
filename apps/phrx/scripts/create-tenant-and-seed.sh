#!/usr/bin/env bash
# Cria tenant + seed central + seed completo do tenant + testa login.
# Pré-requisito: containers já a correr (docker compose -f docker-compose.dev.yml up -d).
# Uso (raiz apps/phrx): bash scripts/create-tenant-and-seed.sh

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

wait_for_health() {
  local attempts=0
  local max=40
  echo "==> Aguardando API (${BASE_URL}/health) ..."
  until curl -sf "${BASE_URL}/health" | grep -q '"status":"ok"'; do
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge "$max" ]]; then
      echo "    Timeout à espera do backend"
      exit 1
    fi
    sleep 3
  done
  echo "    API OK"
}

wait_for_health

echo "==> 1. Seed central (planos + superadmin)"
docker exec "$BACKEND_CONTAINER" bun prisma/seed.ts

TS=$(date +%s)
TENANT_SLUG="farmacia_${TS}"
DB_NAME="tenant_${TENANT_SLUG}"
OWNER_EMAIL="dono.${TS}@demo.com"
OWNER_PASSWORD="123456"

echo "==> 2. Criar tenant (POST /central/tenants) — base: ${DB_NAME}"
RESP=$(curl -s -i -X POST "${BASE_URL}/central/tenants" \
  -H "Content-Type: application/json" \
  -d "{
    \"nomeEmpresa\": \"Farmacia Demo ${TS}\",
    \"nomeTenant\": \"${TENANT_SLUG}\",
    \"adminName\": \"Admin Tenant\",
    \"adminEmail\": \"admin.${TS}@demo.com\",
    \"adminPassword\": \"${OWNER_PASSWORD}\",
    \"ownerUser\": {
      \"name\": \"Dono Central\",
      \"email\": \"${OWNER_EMAIL}\",
      \"password\": \"${OWNER_PASSWORD}\",
      \"role\": \"admin\"
    }
  }")

HTTP_CODE=$(echo "$RESP" | head -1 | awk '{print $2}')
if [[ "$HTTP_CODE" != "201" ]]; then
  echo "    Esperado 201, obteve ${HTTP_CODE}"
  echo "$RESP"
  exit 1
fi
echo "    201 Created"

if ! tenant_database_exists "${DB_NAME}"; then
  echo "    Base ${DB_NAME} não encontrada no MySQL"
  exit 1
fi
echo "    Base ${DB_NAME} confirmada no MySQL"

echo "==> 3. Migrations tenant (baseline + deploy)"
bash "${ROOT}/backend/scripts/migrate-tenant-deploy.sh" "${DB_NAME}" --baseline-all

DB_URL="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@phrx-db:3306/${DB_NAME}"

echo "==> 4. Seed completo do tenant (pode demorar 20–30 min com medicamentos ANARME)"
docker exec -e DATABASE_URL_TENANT="${DB_URL}" "$BACKEND_CONTAINER" \
  bun prisma/seed-all-tenant.ts "${DB_NAME}"

echo "==> 5. Testar login"
LOGIN=$(curl -s -X POST "${BASE_URL}/central/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${OWNER_EMAIL}\", \"password\": \"${OWNER_PASSWORD}\"}")

if command -v jq >/dev/null 2>&1; then
  TOKEN=$(echo "$LOGIN" | jq -r '.data.token // .token // empty')
  TENANT_ID=$(echo "$LOGIN" | jq -r '.data.tenants[0].id // .tenants[0].id // empty')
  BRANCH_ID=$(echo "$LOGIN" | jq -r '.data.tenants[0].branches[0].id // .tenants[0].branches[0].id // empty')
else
  TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  TENANT_ID=""
  BRANCH_ID=""
fi

[[ -n "$TOKEN" ]] || { echo "    Login falhou: $LOGIN"; exit 1; }
echo "    Login OK (token obtido)"

if [[ -n "$TENANT_ID" && -n "$BRANCH_ID" ]]; then
  HTTP_PROD=$(curl -s -o /tmp/produtos.json -w "%{http_code}" "${BASE_URL}/tenant/produtos" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "x-tenant-id: ${TENANT_ID}" \
    -H "x-branch-id: ${BRANCH_ID}")
  [[ "$HTTP_PROD" == "200" ]] || { echo "    GET /tenant/produtos HTTP ${HTTP_PROD}"; exit 1; }
  echo "    GET /tenant/produtos OK"
fi

echo ""
echo "==> Sucesso"
echo "    API:      ${BASE_URL}"
echo "    Tenant:   ${TENANT_SLUG}"
echo "    Email:    ${OWNER_EMAIL}"
echo "    Password: ${OWNER_PASSWORD}"
echo "    DB:       ${DB_NAME}"
echo ""
echo "    export LOGIN_EMAIL='${OWNER_EMAIL}'"
echo "    export LOGIN_PASSWORD='${OWNER_PASSWORD}'"
echo "    bash scripts/test-login-and-products.sh"
