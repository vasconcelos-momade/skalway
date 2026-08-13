#!/usr/bin/env bash
# install-android-sdk.sh — Instala Android SDK (cmdline-tools) + Java 17 e configura PATH
#
# Resolve: "[!] No Android SDK found. Try setting the ANDROID_HOME environment variable."
#
# Uso:
#   bash apps/phrx/scripts/install-android-sdk.sh
#   # ou a partir de apps/phrx:
#   bash scripts/install-android-sdk.sh
#
# Variáveis opcionais:
#   ANDROID_SDK_ROOT=~/Android/Sdk   (destino do SDK)
#   SKIP_JAVA=1                     (não instalar JDK)
#   ANDROID_API=35                  (nível da plataforma)

set -euo pipefail

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
ANDROID_HOME="$ANDROID_SDK_ROOT"
ANDROID_API="${ANDROID_API:-35}"
BUILD_TOOLS="${BUILD_TOOLS:-35.0.0}"
# Command-line tools (Linux). Actualizar URL se o Google publicar build mais recente.
CMDLINE_URL="${CMDLINE_URL:-https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip}"
SKIP_JAVA="${SKIP_JAVA:-0}"

MARKER_BEGIN="# >>> skalway-android-sdk >>>"
MARKER_END="# <<< skalway-android-sdk <<<"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}AVISO:${NC} $*"; }
die()  { echo -e "${RED}ERRO:${NC} $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatório em falta: $1"
}

# ---------------------------------------------------------------------------
# 0. Pré-requisitos
# ---------------------------------------------------------------------------
need_cmd curl
need_cmd unzip
need_cmd sudo

log "Destino do Android SDK: ${ANDROID_SDK_ROOT}"

# ---------------------------------------------------------------------------
# 1. Java JDK 17 (obrigatório para Gradle / Flutter Android)
# ---------------------------------------------------------------------------
ensure_java() {
  if [[ "$SKIP_JAVA" == "1" ]]; then
    warn "SKIP_JAVA=1 — a saltar instalação do JDK"
    return
  fi

  if command -v java >/dev/null 2>&1; then
    log "Java já instalado: $(java -version 2>&1 | head -1)"
  else
    log "A instalar OpenJDK 17 (sudo)..."
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk
  fi

  local java_bin java_home
  java_bin="$(readlink -f "$(command -v java)")"
  java_home="$(dirname "$(dirname "$java_bin")")"
  # Em Debian/Ubuntu o caminho típico é /usr/lib/jvm/java-17-openjdk-amd64
  if [[ -d /usr/lib/jvm/java-17-openjdk-amd64 ]]; then
    java_home="/usr/lib/jvm/java-17-openjdk-amd64"
  fi
  export JAVA_HOME="$java_home"
  export PATH="$JAVA_HOME/bin:$PATH"
  log "JAVA_HOME=${JAVA_HOME}"
}

# ---------------------------------------------------------------------------
# 2. Command-line tools + pacotes SDK
# ---------------------------------------------------------------------------
install_cmdline_tools() {
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

  local sdkmanager="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"
  if [[ -x "$sdkmanager" ]]; then
    log "cmdline-tools já presentes"
    return
  fi

  local zip="/tmp/commandlinetools-linux.zip"
  local unpack="/tmp/cmdline-tools-unpack-$$"

  log "A transferir Android command-line tools..."
  curl -fL --retry 3 --retry-delay 2 -o "$zip" "$CMDLINE_URL"

  rm -rf "$unpack"
  mkdir -p "$unpack"
  unzip -q "$zip" -d "$unpack"

  # O zip contém a pasta "cmdline-tools/" — deve ficar em cmdline-tools/latest/
  rm -rf "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  if [[ -d "${unpack}/cmdline-tools" ]]; then
    mv "${unpack}/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest"
  else
    die "Estrutura inesperada no zip das cmdline-tools"
  fi

  rm -rf "$unpack" "$zip"
  log "cmdline-tools instaladas"
}

