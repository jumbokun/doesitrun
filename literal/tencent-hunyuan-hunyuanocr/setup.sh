#!/usr/bin/env bash
# literal: Tencent-Hunyuan/HunyuanOCR @ 1ef4179e53cf860f7e6fd8276a292e5d05b3e927
# readme: README.md, docs/llama_cpp.md
set -e  # glue strict mode
# README.md:L74 sends the reader to docs/llama_cpp.md for CPU deployment
cd /work  # glue the guide is followed from the working directory
git clone https://github.com/ggml-org/llama.cpp.git  # docs/llama_cpp.md:L28
cd llama.cpp  # docs/llama_cpp.md:L29
# skip docs/llama_cpp.md:L31 -DGGML_CUDA=ON is for NVIDIA GPU
cmake -B build -DLLAMA_BUILD_EXAMPLES=ON  # docs/llama_cpp.md:L32
cmake --build ./build --config Release -j  # docs/llama_cpp.md:L33
uv venv --python 3.12 venv-llamacpp  # docs/llama_cpp.md:L46
source venv-llamacpp/bin/activate  # docs/llama_cpp.md:L47
uv pip install huggingface_hub transformers torch openai  # docs/llama_cpp.md:L48
hf download tencent/HunyuanOCR --local-dir ./HunyuanOCR --exclude "v1.0/*"  # docs/llama_cpp.md:L54
python3 convert_hf_to_gguf.py --outfile ./HunyuanOCR/hyocr-f16.gguf --outtype f16 ./HunyuanOCR  # docs/llama_cpp.md:L62-L65
python3 convert_hf_to_gguf.py --outfile ./HunyuanOCR/mmproj-hyocr-f16.gguf --outtype f16 --mmproj ./HunyuanOCR  # docs/llama_cpp.md:L68-L72
# skip docs/llama_cpp.md:L83-L87 optional DFlash draft conversion
