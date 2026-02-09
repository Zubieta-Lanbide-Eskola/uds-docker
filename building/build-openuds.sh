#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Build and optionally push OpenUDS broker and tunnel-server images
# Usage:
#   ./build-openuds.sh
#
#
# Images:
#   - lhzubieta/uds-broker:4.0
#   - lhzubieta/uds-tunnel-server:4.0
###############################################################################

OPENUDS_COMMIT="7bc12cc"

BROKER_IMAGE="lhzubieta/uds-broker:4.0"
TUNNEL_IMAGE="lhzubieta/uds-tunnel-server:4.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Track Docker Hub login state
DOCKER_LOGGED_IN_BEFORE=false
if docker info 2>/dev/null | grep -q "Username:"; then
  DOCKER_LOGGED_IN_BEFORE=true
fi

echo "Using OPENUDS_COMMIT='${OPENUDS_COMMIT}'"
echo "Build context directory: ${SCRIPT_DIR}"

echo "========================================"
echo "Building broker image..."
echo "========================================"
docker build \
  --build-arg OPENUDS_COMMIT="${OPENUDS_COMMIT}" \
  -f "${SCRIPT_DIR}/broker/DockerFile" \
  -t "${BROKER_IMAGE}" \
  "${SCRIPT_DIR}"

echo "========================================"
echo "Building tunnel-server image..."
echo "========================================"
docker build \
  --build-arg OPENUDS_COMMIT="${OPENUDS_COMMIT}" \
  -f "${SCRIPT_DIR}/tunnelserver/DockerFile" \
  -t "${TUNNEL_IMAGE}" \
  "${SCRIPT_DIR}"

echo "========================================"
echo "Images built successfully:"
echo "  - ${BROKER_IMAGE}"
echo "  - ${TUNNEL_IMAGE}"
echo "========================================"

read -rp "Do you want to push these images to Docker Hub? (y/N): " PUSH_CONFIRM

case "${PUSH_CONFIRM}" in
  y|Y|yes|YES)
    echo "========================================"
    echo "Preparing to push images to Docker Hub..."
    echo "========================================"

    if [ "${DOCKER_LOGGED_IN_BEFORE}" != "true" ]; then
      echo "You are not logged in to Docker Hub."
      echo "Please log in before pushing images."
      docker login
    else
      echo "Already logged in to Docker Hub. Skipping login."
    fi

    echo "========================================"
    echo "Pushing images to Docker Hub..."
    echo "========================================"
    docker push "${BROKER_IMAGE}"
    docker push "${TUNNEL_IMAGE}"

    echo "========================================"
    echo "Images pushed successfully:"
    echo "  - ${BROKER_IMAGE}"
    echo "  - ${TUNNEL_IMAGE}"
    echo "========================================"

    if [ "${DOCKER_LOGGED_IN_BEFORE}" != "true" ]; then
      echo "Logging out from Docker Hub (session created by this script)..."
      docker logout
    fi
    ;;
  *)
    echo "Push skipped. Images are only available locally."
    ;;
esac