#!/usr/bin/env bash
# Reproduce HunyuanOCR-1.5 llama.cpp (CPU) deployment from scratch.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
W=/work
LLAMA_SHA=9183a552e5fdcbdb5243f187f3a63204eca7dba9   # upstream master (>= b11103) at setup time
cd $W

# 0. Project repo
[ -d $W/HunyuanOCR/.git ] || GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/Tencent-Hunyuan/HunyuanOCR $W/HunyuanOCR

# 1. System packages (cmake is not in the base image)
apt-get update
apt-get install -y --no-install-recommends cmake libssl-dev pkg-config ca-certificates

# 2. Build upstream llama.cpp, CPU only (CUDA explicitly off)
if [ ! -d $W/llama.cpp/.git ]; then
  git clone https://github.com/ggml-org/llama.cpp.git $W/llama.cpp
fi
cd $W/llama.cpp
git fetch origin "$LLAMA_SHA" || true
git checkout -q "$LLAMA_SHA"
cmake -B build -DLLAMA_BUILD_EXAMPLES=ON -DGGML_CUDA=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build ./build --config Release -j"$(nproc)" --target llama-server llama-mtmd-cli

# 3. Python env for conversion (CPU torch to avoid pulling CUDA wheels)
cd $W
[ -d $W/venv-llamacpp ] || uv venv --python 3.12 $W/venv-llamacpp
uv pip install --python $W/venv-llamacpp/bin/python --index-strategy unsafe-best-match \
  --extra-index-url https://download.pytorch.org/whl/cpu \
  "torch" huggingface_hub transformers openai pillow \
  -r $W/llama.cpp/requirements/requirements-convert_hf_to_gguf.txt
source $W/venv-llamacpp/bin/activate

# 4. Download weights (base model only; skip v1.0 and DFlash draft)
M=$W/llama.cpp/HunyuanOCR
hf download tencent/HunyuanOCR --local-dir $M --exclude "v1.0/*" --exclude "dflash/*"

# 5. Convert to GGUF
cd $W/llama.cpp
[ -s $M/hyocr-f16.gguf ] || python3 convert_hf_to_gguf.py --outfile $M/hyocr-f16.gguf --outtype f16 $M
[ -s $M/mmproj-hyocr-f16.gguf ] || python3 convert_hf_to_gguf.py --outfile $M/mmproj-hyocr-f16.gguf --outtype f16 --mmproj $M
ls -la $M/*.gguf
echo SETUP_OK
