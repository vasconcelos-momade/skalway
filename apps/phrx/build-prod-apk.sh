#!/bin/bash
# build-prod-apk.sh — APK Release limpo para produção / release oficial
# API: sempre remota (nunca localhost / emulador).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/api-release-urls.sh
source "${SCRIPT_DIR}/scripts/api-release-urls.sh"
phrx_export_release_api_urls

# shellcheck source=scripts/build-apk-common.sh
source "${SCRIPT_DIR}/scripts/build-apk-common.sh"

echo "=============================="
echo "🚀 PhRx APK — PROD"
echo "=============================="
echo "API:   $API_BASE_URL"
echo "Cloud: $API_CLOUD_URL"
echo "=============================="

TOTAL_START=$(date +%s)

phrx_ensure_app_dir
phrx_flutter_clean
phrx_flutter_pub_get
phrx_build_apk_split
phrx_rename_apks
phrx_validate_apks

TOTAL_END=$(date +%s)
phrx_print_summary "PROD" $((TOTAL_END - TOTAL_START))
