#!/bin/bash

set -euo pipefail

readonly DEFAULT_TRIVY_IMAGE="docker.io/aquasec/trivy:0.70.0@sha256:be1190afcb28352bfddc4ddeb71470835d16462af68d310f9f4bca710961a41e"
readonly TRIVY_IMAGE="${TRIVY_IMAGE:-${DEFAULT_TRIVY_IMAGE}}"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <image>" >&2
  exit 2
fi

readonly IMAGE_TO_SCAN="$1"

docker run --rm \
  --volume trivy-cache:/root/.cache/trivy \
  "${TRIVY_IMAGE}" image \
  --scanners secret \
  --image-config-scanners secret \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --no-progress \
  "${IMAGE_TO_SCAN}"
