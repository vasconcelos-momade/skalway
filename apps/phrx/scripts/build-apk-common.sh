#!/bin/bash
# build-apk-common.sh — lógica partilhada de build/rename/validação APK (PhRx)
# Não invocar diretamente; usar build-dev-apk.sh ou build-prod-apk.sh.

set -e

API_BASE_URL="${API_BASE_URL:-https://api.phrx.skalway.com}"
API_CLOUD_URL="${API_CLOUD_URL:-https://api.phrx.skalway.com}"
DISPLAY_NAME="${DISPLAY_NAME:-Skalway PhRx}"
VERSION="${VERSION:-1.0.0}"

# Diretório Flutter: apps/phrx/app (este ficheiro vive em apps/phrx/scripts/)
PHRX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${PHRX_ROOT}/app"
OUT_DIR="${APP_DIR}/build/app/outputs/flutter-apk"

phrx_ensure_app_dir() {
  if [ ! -d "$APP_DIR" ] || [ ! -f "$APP_DIR/pubspec.yaml" ]; then
    echo "❌ App Flutter não encontrado em: $APP_DIR"
    exit 1
  fi
  cd "$APP_DIR"
}

phrx_flutter_clean() {
  echo "🧹 Limpando projeto (flutter clean)..."
  flutter clean
}

phrx_flutter_pub_get() {
  echo "📦 Obtendo dependências Flutter..."
  flutter pub get
}

phrx_build_apk_split() {
  echo "🚀 Gerando APK Release (split por ABI)..."
  local start_ts end_ts
  start_ts=$(date +%s)

  flutter build apk --release --split-per-abi \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=API_CLOUD_URL="$API_CLOUD_URL" \
    --dart-define=APP_NAME="$DISPLAY_NAME"

  end_ts=$(date +%s)
  PHRX_BUILD_ELAPSED=$((end_ts - start_ts))
}

phrx_rename_apks() {
  echo "📱 Renomeando APKs..."

  if [ ! -d "$OUT_DIR" ]; then
    echo "❌ Pasta de saída não encontrada: $OUT_DIR"
    exit 1
  fi

  local renamed=0

  # Flutter default names
  if [ -f "$OUT_DIR/app-arm64-v8a-release.apk" ]; then
    mv -f "$OUT_DIR/app-arm64-v8a-release.apk" "$OUT_DIR/SkalwayPhRx-v${VERSION}-arm64.apk"
    renamed=$((renamed + 1))
  fi
  if [ -f "$OUT_DIR/app-armeabi-v7a-release.apk" ]; then
    mv -f "$OUT_DIR/app-armeabi-v7a-release.apk" "$OUT_DIR/SkalwayPhRx-v${VERSION}-armv7.apk"
    renamed=$((renamed + 1))
  fi
  if [ -f "$OUT_DIR/app-x86_64-release.apk" ]; then
    mv -f "$OUT_DIR/app-x86_64-release.apk" "$OUT_DIR/SkalwayPhRx-v${VERSION}-x86_64.apk"
    renamed=$((renamed + 1))
  fi

  # Fallback se o Gradle outputFileName já tiver renomeado sem ABI
  if [ "$renamed" -eq 0 ] && [ -f "$OUT_DIR/SkalwayPhRx-v${VERSION}-release.apk" ]; then
    echo "⚠️ Build sem split detectado; a copiar como arm64..."
    mv -f "$OUT_DIR/SkalwayPhRx-v${VERSION}-release.apk" \
      "$OUT_DIR/SkalwayPhRx-v${VERSION}-arm64.apk"
    renamed=1
  fi

  if [ "$renamed" -eq 0 ]; then
    echo "❌ Nenhum APK esperado encontrado em $OUT_DIR"
    ls -la "$OUT_DIR" || true
    exit 1
  fi
}

phrx_validate_apks() {
  echo "🔍 Validando APKs gerados..."
  local found=0
  local f

  for f in \
    "$OUT_DIR/SkalwayPhRx-v${VERSION}-arm64.apk" \
    "$OUT_DIR/SkalwayPhRx-v${VERSION}-armv7.apk" \
    "$OUT_DIR/SkalwayPhRx-v${VERSION}-x86_64.apk"
  do
    if [ -f "$f" ]; then
      found=$((found + 1))
      echo "  ✓ $(basename "$f") ($(du -h "$f" | awk '{print $1}'))"
    fi
  done

  if [ "$found" -eq 0 ]; then
    echo "❌ Validação falhou: nenhum APK SkalwayPhRx encontrado"
    exit 1
  fi

  # arm64 é o mínimo obrigatório em dispositivos modernos
  if [ ! -f "$OUT_DIR/SkalwayPhRx-v${VERSION}-arm64.apk" ]; then
    echo "❌ Validação falhou: falta SkalwayPhRx-v${VERSION}-arm64.apk"
    exit 1
  fi
}

phrx_print_summary() {
  local mode="${1:-build}"
  local total="${2:-0}"
  local total_fmt
  total_fmt=$(printf '%dm%02ds' $((total / 60)) $((total % 60)))

  echo ""
  echo "=============================="
  echo "✅ Build concluído (${mode})"
  echo "=============================="
  echo "⏱️  Tempo total: ${total_fmt} (${total}s)"
  if [ -n "${PHRX_BUILD_ELAPSED:-}" ]; then
    local build_fmt
    build_fmt=$(printf '%dm%02ds' $((PHRX_BUILD_ELAPSED / 60)) $((PHRX_BUILD_ELAPSED % 60)))
    echo "🛠️  Tempo compile: ${build_fmt} (${PHRX_BUILD_ELAPSED}s)"
  fi
  echo "📁 Saída: $OUT_DIR"
  echo ""
  echo "APKs:"
  ls -lh "$OUT_DIR"/SkalwayPhRx-v${VERSION}-*.apk 2>/dev/null || ls -lh "$OUT_DIR"/*.apk 2>/dev/null || true
  echo "=============================="
}
