#!/usr/bin/env bash
# Wrapper — delega para scripts/install-android-sdk.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "${SCRIPT_DIR}/scripts/install-android-sdk.sh" "$@"
