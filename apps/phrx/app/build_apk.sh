#!/usr/bin/env bash
# Compat: README antigo referia build_apk.sh — delega a build-apk.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/build-apk.sh" "$@"
