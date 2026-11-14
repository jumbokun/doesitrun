#!/usr/bin/env bash
# Reproduce the llama.cpp CPU server from docs/llama-cpp/deployment/ec2.md without Docker.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
LLAMA_CPP_REF=b29c606e28a01b1bc8c1351026a0fa6e616bf6c4   # same pin as docker/llama_cpp/Dockerfile.cpu
cd /work
[ -d deep-learning-containers/.git ] || git clone --depth 1 https://github.com/aws/deep-learning-containers /work/deep-learning-containers

apt-get update
apt-get install -y --no-install-recommends cmake libssl-dev libgomp1 ca-certificates curl git

if [ ! -d /work/llama.cpp/.git ]; then
  git init -q /work/llama.cpp
  git -C /work/llama.cpp remote add origin https://github.com/ggml-org/llama.cpp.git
fi
git -C /work/llama.cpp fetch --depth 1 origin "$LLAMA_CPP_REF"
git -C /work/llama.cpp checkout -q FETCH_HEAD

cmake -S /work/llama.cpp -B /work/llama.cpp/build \
  -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF -DGGML_CPU_ALL_VARIANTS=ON \
  -DGGML_BACKEND_DL=ON -DGGML_OPENMP=ON -DLLAMA_CURL=OFF -DLLAMA_BUILD_TESTS=OFF
cmake --build /work/llama.cpp/build --config Release -j "$(nproc)" --target llama-server

mkdir -p /work/models
M=/work/models/qwen2.5-0.5b-instruct-q4_0.gguf
F=qwen2.5-0.5b-instruct-q4_0.gguf
if [ ! -s "$M" ]; then
  # Documented repo first; it currently returns 401 (missing/gated), so fall back to the
  # official Qwen repo which ships the identically named q4_0 GGUF.
  for REPO in ggml-org/Qwen2.5-0.5B-Instruct-GGUF Qwen/Qwen2.5-0.5B-Instruct-GGUF; do
    if curl -fL --retry 5 -o "$M.part" "https://huggingface.co/$REPO/resolve/main/$F"; then
      mv "$M.part" "$M"; echo "model from $REPO"; break
    fi
    rm -f "$M.part"
  done
fi
[ -s "$M" ] || { echo "model download failed"; exit 1; }
echo "setup done"
