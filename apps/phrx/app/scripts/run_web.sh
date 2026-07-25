#!/usr/bin/env bash
# Arranque web rápido — NÃO volta a resolver/baixar pacotes (use dev_web.sh --deps se mudou pubspec).
# Uso: bash scripts/run_web.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${WEB_PORT:-5000}"
PACKAGE_CONFIG="$ROOT/.dart_tool/package_config.json"
PACKAGE_GRAPH="$ROOT/.dart_tool/package_graph.json"

needs_pub_get=0

if [[ ! -f "$PACKAGE_CONFIG" || ! -f "$PACKAGE_GRAPH" ]]; then
  needs_pub_get=1
elif ! grep -Eq '"name"[[:space:]]*:[[:space:]]*"phrx"' "$PACKAGE_GRAPH"; then
  needs_pub_get=1
fi

if [[ "$needs_pub_get" -eq 1 ]]; then
  echo "Metadados do Flutter Pub em falta ou desatualizados. A correr: flutter pub get"
  flutter pub get
fi

exec flutter run -d chrome --no-pub --web-port="$PORT" "$@"
