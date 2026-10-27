#!/bin/bash
set -euo pipefail
cd /work
[ -d DiffSynth-Studio ] || git clone https://github.com/modelscope/DiffSynth-Studio
cd DiffSynth-Studio
git checkout -q d55ff1999b57547e58d7b06c224bc98b75297fd5
[ -d /work/venv ] || uv venv -p python3.12 /work/venv
source /work/venv/bin/activate
# CPU-only torch wheels (avoid pulling multi-GB CUDA wheels)
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
uv pip install -e . --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match
# CPU variant of the example
sed -e 's/rand_device="cuda"/rand_device="cpu"/' \
    -e 's/torch_dtype=torch.float32,/torch_dtype=torch.float32,\n    device="cpu",/' \
    -e 's/num_inference_steps=50/num_inference_steps=20/' \
    -e 's/, high quality, detailed//' \
    -e 's#image.save("image.jpg")#image.save("/work/image.jpg")#' \
    examples/stable_diffusion/model_inference/stable-diffusion-v1-5.py > /work/sd15_cpu.py
# Pre-download models (ModelScope, no auth) into ./models as the pipeline expects
cd /work/DiffSynth-Studio
python - <<'PY'
from modelscope import snapshot_download
snapshot_download("AI-ModelScope/stable-diffusion-v1-5", local_dir="./models/AI-ModelScope/stable-diffusion-v1-5",
    allow_file_pattern=["text_encoder/model.safetensors","unet/diffusion_pytorch_model.safetensors",
                        "vae/diffusion_pytorch_model.safetensors","tokenizer/*"])
PY
