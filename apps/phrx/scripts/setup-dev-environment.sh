#!/usr/bin/env bash
# Ambiente de desenvolvimento: bootstrap Central → criar Tenant via API → validar login.
# A criação do Tenant usa CreateTenantUseCase (migrations + seeders estruturais + branch HQ).
# Dados de demonstração NÃO são carregados automaticamente (usar: bun run seed:demo <db>).
# Uso (raiz apps/phrx): bash scripts/setup-dev-environment.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="${INFRA_DIR:-$(cd "${SCRIPT_DIR}/../../../infra/docker/phrx" && pwd)}"
# shellcheck source=lib/docker.sh
source "${SCRIPT_DIR}/lib/docker.sh"
# shellcheck source=lib/mysql-tenants.sh
source "${SCRIPT_DIR}/lib/mysql-tenants.sh"

ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${INFRA_DIR}"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.dev.yml}"
BASE_URL="${BASE_URL:-http://localhost:4001/api/v1}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-phrx_backend}"

wait_for_health() {
  local attempts=0
  local max=60
  echo "==> Aguardando API (${BASE_URL}/health) ..."
  until curl -sf "${BASE_URL}/health" | grep -q '"status":"ok"'; do
    attempts=$((attempts + 1))
    if [[ "$attempts" -ge "$max" ]]; then
      echo "    Timeout à espera do backend"
      docker compose -f "$COMPOSE_FILE" logs --tail=50 phrx-backend
      exit 1
    fi
    sleep 3
  done
  echo "    API OK"
}

echo "==> 1. Subir containers (docker compose up -d --build)"
docker compose -f "$COMPOSE_FILE" up -d --build

wait_for_health

echo "==> 2. Bootstrap Central (migrations + seeders + SUPER_ADMIN)"
CENTRAL_SCHEMA="src/infrastructure/prisma/central/schema.prisma"
CENTRAL_MIGRATIONS="${ROOT}/backend/src/infrastructure/prisma/central/migrations"
if ! docker exec "$BACKEND_CONTAINER" bun run bootstrap:central; then
  echo "    bootstrap:central falhou (ex.: P3005) — baseline das migrations existentes..."
  for dir in "${CENTRAL_MIGRATIONS}"/*/; do
    [[ -d "$dir" ]] || continue
    migration_name="$(basename "$dir")"
    echo "    resolve --applied ${migration_name}"
    docker exec "$BACKEND_CONTAINER" \
      bunx prisma migrate resolve --applied "${migration_name}" --schema="${CENTRAL_SCHEMA}" || true
  done
  docker exec "$BACKEND_CONTAINER" bun run bootstrap:central
fi

TS=$(date +%s)
TENANT_SLUG="farmacia_${TS}"
DB_NAME="tenant_${TENANT_SLUG}"
OWNER_EMAIL="dono.${TS}@demo.com"
OWNER_PASSWORD="123456"
SUPER_ADMIN_EMAIL="${SUPER_ADMIN_EMAIL:-admin@skalway.com}"
SUPER_ADMIN_PASSWORD="${SUPER_ADMIN_PASSWORD:-admin123}"

echo "==> 3. Validar login SUPER_ADMIN"
SUPER_LOGIN=$(curl -s -X POST "${BASE_URL}/central/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"${SUPER_ADMIN_EMAIL}\", \"password\": \"${SUPER_ADMIN_PASSWORD}\"}")

if command -v jq >/dev/null 2>&1; then
  SUPER_TOKEN=$(echo "$SUPER_LOGIN" | jq -r '.data.token // .token // empty')
else
  SUPER_TOKEN=$(echo "$SUPER_LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
fi

[[ -n "$SUPER_TOKEN" ]] || { echo "    Login SUPER_ADMIN falhou: $SUPER_LOGIN"; exit 1; }
echo "    SUPER_ADMIN OK (${SUPER_ADMIN_EMAIL})"

echo "==> 4. Criar Tenant via API (CreateTenantUseCase) — base: ${DB_NAME}"
RESP=$(curl -s -i -X POST "${BASE_URL}/central/tenants" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SUPER_TOKEN}" \
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
echo "    201 Created (BD + migrations + seeders estruturais + branch HQ)"

if ! tenant_database_exists "${DB_NAME}"; then
  echo "    Base ${DB_NAME} não encontrada no MySQL"
  exit 1
fi
echo "    Base ${DB_NAME} confirmada no MySQL"

echo "==> 5. Validar login do owner do tenant"
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
  echo "    GET /tenant/produtos OK (catálogo vazio até seed:demo)"
fi

echo ""
echo "==> Ambiente pronto"
echo "    API:      http://localhost:4001/api/v1"
echo "    Tenant:   ${TENANT_SLUG}"
echo "    Email:    ${OWNER_EMAIL}"
echo "    Password: ${OWNER_PASSWORD}"
echo "    DB:       ${DB_NAME}"
echo "    SUPER:    ${SUPER_ADMIN_EMAIL} / ${SUPER_ADMIN_PASSWORD}"
echo ""
echo "    Dados de demo (opcional):"
echo "    docker exec -e DATABASE_URL_TENANT='mysql://admin:password@phrx-db:3306/${DB_NAME}' \\"
echo "      ${BACKEND_CONTAINER} bun run seed:demo ${DB_NAME}"
echo ""
echo "    export LOGIN_EMAIL='${OWNER_EMAIL}'"
echo "    export LOGIN_PASSWORD='${OWNER_PASSWORD}'"
echo "    bash scripts/test-login-and-products.sh"
