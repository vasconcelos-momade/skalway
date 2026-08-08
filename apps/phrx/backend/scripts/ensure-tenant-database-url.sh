#!/usr/bin/env sh
set -eu

url="${DATABASE_URL_TENANT:-}"
if [ -z "$url" ]; then
  echo "❌ DATABASE_URL_TENANT não está definido."
  exit 1
fi

db_name="$(printf '%s' "$url" | sed -n 's|.*/\([^/?]*\).*|\1|p')"

if [ -z "$db_name" ]; then
  echo "❌ Não foi possível extrair o nome da base de DATABASE_URL_TENANT."
  exit 1
fi

case "$db_name" in
  skalway_central|*_central)
    echo "❌ DATABASE_URL_TENANT aponta para a base central '${db_name}'."
    echo "   Use o schema tenant apenas em bases de filial"
    echo "   (ex.: phrx_tenant_1_branch_1)."
    exit 1
    ;;
  phrx_tenant_*|tenant_*)
    ;;
  skalway_tenant_example)
    echo "❌ DATABASE_URL_TENANT='${db_name}' é só um placeholder do .env.example."
    echo "   Defina a base real, por exemplo:"
    echo "   DATABASE_URL_TENANT=\"mysql://root:root_password@phrx-db:3306/phrx_tenant_1_branch_1\""
    exit 1
    ;;
  *)
    echo "⚠️  DATABASE_URL_TENANT usa '${db_name}' (esperado: phrx_tenant_{tenantId}_branch_{branchId})."
    ;;
esac
