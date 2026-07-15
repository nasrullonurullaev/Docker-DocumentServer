#!/bin/bash

set -euo pipefail

readonly DEFAULT_TRIVY_IMAGE="docker.io/aquasec/trivy:0.70.0@sha256:be1190afcb28352bfddc4ddeb71470835d16462af68d310f9f4bca710961a41e"
readonly TRIVY_IMAGE="${TRIVY_IMAGE:-${DEFAULT_TRIVY_IMAGE}}"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <image-or-docker-archive>" >&2
  exit 2
fi

readonly IMAGE_TO_SCAN="$1"

TRIVY_ARGS=(
  image
  --scanners secret
  --image-config-scanners secret
  --severity HIGH,CRITICAL
  --exit-code 1
  --no-progress
  --skip-version-check
)

TEMP_ARCHIVE=""
TRIVY_CONTAINER=""

cleanup() {
  [ -z "${TRIVY_CONTAINER}" ] || docker rm -f "${TRIVY_CONTAINER}" >/dev/null 2>&1 || true
  [ -z "${TEMP_ARCHIVE}" ] || rm -f "${TEMP_ARCHIVE}"
}
trap cleanup EXIT

scan_archive() {
  local archive=$1 scan_exit

  TRIVY_CONTAINER=$(docker create \
    --volume trivy-cache:/root/.cache/trivy \
    "${TRIVY_IMAGE}" "${TRIVY_ARGS[@]}" --input /image.tar)
  docker cp "${archive}" "${TRIVY_CONTAINER}:/image.tar"
  docker start --attach "${TRIVY_CONTAINER}" || true
  scan_exit=$(docker inspect --format '{{.State.ExitCode}}' "${TRIVY_CONTAINER}")
  docker rm "${TRIVY_CONTAINER}" >/dev/null
  TRIVY_CONTAINER=""

}

if [ -f "${IMAGE_TO_SCAN}" ]; then
  readonly IMAGE_ARCHIVE="$(realpath "${IMAGE_TO_SCAN}")"
  scan_archive "${IMAGE_ARCHIVE}"
else
  DOCKER_ENDPOINT="${DOCKER_HOST:-$(docker context inspect --format '{{.Endpoints.docker.Host}}' 2>/dev/null || true)}"
  DOCKER_SOCKET="${DOCKER_ENDPOINT#unix://}"

  if [ "${DOCKER_SOCKET}" != "${DOCKER_ENDPOINT}" ] && [ -S "${DOCKER_SOCKET}" ]; then
    docker run --rm \
      --volume trivy-cache:/root/.cache/trivy \
      --volume "${DOCKER_SOCKET}:/var/run/docker.sock" \
      --env DOCKER_HOST=unix:///var/run/docker.sock \
      "${TRIVY_IMAGE}" "${TRIVY_ARGS[@]}" "${IMAGE_TO_SCAN}"
  else
    TEMP_ARCHIVE=$(mktemp "${TMPDIR:-/tmp}/trivy-image-XXXXXX.tar")
    docker image save --output "${TEMP_ARCHIVE}" "${IMAGE_TO_SCAN}"
    scan_archive "${TEMP_ARCHIVE}"
  fi
fi
