#!/usr/bin/env bash
# Scripts partilhados — dry-run / logging
# shellcheck shell=bash

set -euo pipefail

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
  esac
done

log()  { printf '==> %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
die()  { printf '❌ %s\n' "$*" >&2; exit 1; }

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  # shellcheck disable=SC2068
  "$@"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Comando em falta: $1"
}

repo_root() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  # infra/scripts → skalway/
  cd "$here/../.." && pwd
}

PHRX_COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docker/phrx" && pwd)"
