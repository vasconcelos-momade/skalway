#!/usr/bin/env sh
set -e

# Prisma generate fails on VirtualBox shared folders (vboxsf) when removing old files.
# docker-compose mounts named volumes over .../generated so output stays on a native FS.
#
# Named volumes can still end up with sparse/null-byte files (crash mid-write, disk full).
# Detect that and wipe before regenerating.

flock -w 120 /tmp/prisma-generate.lock sh -c '
set -e

is_valid_prisma_client() {
  client_dir="$1"
  index_js="$client_dir/index.js"
  package_json="$client_dir/package.json"

  [ -f "$index_js" ] || return 1
  [ -f "$package_json" ] || return 1

  # Reject empty or NUL-padded files left by interrupted writes.
  first_byte="$(od -An -N1 -tx1 "$index_js" 2>/dev/null | tr -d " \n")"
  [ "$first_byte" != "00" ] || return 1

  head -c 1 "$package_json" | grep -q "{" || return 1
  head -c 20 "$index_js" | grep -q "Object\|exports\|module" || return 1

  return 0
}

central_dir="src/infrastructure/prisma/central/generated/central"
tenant_dir="src/infrastructure/prisma/tenant/generated/tenant"

if ! is_valid_prisma_client "$central_dir"; then
  echo "[entrypoint] Prisma central client missing/corrupt — regenerating"
  rm -rf "$central_dir"
fi

if ! is_valid_prisma_client "$tenant_dir"; then
  echo "[entrypoint] Prisma tenant client missing/corrupt — regenerating"
  rm -rf "$tenant_dir"
fi

bunx prisma generate --schema=src/infrastructure/prisma/central/schema.prisma
bunx prisma generate --schema=src/infrastructure/prisma/tenant/schema.prisma

if ! is_valid_prisma_client "$central_dir" || ! is_valid_prisma_client "$tenant_dir"; then
  echo "[entrypoint] ERROR: Prisma generate finished but clients are still invalid" >&2
  exit 1
fi
'

exec "$@"
