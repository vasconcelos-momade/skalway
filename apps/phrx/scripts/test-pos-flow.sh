#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:4001/api/v1}"
ADMIN_EMAIL="${LOGIN_EMAIL:-dono.1784935275@demo.com}"
ADMIN_PASSWORD="${LOGIN_PASSWORD:-123456}"
TENANT_ID="${TENANT_ID:-1}"
BRANCH_ID="${BRANCH_ID:-1}"
PRODUCT_ID="${PRODUCT_ID:-1}"

echo "🔐 Fazendo login ($ADMIN_EMAIL)..."
LOGIN=$(curl -s -X POST "$BASE_URL/central/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$ADMIN_EMAIL\", \"password\": \"$ADMIN_PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
TENANT_ID=$(echo "$LOGIN" | jq -r '.data.tenants[0].id // empty' 2>/dev/null || echo "$TENANT_ID")
BRANCH_ID=$(echo "$LOGIN" | jq -r '.data.tenants[0].branches[0].id // empty' 2>/dev/null || echo "$BRANCH_ID")

if [ -z "$TOKEN" ]; then echo "❌ Erro login: $LOGIN"; exit 1; fi

AUTH_HDR=(-H "Authorization: Bearer $TOKEN" -H "x-tenant-id: $TENANT_ID" -H "x-branch-id: $BRANCH_ID")

echo "🔍 1. Buscando produto..."
curl -s -X GET "$BASE_URL/tenant/pos/produtos/search?q=a" \
  "${AUTH_HDR[@]}" | head -c 400
echo

echo -e "\n🔍 2. Buscando serviço..."
curl -s -X GET "$BASE_URL/tenant/pos/servicos/search?q=a" \
  "${AUTH_HDR[@]}" | head -c 400
echo

echo -e "\n⚖️ 3. Validando dispensação do produto ${PRODUCT_ID}..."
curl -s -X POST "$BASE_URL/tenant/pos/validar-dispensacao" \
  "${AUTH_HDR[@]}" \
  -H "Content-Type: application/json" \
  -d "{\"produtoId\": \"${PRODUCT_ID}\", \"quantidade\": 1}" | head -c 400
echo

echo -e "\n✅ test-pos-flow concluído"
