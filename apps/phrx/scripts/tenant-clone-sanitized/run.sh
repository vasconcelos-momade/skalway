#!/usr/bin/env bash
# Wrapper para executar tenant:clone-sanitized a partir do host.
# Usa docker exec no MySQL (padrão dos scripts PhRx) e bun no backend.
#
# Uso (raiz apps/phrx):
#   bash scripts/tenant-clone-sanitized/run.sh --source=... --target=... --dry-run
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-phrx_backend}"
MYSQL_CONTAINER="${MYSQL_CONTAINER:-phrx_mysql}"

if ! docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER" 2>/dev/null | grep -q true; then
  echo "❌ Container MySQL '${MYSQL_CONTAINER}' não está a correr."
  exit 1
fi

if ! docker inspect -f '{{.State.Running}}' "$BACKEND_CONTAINER" 2>/dev/null | grep -q true; then
  echo "❌ Container backend '${BACKEND_CONTAINER}' não está a correr."
  exit 1
fi

export MYSQL_CONTAINER
export TENANT_CLONE_USE_DOCKER=1

exec docker exec \
  -e MYSQL_CONTAINER \
  -e TENANT_CLONE_USE_DOCKER \
  -e PROTECTED_DATABASES="${PROTECTED_DATABASES:-}" \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root_password}" \
  "$BACKEND_CONTAINER" \
  bun run tenant:clone-sanitized -- "$@"
