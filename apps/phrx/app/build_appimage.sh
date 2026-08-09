#!/bin/bash

set -e

APP_NAME="SkalwayPhRx"
VERSION="1.0.0"
API_BASE_URL="${API_BASE_URL:-https://api-phrx.skalway.com}"
DISPLAY_NAME="Skalway PhRx"
APPDIR="${APP_NAME}.AppDir"
APPIMAGETOOL="appimagetool-x86_64.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
DESKTOP_ID="$APP_NAME"
ICON_ID="$APP_NAME"
ICON_PATH="assets/icons/icon.png"
ICON_FILE="${ICON_ID}.png"
ICON_SIZE_DIR="256x256"
BINARY_NAME="skalway_phrx"

echo "=============================="
echo "🚀 BUILD APPIMAGE SKALWAY PHRX"
echo "=============================="

echo "🧹 Limpando ambiente..."
rm -rf build "$APPDIR"
rm -f "${APP_NAME}"*.AppImage
rm -rf squashfs-root pkg

echo "🔍 Verificando suporte Linux no Flutter..."

if [ ! -d "linux" ]; then
  echo "⚙️ Linux não encontrado. Criando suporte automaticamente..."
  flutter create --platforms=linux .
else
  echo "✔️ Linux já configurado"
fi

echo "📦 Gerando build Linux..."
mkdir -p build/native_assets/linux
flutter build linux --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=API_CLOUD_URL=$API_BASE_URL \
  --dart-define=APP_NAME="$DISPLAY_NAME"

echo "📁 Criando AppDir..."
mkdir -p $APPDIR

echo "📂 Copiando build..."
cp -r build/linux/x64/release/bundle/* $APPDIR/

echo "▶️ Criando AppRun..."
ln -sf "$BINARY_NAME" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun" "$APPDIR/$BINARY_NAME"

echo "🎨 Adicionando ícone..."
if [ -f "$ICON_PATH" ]; then
  cp "$ICON_PATH" "$APPDIR/$ICON_FILE"
  ln -sf "$ICON_FILE" "$APPDIR/.DirIcon"
  mkdir -p "$APPDIR/usr/share/icons/hicolor/${ICON_SIZE_DIR}/apps"
  cp "$ICON_PATH" "$APPDIR/usr/share/icons/hicolor/${ICON_SIZE_DIR}/apps/${ICON_FILE}"
  mkdir -p "$APPDIR/usr/share/pixmaps"
  cp "$ICON_PATH" "$APPDIR/usr/share/pixmaps/${ICON_FILE}"
else
  echo "⚠️ Ícone não encontrado, ignorando..."
fi

echo "📄 Criando desktop entry..."
cat <<EOF > "$APPDIR/${DESKTOP_ID}.desktop"
[Desktop Entry]
Name=$DISPLAY_NAME
Exec=AppRun
Icon=$ICON_ID
Type=Application
Terminal=false
StartupWMClass=$BINARY_NAME
Categories=Utility;
EOF

echo "⬇️ Verificando appimagetool..."

if [ ! -f "$APPIMAGETOOL" ]; then
  echo "📥 Baixando appimagetool..."
  if command -v wget >/dev/null 2>&1; then
    wget -q -O "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$APPIMAGETOOL" "$APPIMAGETOOL_URL"
  else
    echo "❌ Precisas ter wget ou curl instalado para baixar o appimagetool."
    exit 1
  fi

  if [ ! -s "$APPIMAGETOOL" ]; then
    echo "❌ Download do appimagetool falhou (ficou vazio)."
    exit 1
  fi

  chmod +x "$APPIMAGETOOL"
else
  echo "✔️ appimagetool já existe"
fi

echo "🚀 Gerando AppImage..."

chmod +x "$APPIMAGETOOL"

ARCH=x86_64 ./$APPIMAGETOOL $APPDIR

OUTPUT="${APP_NAME}-${VERSION}-x86_64.AppImage"

GENERATED_APPIMAGE="$(ls -1 *.AppImage 2>/dev/null | grep -v "^${APPIMAGETOOL}$" | head -n 1)"
if [ -z "$GENERATED_APPIMAGE" ]; then
  echo "❌ Não encontrei o AppImage gerado (só existe o appimagetool)."
  exit 1
fi

mv "$GENERATED_APPIMAGE" "$OUTPUT"

chmod +x $OUTPUT

echo "=============================="
echo "✅ BUILD CONCLUÍDO COM SUCESSO"
echo "📦 Ficheiro: $OUTPUT"
echo "=============================="
