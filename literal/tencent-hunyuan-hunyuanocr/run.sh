#!/usr/bin/env bash
# literal: Tencent-Hunyuan/HunyuanOCR @ 1ef4179e53cf860f7e6fd8276a292e5d05b3e927
# readme: README.md, docs/llama_cpp.md
set -e  # glue strict mode
cd /work/llama.cpp  # glue docs/llama_cpp.md:L97 paths are relative to the llama.cpp checkout
# skip docs/llama_cpp.md:L109-L119 DFlash variant; base model only (L96-L103)
#= docs/llama_cpp.md:L97-L102
nohup build/bin/llama-server --model "./HunyuanOCR/hyocr-f16.gguf" --mmproj "./HunyuanOCR/mmproj-hyocr-f16.gguf" --host 0.0.0.0 --port 8080 --alias HYVL --ctx-size 10240 --n-predict 4096 -fa on --jinja > /work/server.log 2>&1 &  # glue start the guide server in the background
for i in $(seq 1 240); do curl -sf http://127.0.0.1:8080/health && break; sleep 5; done  # glue wait until ready
