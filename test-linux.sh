#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONTAINER_IMAGE="${CONTAINER_IMAGE:-swift:6.3}"
CONTAINER_MEMORY="${CONTAINER_MEMORY:-4G}"
CONTAINER_CPUS="${CONTAINER_CPUS:-4}"

exec container run \
  --rm \
  --memory "${CONTAINER_MEMORY}" \
  --cpus "${CONTAINER_CPUS}" \
  --volume "${ROOT_DIR}:/workspace" \
  --workdir /workspace \
  "${CONTAINER_IMAGE}" \
  swift test "$@"
