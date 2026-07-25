#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_ROOT="$(cd "${PROJECT_ROOT}/.." && pwd)"

FLUTTER_SDK="${WORKSPACE_ROOT}/.tooling/flutter_sdk"
LOCAL_HOME="${WORKSPACE_ROOT}/.tooling/home"
LOCAL_PUB_CACHE="${WORKSPACE_ROOT}/.tooling/pub_cache"

if [[ ! -x "${FLUTTER_SDK}/bin/flutter" ]]; then
  echo "Flutter SDK local nao encontrado em: ${FLUTTER_SDK}" >&2
  echo "Crie a copia local do SDK em .tooling/flutter_sdk antes de executar este script." >&2
  exit 1
fi

mkdir -p "${LOCAL_HOME}" "${LOCAL_PUB_CACHE}"

export HOME="${LOCAL_HOME}"
export PUB_CACHE="${LOCAL_PUB_CACHE}"
export PATH="${FLUTTER_SDK}/bin:${PATH}"

cd "${PROJECT_ROOT}"
exec flutter analyze "$@"
