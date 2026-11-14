#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work
[ -d gpt-oss/.git ] || git clone https://github.com/openai/gpt-oss /work/gpt-oss
# Ollama's install.sh needs zstd to unpack the release tarball
apt-get update -y && apt-get install -y --no-install-recommends zstd ca-certificates curl pciutils
command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
source /work/env.sh
# No systemd in the container: start a temporary server to pull the model
if ! curl -sf http://127.0.0.1:11434/api/version >/dev/null; then
  nohup ollama serve > /work/setup-ollama.log 2>&1 &
  SPID=$!
  for i in $(seq 60); do curl -sf http://127.0.0.1:11434/api/version >/dev/null && break; sleep 1; done
fi
ollama pull gpt-oss:20b
[ -n "${SPID:-}" ] && kill $SPID || true
echo "setup done"
