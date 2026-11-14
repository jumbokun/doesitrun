#!/usr/bin/env bash
# Reproduce HunyuanOCR llama.cpp CPU deployment (docs/llama_cpp.md)
set -euxo pipefail
cd /work
export DEBIAN_FRONTEND=noninteractive
# cmake is not in the base image (README assumes it)
apt-get update && apt-get install -y --no-install-recommends cmake libssl-dev ca-certificates

[ -d HunyuanOCR/.git ] || git clone https://github.com/Tencent-Hunyuan/HunyuanOCR /work/HunyuanOCR
[ -d llama.cpp/.git ] || git clone https://github.com/ggml-org/llama.cpp.git /work/llama.cpp

cd /work/llama.cpp
# CPU-only build (no -DGGML_CUDA)
cmake -B build -DLLAMA_BUILD_EXAMPLES=ON -DGGML_CUDA=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build ./build --config Release -j"$(nproc)" --target llama-server
build/bin/llama-server --help | grep -A2 -- --spec-type || true

cd /work
[ -d venv-llamacpp ] || uv venv --python 3.12 venv-llamacpp
source venv-llamacpp/bin/activate
# CPU torch wheel to avoid pulling multi-GB CUDA deps
uv pip install --index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple torch
uv pip install huggingface_hub transformers openai -r /work/llama.cpp/requirements/requirements-convert_hf_to_gguf.txt \
    --index-strategy unsafe-best-match --extra-index-url https://download.pytorch.org/whl/cpu

MD=/work/models/HunyuanOCR
mkdir -p "$MD"
hf download tencent/HunyuanOCR --local-dir "$MD" --exclude "v1.0/*" --exclude "dflash/*"

cd /work/llama.cpp
[ -s "$MD/hyocr-f16.gguf" ] || python3 convert_hf_to_gguf.py --outfile "$MD/hyocr-f16.gguf" --outtype f16 "$MD"
[ -s "$MD/mmproj-hyocr-f16.gguf" ] || python3 convert_hf_to_gguf.py --outfile "$MD/mmproj-hyocr-f16.gguf" --outtype f16 --mmproj "$MD"
echo SETUP_OK
