#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

IMAGE_TAG="crypto-c-saw:latest"
echo "[*] Building base image: $IMAGE_TAG"
docker build -t "$IMAGE_TAG" -f Dockerfile .
echo "[+] Done: $IMAGE_TAG"