#!/usr/bin/env bash
set -euo pipefail

# Portable SAW/Cryptol (Ubuntu-based)
echo "[*] Installing portable SAW/Cryptol..."

TMPDIR="$(mktemp -d)"
pushd "$TMPDIR" >/dev/null

# Install SAW 
curl -fsSL https://github.com/GaloisInc/saw-script/releases/download/v1.3/saw-1.3-ubuntu-20.04-X64-with-solvers.tar.gz -o saw.tgz
sudo mkdir -p /opt/saw
sudo tar -xf saw.tgz -C /opt/saw --strip-components=1
sudo ln -sf /opt/saw/bin/saw /usr/local/bin/saw
sudo ln -sf /opt/saw/bin/cryptol /usr/local/bin/cryptol

which saw
saw --version || true
cryptol --version || true

popd >/dev/null
echo "[*] SAW/Cryptol installed."