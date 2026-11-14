#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
# opencv (pulled by controlnet_aux) needs these shared libs
apt-get update -qq && apt-get install -y -qq libgl1 libglib2.0-0 libxcb1 >/dev/null
cd /work
[ -d T2I-Adapter/.git ] || git clone https://github.com/TencentARC/T2I-Adapter /work/T2I-Adapter
export HF_HOME=/work/hf_cache
[ -x /work/venv/bin/python ] || uv venv -p 3.12 /work/venv
. /work/venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.8.0 torchvision==0.23.0
# keep the CPU torch build when installing the rest (controlnet_aux would otherwise pull CUDA torch)
printf 'torch==2.8.0\ntorchvision==0.23.0\n' > /work/constraints.txt
uv pip install -c /work/constraints.txt --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match \
  "controlnet_aux==0.0.7" "diffusers==0.35.2" "transformers==4.57.1" "accelerate==1.10.1" "safetensors==0.6.2" \
  "huggingface_hub>=0.34,<1.0" pillow numpy hf_transfer
export HF_HUB_ENABLE_HF_TRANSFER=1
# pre-download only the weights the pipeline needs (fp16 variant as in README)
hf download TencentARC/t2i-adapter-lineart-sdxl-1.0
hf download madebyollin/sdxl-vae-fp16-fix config.json diffusion_pytorch_model.safetensors
hf download stabilityai/stable-diffusion-xl-base-1.0 model_index.json \
  scheduler/scheduler_config.json \
  tokenizer/merges.txt tokenizer/special_tokens_map.json tokenizer/tokenizer_config.json tokenizer/vocab.json \
  tokenizer_2/merges.txt tokenizer_2/special_tokens_map.json tokenizer_2/tokenizer_config.json tokenizer_2/vocab.json \
  text_encoder/config.json text_encoder/model.fp16.safetensors \
  text_encoder_2/config.json text_encoder_2/model.fp16.safetensors \
  unet/config.json unet/diffusion_pytorch_model.fp16.safetensors \
  vae/config.json vae/diffusion_pytorch_model.fp16.safetensors
# lineart detector weights used by the README (controlnet_aux LineartDetector)
hf download lllyasviel/Annotators sk_model.pth sk_model2.pth
# fp32 (non-variant) weights too, in case the pipeline is loaded without variant="fp16"
hf download stabilityai/stable-diffusion-xl-base-1.0 text_encoder/model.safetensors \
  text_encoder_2/model.safetensors unet/diffusion_pytorch_model.safetensors vae/diffusion_pytorch_model.safetensors
echo "setup done"
