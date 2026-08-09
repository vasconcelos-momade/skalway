#!/bin/bash

# build_deb.sh — Skalway PhRx Linux DEB Release
#
# Build otimizado:
# - Suporta ambiente DEV e PROD
# - Mantém cache Flutter
# - Gera pacote Debian (.deb)
# - Configura API via dart-define

set -euo pipefail


# ==============================
# Configurações do App
# ==============================

APP_NAME="skalway-phrx"
DISPLAY_NAME="Skalway PhRx"
VERSION="${VERSION:-1.0.0}"

MAINTAINER="Skalway <suporte@skalway.com>"
DESCRIPTION="Sistema de gestão Skalway PhRx — ERP farmacêutico"

ENVIRONMENT="${ENVIRONMENT:-dev}"


# ==============================
# Configuração API DEV / PROD
# ==============================

case "$ENVIRONMENT" in

  dev)

    # Teste local do .deb: backend no mesmo host (docker compose → :4001).
    # LAN / outro host: API_BASE_URL=http://<IP>:4001 ./build_deb.sh
    API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:4001}"
    API_CLOUD_URL="${API_CLOUD_URL:-https://api-phrx.skalway.com}"

    ;;

  prod)

    API_BASE_URL="${API_BASE_URL:-https://api-phrx.skalway.com}"
    API_CLOUD_URL="${API_CLOUD_URL:-https://api-phrx.skalway.com}"

    ;;

  *)

    echo "❌ Ambiente inválido: $ENVIRONMENT"
    echo ""
    echo "Uso:"
    echo ""
    echo "DEV:"
    echo "./build_deb.sh"
    echo ""
    echo "PROD:"
    echo "ENVIRONMENT=prod ./build_deb.sh"

    exit 1

    ;;

esac


# ==============================
# Configurações DEB
# ==============================

DEB_DIR="pkg_deb"

ICON_PATH="assets/icons/icon.png"

ICON_NAME="skalway_phrx"

WM_CLASS="skalway_phrx"

BINARY_NAME="skalway_phrx"



echo "=============================="
echo "🚀 BUILD DEB SKALWAY PHRX"
echo "=============================="

echo "Ambiente: $ENVIRONMENT"
echo "Versão:   $VERSION"
echo "API:      $API_BASE_URL"
echo "Cloud:    $API_CLOUD_URL"
echo ""



# ==============================
# Limpeza temporária
# ==============================

echo "🧹 Limpando ambiente..."

rm -rf build "$DEB_DIR"
rm -f "${APP_NAME}"*.deb



# ==============================
# Verificar Linux Flutter
# ==============================

if [ ! -d "linux" ]; then

    echo "⚙️ Linux não encontrado. Criando suporte..."

    flutter create --platforms=linux .

fi



# ==============================
# Build Linux
# ==============================

echo "📦 Gerando build Linux..."


# CMake install(DIRECTORY) exige que o path exista (mesmo vazio).
mkdir -p build/native_assets/linux

flutter build linux --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=API_CLOUD_URL="$API_CLOUD_URL" \
  --dart-define=APP_NAME="$DISPLAY_NAME"



# ==============================
# Criar estrutura DEB
# ==============================

echo "📁 Criando estrutura do pacote..."


mkdir -p "$DEB_DIR/usr/bin"

mkdir -p "$DEB_DIR/usr/lib/$APP_NAME"

mkdir -p "$DEB_DIR/usr/share/applications"

mkdir -p "$DEB_DIR/usr/share/pixmaps"

mkdir -p "$DEB_DIR/DEBIAN"



for size in 16 32 48 64 128 256; do

    mkdir -p \
    "$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps"

done



# ==============================
# Copiar aplicação
# ==============================

echo "📂 Copiando ficheiros..."


cp -r \
build/linux/x64/release/bundle/* \
"$DEB_DIR/usr/lib/$APP_NAME/"



# ==============================
# Criar comando global
# ==============================

ln -sf \
"/usr/lib/$APP_NAME/$BINARY_NAME" \
"$DEB_DIR/usr/bin/$APP_NAME"



# ==============================
# Ícones
# ==============================

if [ -f "$ICON_PATH" ]; then


echo "🎨 Instalando ícones..."


for size in 16 32 48 64 128 256; do


cp "$ICON_PATH" \
"$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/skalway-phrx.png"


cp "$ICON_PATH" \
"$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/skalway_phrx.png"


done


cp "$ICON_PATH" \
"$DEB_DIR/usr/share/pixmaps/skalway-phrx.png"


cp "$ICON_PATH" \
"$DEB_DIR/usr/share/pixmaps/skalway_phrx.png"



else

echo "⚠️ Ícone não encontrado:"
echo "$ICON_PATH"


fi



# ==============================
# Desktop Entry
# ==============================

echo "📄 Criando desktop entry..."


cat > "$DEB_DIR/usr/share/applications/skalway_phrx.desktop" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$ICON_NAME
Type=Application
Terminal=false
StartupWMClass=$WM_CLASS
Categories=Utility;
Keywords=PhRx;Pharmacy;Farmacia;Skalway;
EOF



# ==============================
# Scripts DEB
# ==============================


echo "📝 Criando scripts Debian..."


cat > "$DEB_DIR/DEBIAN/postinst" <<EOF
#!/bin/bash
set -e
update-desktop-database -q || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
EOF



cat > "$DEB_DIR/DEBIAN/postrm" <<EOF
#!/bin/bash
set -e
update-desktop-database -q || true
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
EOF



chmod 755 \
"$DEB_DIR/DEBIAN/postinst" \
"$DEB_DIR/DEBIAN/postrm"



# ==============================
# Control DEB
# ==============================


echo "📝 Criando control..."


cat > "$DEB_DIR/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Architecture: amd64
Maintainer: $MAINTAINER
Description: $DESCRIPTION
Section: utils
Priority: optional
Depends: libc6, libgtk-3-0, libblkid1, liblzma5
EOF



# ==============================
# Gerar DEB
# ==============================


echo "🚀 Gerando pacote DEB..."


OUTPUT="${APP_NAME}_${VERSION}_${ENVIRONMENT}_amd64.deb"


dpkg-deb --build \
"$DEB_DIR" \
"$OUTPUT"



# ==============================
# Limpeza
# ==============================


rm -rf "$DEB_DIR"



echo ""
echo "=============================="
echo "✅ DEB CONCLUÍDO"
echo "=============================="

echo "📦 Arquivo:"
echo "$OUTPUT"

echo ""

echo "Ambiente:"
echo "$ENVIRONMENT"

echo ""

echo "API:"
echo "$API_BASE_URL"

echo "=============================="
