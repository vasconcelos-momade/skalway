#!/bin/bash

set -e

# Configurações do App
APP_NAME="skalway-phrx"
DISPLAY_NAME="Skalway PhRx"
VERSION="1.0.0"
MAINTAINER="Skalway <suporte@skalway.com>"
DESCRIPTION="Sistema de gestão Skalway PhRx — ERP farmacêutico"
API_BASE_URL="https://api.skalway.com"
DEB_DIR="pkg_deb"
ICON_PATH="assets/icons/icon.png"
ICON_NAME="skalway_phrx"
WM_CLASS="skalway_phrx"
BINARY_NAME="skalway_phrx"

echo "=============================="
echo "🚀 BUILD DEB SKALWAY PHRX"
echo "=============================="

# Limpar ambiente
echo "🧹 Limpando ambiente..."
rm -rf build "$DEB_DIR"
rm -f "${APP_NAME}"*.deb

# Verificar suporte Linux
if [ ! -d "linux" ]; then
  echo "⚙️ Linux não encontrado. Criando suporte..."
  flutter create --platforms=linux .
fi

# Gerar build Linux
echo "📦 Gerando build Linux..."
flutter build linux --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=API_CLOUD_URL=$API_BASE_URL \
  --dart-define=APP_NAME="$DISPLAY_NAME"

# Criar estrutura do pacote DEB com multi-resolução de ícones
echo "📁 Criando estrutura do pacote..."
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/lib/$APP_NAME"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"
mkdir -p "$DEB_DIR/DEBIAN"

# Criar pastas para múltiplas resoluções de ícones
for size in 16 32 48 64 128 256; do
  mkdir -p "$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps"
done

# Copiar ficheiros do build para a estrutura DEB
echo "📂 Copiando ficheiros..."
cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/lib/$APP_NAME/"

# Criar link simbólico em /usr/bin
ln -sf "/usr/lib/$APP_NAME/$BINARY_NAME" "$DEB_DIR/usr/bin/$APP_NAME"

# Instalar ícones
if [ -f "$ICON_PATH" ]; then
  echo "🎨 Instalando ícones multi-resolução..."
  for size in 16 32 48 64 128 256; do
    # Instalar com hífen (padrão DEB)
    cp "$ICON_PATH" "$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/skalway-phrx.png"
    # Instalar com underscore (padrão Flutter/C++)
    cp "$ICON_PATH" "$DEB_DIR/usr/share/icons/hicolor/${size}x${size}/apps/skalway_phrx.png"
  done
  cp "$ICON_PATH" "$DEB_DIR/usr/share/pixmaps/skalway-phrx.png"
  cp "$ICON_PATH" "$DEB_DIR/usr/share/pixmaps/skalway_phrx.png"
else
  echo "⚠️ Ícone não encontrado em $ICON_PATH"
fi

# Criar ficheiro .desktop (Versão Sincronizada com o ID do C++)
# O NOME DO FICHEIRO É CRÍTICO: skalway_phrx.desktop
echo "📄 Criando desktop entry..."
cat <<EOF > "$DEB_DIR/usr/share/applications/skalway_phrx.desktop"
[Desktop Entry]
Name=$DISPLAY_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=skalway_phrx
Type=Application
Terminal=false
StartupWMClass=$WM_CLASS
Categories=Utility;
Keywords=PhRx;Pharmacy;Farmacia;Skalway;
X-GNOME-Autostart-enabled=true
EOF

# Criar scripts de pós-instalação e pós-remoção
echo "📝 Criando scripts de manutenção..."
cat <<EOF > "$DEB_DIR/DEBIAN/postinst"
#!/bin/bash
set -e
update-desktop-database -q
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
EOF

cat <<EOF > "$DEB_DIR/DEBIAN/postrm"
#!/bin/bash
set -e
update-desktop-database -q
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
EOF

chmod 755 "$DEB_DIR/DEBIAN/postinst" "$DEB_DIR/DEBIAN/postrm"

# Criar ficheiro de controlo do DEB
echo "📝 Criando ficheiro control..."
cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Architecture: amd64
Maintainer: $MAINTAINER
Description: $DESCRIPTION
Section: utils
Priority: optional
Depends: libc6, libgtk-3-0, libblkid1, liblzma5
EOF

# Gerar o pacote .deb
echo "🚀 Gerando pacote .deb..."
dpkg-deb --build "$DEB_DIR" "${APP_NAME}_${VERSION}_amd64.deb"

# Limpar pasta temporária
rm -rf "$DEB_DIR"

echo "=============================="
echo "✅ DEB DE PRODUÇÃO CONCLUÍDO"
echo "📦 Ficheiro: ${APP_NAME}_${VERSION}_amd64.deb"
echo "=============================="
echo "Para instalar corre: sudo dpkg -i ${APP_NAME}_${VERSION}_amd64.deb"
