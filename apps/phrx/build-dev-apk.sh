#!/bin/bash
# build-dev-apk.sh — APK Release rápido (sem flutter clean / pub get).
# API: sempre remota (nunca localhost / emulador).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/api-release-urls.sh
source "${SCRIPT_DIR}/scripts/api-release-urls.sh"
phrx_export_release_api_urls

# shellcheck source=scripts/build-apk-common.sh
source "${SCRIPT_DIR}/scripts/build-apk-common.sh"

echo "=============================="
echo "🚀 PhRx APK — DEV (API remota)"
echo "=============================="
echo "API:   $API_BASE_URL"
echo "Cloud: $API_CLOUD_URL"
echo "=============================="

TOTAL_START=$(date +%s)

phrx_ensure_app_dir
phrx_build_apk_split
phrx_rename_apks

TOTAL_END=$(date +%s)
phrx_print_summary "DEV" $((TOTAL_END - TOTAL_START))
