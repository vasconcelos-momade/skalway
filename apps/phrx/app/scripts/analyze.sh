#!/usr/bin/env bash
# Resolve e descarrega dependências antes de analisar (equivalente a --deps + analyze).
# Uso: bash scripts/analyze.sh
#      bash scripts/analyze.sh lib/modules/sales/

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

flutter pub get
exec flutter analyze --no-pub "$@"
