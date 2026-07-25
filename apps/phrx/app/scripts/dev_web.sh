#!/usr/bin/env bash
# Desenvolvimento web sem voltar a correr pub get em cada arranque.
# Primeira vez (ou após alterar pubspec): bash scripts/dev_web.sh --deps
# Análise estática com dependências atualizadas: bash scripts/analyze.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "--analyze" ]]; then
  shift
  exec "$ROOT/scripts/analyze.sh" "$@"
fi

if [[ "${1:-}" == "--deps" ]]; then
  flutter pub get
  shift
fi

exec "$ROOT/scripts/run_web.sh" "$@"
