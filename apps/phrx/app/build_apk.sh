#!/bin/bash

set -e

API_BASE_URL="https://api.skalway.com"
DISPLAY_NAME="Skalway PhRx"
VERSION="1.0.0"

echo "🧹 Limpando projeto..."
flutter clean

echo "📦 Buscando dependências..."
flutter pub get

echo "🚀 Gerando APK (split por ABI)..."
flutter build apk --release --split-per-abi \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=API_CLOUD_URL=$API_BASE_URL \
  --dart-define=APP_NAME="$DISPLAY_NAME"

echo "📁 Acessando pasta de saída..."
cd build/app/outputs/flutter-apk/

echo "📦 Renomeando APK ARM64..."
mv app-arm64-v8a-release.apk "SkalwayPhRx-v${VERSION}-arm64.apk"

echo "📦 Renomeando APK ARMV7..."
mv app-armeabi-v7a-release.apk "SkalwayPhRx-v${VERSION}-armv7.apk"

echo "✅ BUILD CONCLUÍDO COM SUCESSO!"
echo "📍 Arquivos prontos na pasta flutter-apk"
