#!/usr/bin/env bash
# Reproduce the T2I-Adapter-SDXL "Quick start with diffusers" (LineArt) setup on a CPU-only box.
set -euo pipefail
cd /work

# 1. Clone
[ -d T2I-Adapter/.git ] || git clone https://github.com/TencentARC/T2I-Adapter /work/T2I-Adapter

# 2. System packages (opencv, pulled in by controlnet_aux, needs libGL/glib)
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0

# 3. Python env
[ -x venv/bin/python ] || uv venv -p 3.10 venv
export VIRTUAL_ENV=/work/venv PATH=/work/venv/bin:$PATH
# CPU torch (recent build: much faster bf16 conv on CPUs without native bf16)
uv pip install torch==2.14.1 torchvision==0.29.2 --index-url https://download.pytorch.org/whl/cpu
# README deps; pins keep the 2023 diffusers branch working (huggingface_hub/transformers APIs changed since)
uv pip install "git+https://github.com/huggingface/diffusers.git@e2e633635eb27a133d17cc8faa2a3bfc304dca1c" \
    controlnet_aux==0.0.7 transformers==4.33.2 accelerate==0.23.0 safetensors \
    huggingface_hub==0.17.3 "numpy<2"

# 4. Patch diffusers: channels_last conv weights on CPU (bf16 conv otherwise ~35x slower)
python - "$(python -c 'import diffusers.models.modeling_utils as m; print(m.__file__)')" <<'PY'
# Patch the installed diffusers so models loaded on CPU keep 4D conv weights in channels_last.
# Without this, bf16 Conv2d on CPUs lacking native bf16 (e.g. AMD Zen3) falls to a ~35x slower path.
import sys, re
f = sys.argv[1]
s = open(f).read()
marker = "# [cpu-channels-last patch]"
if marker not in s:
    old = "        model.eval()\n        if output_loading_info:"
    new = ("        model.eval()\n"
           "        " + marker + "\n"
           "        if all(p.device.type == \"cpu\" for p in model.parameters()):\n"
           "            model.to(memory_format=torch.channels_last)\n"
           "        if output_loading_info:")
    assert s.count(old) == 1, "patch anchor not found"
    open(f, "w").write(s.replace(old, new))
print("patched", f)
PY

# 5. Models
export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download as s
s('TencentARC/t2i-adapter-lineart-sdxl-1.0')
s('madebyollin/sdxl-vae-fp16-fix', allow_patterns=['*.json', '*.safetensors'])
s('lllyasviel/Annotators', allow_patterns=['sk_model.pth', 'sk_model2.pth'])
s('stabilityai/stable-diffusion-xl-base-1.0', allow_patterns=[
    'model_index.json', '*/*.json', '*/*.txt', 'scheduler/*',
    'unet/diffusion_pytorch_model*.safetensors', 'text_encoder/model*.safetensors',
    'text_encoder_2/model*.safetensors', 'vae/diffusion_pytorch_model*.safetensors'])
PY
echo "setup done"
