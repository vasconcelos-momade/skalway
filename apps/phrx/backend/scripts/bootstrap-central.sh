#!/usr/bin/env bash
# Bootstrap idempotente da Central: migrations + seeders + SUPER_ADMIN.
#
# Uso recomendado (host, com stack Docker a correr):
#   ./bootstrap-central.sh
#   # ou: bash apps/phrx/backend/scripts/bootstrap-central.sh
#
# Dentro do contentor / com env carregado:
#   bun run bootstrap:central
#   docker exec phrx_backend bun run bootstrap:central

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-phrx_backend}"

# No host normalmente não há DATABASE_URL — redireciona para o contentor.
if [[ -z "${DATABASE_URL:-}" ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "❌ DATABASE_URL não está definido e o Docker não está disponível."
    echo "   Defina DATABASE_URL ou suba o stack PhRx."
    exit 1
  fi
  if ! docker ps --format '{{.Names}}' | grep -qx "${BACKEND_CONTAINER}"; then
    echo "❌ DATABASE_URL não está definido e o contentor '${BACKEND_CONTAINER}' não está a correr."
    echo "   Suba o stack:"
    echo "     cd infra/docker/phrx && docker compose -f docker-compose.dev.yml up -d"
    echo "   Depois volte a correr este script, ou:"
    echo "     docker exec ${BACKEND_CONTAINER} bun run bootstrap:central"
    exit 1
  fi
  echo "==> [bootstrap:central] A executar no contentor ${BACKEND_CONTAINER}..."
  exec docker exec "${BACKEND_CONTAINER}" bun run bootstrap:central
fi

cd "${BACKEND_DIR}"

CENTRAL_SCHEMA="src/infrastructure/prisma/central/schema.prisma"
CENTRAL_MIGRATIONS_DIR="src/infrastructure/prisma/central/migrations"

baseline_central_migrations() {
  echo "    migrate deploy falhou (ex.: P3005) — a marcar migrations existentes como aplicadas..."
  local dir migration_name
  for dir in "${CENTRAL_MIGRATIONS_DIR}"/*/; do
    [[ -d "$dir" ]] || continue
    migration_name="$(basename "$dir")"
    echo "    resolve --applied ${migration_name}"
    bunx prisma migrate resolve --applied "${migration_name}" --schema="${CENTRAL_SCHEMA}" || true
  done
}

echo "==> [bootstrap:central] 1/2 Migrations da Central"
bash "${SCRIPT_DIR}/ensure-central-database-url.sh"

if ! bun run prisma:migrate:central; then
  baseline_central_migrations
  bun run prisma:migrate:central
fi

echo "==> [bootstrap:central] 2/2 Seeders da Central (planos, permissões, SUPER_ADMIN)"
bun prisma/seed.ts

echo "==> [bootstrap:central] Concluído (idempotente)."