install_sdk_packages() {
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export ANDROID_SDK_ROOT
  export PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

  local sdkmanager
  sdkmanager="$(command -v sdkmanager)" || die "sdkmanager não encontrado no PATH"

  log "A aceitar licenças Android..."
  yes | "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" --licenses >/tmp/android-sdk-licenses.log 2>&1 || true

  log "A instalar platform-tools, platforms;android-${ANDROID_API}, build-tools;${BUILD_TOOLS}..."
  "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" \
    "platform-tools" \
    "platforms;android-${ANDROID_API}" \
    "build-tools;${BUILD_TOOLS}"

  # Plataforma 34 também (alguns plugins Flutter ainda referenciam)
  if [[ "$ANDROID_API" != "34" ]]; then
    "$sdkmanager" --sdk_root="${ANDROID_SDK_ROOT}" "platforms;android-34" || true
  fi
}

# ---------------------------------------------------------------------------
# 3. PATH / ANDROID_HOME no ~/.bashrc
# ---------------------------------------------------------------------------
update_bashrc() {
  local bashrc="${HOME}/.bashrc"
  local java_home_line=""
  if [[ -n "${JAVA_HOME:-}" ]]; then
    java_home_line="export JAVA_HOME=\"${JAVA_HOME}\""
  else
    java_home_line='export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"'
  fi

  local block
  block=$(cat <<EOF
${MARKER_BEGIN}
# Android SDK (Skalway PhRx / Flutter)
export ANDROID_HOME="${ANDROID_SDK_ROOT}"
export ANDROID_SDK_ROOT="\${ANDROID_HOME}"
${java_home_line}
export PATH="\${JAVA_HOME}/bin:\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools:\${ANDROID_HOME}/emulator:\${PATH}"
${MARKER_END}
EOF
)

  touch "$bashrc"

  # Remover bloco antigo (se existir) e bloco genérico incompleto só com ANDROID_HOME vazio
  if grep -qF "$MARKER_BEGIN" "$bashrc" 2>/dev/null; then
    log "A actualizar bloco Android no ~/.bashrc"
    # Remove entre markers
    sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "$bashrc"
  else
    log "A acrescentar Android SDK ao ~/.bashrc"
  fi

  {
    echo ""
    echo "$block"
  } >>"$bashrc"

  # Exportar na sessão actual
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export ANDROID_SDK_ROOT
  export PATH="${JAVA_HOME:-}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator:${PATH}"
}

# ---------------------------------------------------------------------------
# 4. Verificação
# ---------------------------------------------------------------------------
verify() {
  log "A verificar instalação..."
  [[ -x "${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" ]] \
    || die "sdkmanager em falta"
  [[ -d "${ANDROID_SDK_ROOT}/platform-tools" ]] \
    || die "platform-tools em falta"
  [[ -d "${ANDROID_SDK_ROOT}/platforms/android-${ANDROID_API}" ]] \
    || die "platforms;android-${ANDROID_API} em falta"

  echo ""
  echo "=============================================="
  echo "✅ Android SDK instalado"
  echo "=============================================="
  echo "ANDROID_HOME=${ANDROID_HOME}"
  echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
  echo "JAVA_HOME=${JAVA_HOME:-"(não definido)"}"
  echo ""
  echo "sdkmanager: $(command -v sdkmanager)"
  echo "adb:        $(command -v adb || echo '(ainda não no PATH desta sessão)')"
  if command -v adb >/dev/null 2>&1; then
    adb version 2>&1 | head -1 || true
  fi
  echo "=============================================="
}

# ---------------------------------------------------------------------------
main() {
  ensure_java
  install_cmdline_tools
  install_sdk_packages
  update_bashrc
  verify

  echo ""
  echo "Próximos passos (teste):"
  echo "  1) source ~/.bashrc"
  echo "  2) echo \$ANDROID_HOME && flutter doctor -v"
  echo "  3) cd apps/phrx && ./build-dev-apk.sh"
  echo ""
}

main "$@"
