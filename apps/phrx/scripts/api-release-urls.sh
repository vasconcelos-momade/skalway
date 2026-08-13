#!/bin/bash
# api-release-urls.sh — URLs de API para builds empacotados (.deb / APK / AppImage)
# Builds de distribuição NÃO usam API local (localhost / emulador).
#
# Uso:
#   source "$(dirname "$0")/api-release-urls.sh"
#   # ou a partir de apps/phrx/app:
#   source "../scripts/api-release-urls.sh"
#   phrx_export_release_api_urls

PHRX_RELEASE_API_URL="${PHRX_RELEASE_API_URL:-https://api-phrx.skalway.com}"

phrx_is_local_api_url() {
  local url="${1:-}"
  case "$url" in
    ""|*localhost*|*127.0.0.1*|*0.0.0.0*|*10.0.2.2*|*\[::1\]*|*:4001*)
      # :4001 = porta local do backend de desenvolvimento
      return 0
      ;;
  esac
  # Hosts privados típicos de LAN (opcional: bloquear também)
  if echo "$url" | grep -Eq '://(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'; then
    return 0
  fi
  return 1
}

phrx_require_non_local_api() {
  local label="${1:-API}"
  local url="${2:-}"
  if phrx_is_local_api_url "$url"; then
    echo "❌ Builds .deb/.apk/AppImage não podem usar API local (${label}): $url"
    echo "   Defina uma URL remota, ex.: ${PHRX_RELEASE_API_URL}"
    exit 1
  fi
}

# Exporta API_BASE_URL / API_CLOUD_URL para a API de release (nunca local).
# Overrides só são aceites se NÃO forem locais.
phrx_export_release_api_urls() {
  local base="${API_BASE_URL:-$PHRX_RELEASE_API_URL}"
  local cloud="${API_CLOUD_URL:-$PHRX_RELEASE_API_URL}"

  if phrx_is_local_api_url "$base"; then
    echo "⚠️  API_BASE_URL local ignorada ($base) → $PHRX_RELEASE_API_URL"
    base="$PHRX_RELEASE_API_URL"
  fi
  if phrx_is_local_api_url "$cloud"; then
    echo "⚠️  API_CLOUD_URL local ignorada ($cloud) → $PHRX_RELEASE_API_URL"
    cloud="$PHRX_RELEASE_API_URL"
  fi

  export API_BASE_URL="$base"
  export API_CLOUD_URL="$cloud"

  phrx_require_non_local_api "API_BASE_URL" "$API_BASE_URL"
  phrx_require_non_local_api "API_CLOUD_URL" "$API_CLOUD_URL"
}
