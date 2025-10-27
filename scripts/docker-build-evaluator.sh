#!/usr/bin/env bash
set -euo pipefail
# Build the evaluator image that layers Python + transformers on top of the base image.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

IMAGE_TAG="crypto-c-eval:latest"
DOCKERFILE="docker/Dockerfile.evaluator"

# Allow overriding the base image tag
BASE_IMAGE="${BASE_IMAGE:-crypto-c-saw:latest}"

echo "[*] Building evaluator image: $IMAGE_TAG (BASE_IMAGE=${BASE_IMAGE})"
docker build --build-arg BASE_IMAGE="${BASE_IMAGE}" -t "$IMAGE_TAG" -f "$DOCKERFILE" .
echo "[+] Done: $IMAGE_TAG"