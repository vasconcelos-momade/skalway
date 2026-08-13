#!/bin/bash

# build-apk.sh
# Skalway PhRx APK Release — API sempre remota (nunca localhost / emulador).
#
#   ./build-apk.sh
#   ENVIRONMENT=prod ./build-apk.sh


set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/api-release-urls.sh
source "${SCRIPT_DIR}/../scripts/api-release-urls.sh"


# =====================================
# Ambiente
# =====================================

ENVIRONMENT="${ENVIRONMENT:-prod}"

# Builds empacotados apontam só para a API remota.
phrx_export_release_api_urls



# =====================================
# App
# =====================================

APP_NAME="${APP_NAME:-Skalway PhRx}"
VERSION="${VERSION:-1.0.0}"


OUT_DIR="build/app/outputs/flutter-apk"

APK_SOURCE="$OUT_DIR/app-release.apk"

APK_NAME="SkalwayPhRx-v${VERSION}-${ENVIRONMENT}.apk"

APK_DEST="$OUT_DIR/$APK_NAME"



# =====================================
# Gradle Cache
# =====================================

export GRADLE_OPTS="
-Dorg.gradle.daemon=true
-Dorg.gradle.parallel=true
-Dorg.gradle.caching=true
"



# =====================================
# Informações
# =====================================

echo ""
echo "================================"
echo "🚀 BUILD APK UNIVERSAL — PhRx"
echo "================================"
echo "Ambiente: $ENVIRONMENT"
echo "Versão:   $VERSION"
echo "API:      $API_BASE_URL"
echo "Cloud:    $API_CLOUD_URL"
echo "App:      $APP_NAME"
echo "================================"
echo ""



START=$(date +%s)



# =====================================
# Validar Flutter
# =====================================

if ! command -v flutter >/dev/null 2>&1
then

    echo "❌ Flutter não encontrado"

    exit 1

fi



# =====================================
# Build
# =====================================

echo "🔨 Gerando APK Release..."

flutter build apk --release \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=API_CLOUD_URL="$API_CLOUD_URL" \
    --dart-define=APP_NAME="$APP_NAME"



echo ""

echo "🔎 Verificando APK..."



if [ ! -f "$APK_SOURCE" ]
then

    echo "❌ APK não encontrado:"
    echo "$APK_SOURCE"

    exit 1

fi



# =====================================
# Renomear APK
# =====================================

echo "📦 Renomeando APK..."


rm -f "$APK_DEST"


mv "$APK_SOURCE" "$APK_DEST"



# =====================================
# Resultado
# =====================================


END=$(date +%s)

TIME=$((END - START))


SIZE=$(du -h "$APK_DEST" | awk '{print $1}')


PATH_APK="$(cd "$(dirname "$APK_DEST")" && pwd)/$(basename "$APK_DEST")"



echo ""
echo "================================"
echo "✅ BUILD CONCLUÍDO"
echo "================================"
echo "⏱️ Tempo:    ${TIME}s"
echo "🌎 Ambiente: $ENVIRONMENT"
echo "📦 APK:      $APK_NAME"
echo "📏 Tamanho:  $SIZE"
echo "📍 Local:"
echo "$PATH_APK"
echo "================================"
echo ""
