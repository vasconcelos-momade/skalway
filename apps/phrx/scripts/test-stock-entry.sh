#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:4001/api/v1}"
ADMIN_EMAIL="${LOGIN_EMAIL:-dono.1784935275@demo.com}"
ADMIN_PASSWORD="${LOGIN_PASSWORD:-123456}"
PRODUTO_ID="${PRODUCT_ID:-1}"
FORNECEDOR_ID="${FORNECEDOR_ID:-1}"

echo "🔐 Fazendo login ($ADMIN_EMAIL)..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/central/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$ADMIN_EMAIL\", \"password\": \"$ADMIN_PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
TENANT_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.tenants[0].id // "1"')
BRANCH_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.data.tenants[0].branches[0].id // "1"')

if [ -z "$TOKEN" ]; then
  echo "❌ Erro ao obter token: $LOGIN_RESPONSE"
  exit 1
fi
echo "✅ Login realizado! tenant=$TENANT_ID branch=$BRANCH_ID"

AUTH_HDR=(-H "Authorization: Bearer $TOKEN" -H "x-tenant-id: $TENANT_ID" -H "x-branch-id: $BRANCH_ID")

echo "📦 Listando produtos..."
set +o pipefail
curl -s -X GET "$BASE_URL/tenant/produtos" "${AUTH_HDR[@]}" | head -c 300
set -o pipefail
echo -e "\n..."

echo "📥 Realizando entrada de stock (produto $PRODUTO_ID)..."
LOTE="LOTE-TESTE-$(date +%s)"
VALIDADE="2027-12-31"
DOC_NUM="FT-TESTE-$(date +%s)"

STOCK_ENTRY_DATA=$(cat <<EOF
{
  "fornecedorId": "${FORNECEDOR_ID}",
  "numeroDocumento": "${DOC_NUM}",
  "items": [
    {
      "produtoId": "${PRODUTO_ID}",
      "numeroLote": "${LOTE}",
      "dataValidade": "${VALIDADE}",
      "quantidade": 50,
      "precoCompra": 100,
      "precoVenda": 150
    }
  ]
}
EOF
)

STOCK_RESPONSE=$(curl -s -X POST "$BASE_URL/tenant/stock/receive" \
  "${AUTH_HDR[@]}" \
  -H "Content-Type: application/json" \
  -d "$STOCK_ENTRY_DATA")

echo "📄 Resposta da entrada de stock:"
echo "$STOCK_RESPONSE" | head -c 500
echo

echo "🔍 Verificando produto $PRODUTO_ID..."
set +o pipefail
curl -s -X GET "$BASE_URL/tenant/produtos/$PRODUTO_ID" "${AUTH_HDR[@]}" | head -c 400
set -o pipefail
echo
echo "✅ test-stock-entry concluído"
