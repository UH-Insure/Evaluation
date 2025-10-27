#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_TAG="${IMAGE_TAG:-crypto-c-eval:latest}"
MODEL=""
TASKS="eval/prompts/tasks.jsonl"
K="5"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --tasks) TASKS="$2"; shift 2 ;;
    --k)     K="$2"; shift 2 ;;
    *) EXTRA_ARGS+=("$1"); shift ;;
  esac
done

if [[ -z "$MODEL" ]]; then
  echo "[!] Provide --model MODEL_ID_OR_PATH"
  exit 1
fi

mkdir -p "${REPO_ROOT}/outputs"

# Optional HF token for private models
DOCKER_ENV=()
if [[ -n "${HF_TOKEN:-}" ]]; then
  DOCKER_ENV=(-e HUGGING_FACE_HUB_TOKEN="$HF_TOKEN" -e HF_TOKEN="$HF_TOKEN")
fi

# Inside the container: clone/build crypto-c, run SAW proofs, then evaluate
exec docker run --rm -it \
  -v "${REPO_ROOT}:/work" \
  "${DOCKER_ENV[@]}" \
  "${IMAGE_TAG}" \
  bash -lc '
    set -euo pipefail
    cd /work
    if [ ! -d crypto-c ]; then
      git clone https://github.com/UH-Insure/crypto-c.git
    fi
    cd crypto-c
    chmod +x scripts/setup.sh || true
    # Prefer the more portable setup if available; fallback to colab script:
    if [ -x scripts/setup.sh ]; then
      bash scripts/setup.sh
    else
      chmod +x scripts/colab_setup.sh
      bash scripts/colab_setup.sh
    fi
    bash scripts/run-all-saw.sh
    cd /work
    python3 scripts/run_eval.py --model "'"$MODEL"'" --tasks "'"$TASKS"'" --k "'"$K"'" '"${EXTRA_ARGS[*]}"'
  '