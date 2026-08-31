#!/usr/bin/env bash
# Wrapper local — backup antes de tenant-clone-sanitized (dev).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"
exec "${REPO_ROOT}/infra/scripts/backup-before-tenant-clone.sh" "$@"
