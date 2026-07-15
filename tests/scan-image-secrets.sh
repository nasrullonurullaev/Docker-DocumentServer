#!/bin/bash

set -euo pipefail

readonly DEFAULT_TRIVY_IMAGE="docker.io/aquasec/trivy:0.70.0@sha256:be1190afcb28352bfddc4ddeb71470835d16462af68d310f9f4bca710961a41e"
readonly TRIVY_IMAGE="${TRIVY_IMAGE:-${DEFAULT_TRIVY_IMAGE}}"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <image-or-docker-archive>" >&2
  exit 2
fi

readonly IMAGE_TO_SCAN="$1"

DOCKER_ARGS=(
  --rm
  --volume trivy-cache:/root/.cache/trivy
)
TRIVY_TARGET=("${IMAGE_TO_SCAN}")

if [ -f "${IMAGE_TO_SCAN}" ]; then
  readonly IMAGE_ARCHIVE="$(realpath "${IMAGE_TO_SCAN}")"
  DOCKER_ARGS+=(--volume "${IMAGE_ARCHIVE}:/scan/image.tar:ro")
  TRIVY_TARGET=(--input /scan/image.tar)
else
  DOCKER_ARGS+=(--volume /var/run/docker.sock:/var/run/docker.sock)
fi

docker run "${DOCKER_ARGS[@]}" \
  "${TRIVY_IMAGE}" image \
  --scanners secret \
  --image-config-scanners secret \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --no-progress \
  "${TRIVY_TARGET[@]}"
