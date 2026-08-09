#!/bin/bash
# build-dev-apk.sh — APK Release rápido para desenvolvimento diário
# Sem flutter clean / flutter pub get (mantém cache e poupa dados).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Emulador Android: 10.0.2.2 → localhost do host.
# Dispositivo físico: API_BASE_URL=http://<IP-da-máquina>:4001 ./build-dev-apk.sh
export API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:4001}"
export API_CLOUD_URL="${API_CLOUD_URL:-https://api.phrx.skalway.com}"

# shellcheck source=scripts/build-apk-common.sh
source "${SCRIPT_DIR}/scripts/build-apk-common.sh"

echo "=============================="
echo "🚀 PhRx APK — DEV"
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
