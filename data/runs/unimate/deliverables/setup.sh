#!/usr/bin/env bash
# Reproduce the UniMate inference setup from scratch on a fresh sandbox
# (Ubuntu 24.04 + CUDA 12.8 devel, git/git-lfs/curl/build-essential/python3/uv).
# Covers: clone, system packages, Python env, checkpoint + text-encoder download.
# The 88 GB UniML3D dataset is NOT downloaded; it is not needed to animate a
# rig_preprocess asset such as assets/examples/unitree_go2.
set -euo pipefail

REPO_DIR=/work/UniMate
VENV_DIR=/work/venv
export HF_HOME=/work/hf_cache
export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 1. System packages
# ---------------------------------------------------------------------------
# Nothing beyond the base image is strictly required for text-to-motion
# inference: the mp4 writer comes from the imageio-ffmpeg wheel's bundled
# ffmpeg. ffmpeg/libgl are installed anyway so matplotlib/imageio have a
# system fallback, and are skipped silently if apt is unavailable.
apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    ffmpeg libgl1 libglib2.0-0 ca-certificates || \
    echo "WARN: apt step skipped; continuing (not required for inference)"

# ---------------------------------------------------------------------------
# 2. Clone
# ---------------------------------------------------------------------------
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone https://github.com/Friedrich-M/UniMate "$REPO_DIR"
fi
cd "$REPO_DIR"

# ---------------------------------------------------------------------------
# 3. Python environment
# ---------------------------------------------------------------------------
# requirements.txt targets conda + Python 3.10 / CUDA 12.4. We keep Python
# 3.10 and every library pin, but install PyTorch from the cu128 index:
# torch 2.5.1+cu124 has no sm_120 kernels, so it cannot run on this RTX 5060
# (Blackwell). See NOTES.md.
rm -rf "$VENV_DIR"
uv venv --python 3.10 "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# setuptools < 81 keeps pkg_resources available for the Motion build below
# (requirements.txt's own instruction), and must not be upgraded afterwards.
uv pip install --quiet "setuptools<81" wheel

# PyTorch for Blackwell (sm_120).
uv pip install --quiet torch==2.8.0 torchvision==0.23.0 \
    --index-url https://download.pytorch.org/whl/cu128

# Everything the inference path imports, at requirements.txt's pins.
uv pip install --quiet \
    "numpy==2.2.6" \
    "torch-geometric==2.7.0" \
    "torchdiffeq==0.2.5" \
    "einops==0.8.2" \
    "accelerate==1.14.0" \
    "tensorboard==2.20.0" \
    "transformers==5.16.1" \
    "sentencepiece==0.2.1" \
    "spacy>=3.8,<3.9" \
    "num2words==0.5.14" \
    "huggingface_hub==1.29.0" \
    "matplotlib==3.10.8" \
    "imageio==2.37.3" \
    "imageio-ffmpeg==0.6.0" \
    "pillow==12.2.0" \
    "tyro==1.0.12" \
    "rich==14.3.3" \
    "loguru==0.7.3" \
    "tqdm==4.67.3"

# spaCy model (T5 text normalization), pinned wheel as in requirements.txt.
uv pip install --quiet \
    "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"

# Holden-style Animation / Quaternions, used by the motion feature code.
# Legacy setup.py imports pkg_resources -> must build without isolation.
uv pip install --quiet --no-build-isolation "Motion @ git+https://github.com/inbar-2344/Motion.git"

# ---------------------------------------------------------------------------
# 4. Released checkpoint (README "Inference" step 1)
# ---------------------------------------------------------------------------
hf download Linzhan/UniMate --repo-type model --local-dir outputs \
    --include "unimate_uniml3d_f60_v3/*.json" --include "unimate_uniml3d_f60_v3/*.npy" \
    --include "unimate_uniml3d_f60_v3/checkpoints/checkpoint_step_150000.pt"

test -f outputs/unimate_uniml3d_f60_v3/config.json
test -f outputs/unimate_uniml3d_f60_v3/dataset_stats.npy
test -f outputs/unimate_uniml3d_f60_v3/checkpoints/checkpoint_step_150000.pt

# ---------------------------------------------------------------------------
# 5. Text encoder named by the checkpoint's config (model.text_encoder_version)
# ---------------------------------------------------------------------------
# Pre-fetched into HF_HOME so inference does not depend on a live download.
TEXT_ENCODER=$(python - <<'PY'
import json
print(json.load(open("outputs/unimate_uniml3d_f60_v3/config.json"))["model"]["text_encoder_version"])
PY
)
echo "Pre-downloading text encoder: $TEXT_ENCODER"
hf download "$TEXT_ENCODER" --repo-type model \
    --include "config.json" --include "*.model" --include "tokenizer*" \
    --include "spiece.model" --include "special_tokens_map.json" \
    --include "model.safetensors" --include "generation_config.json"

echo "Setup complete. Source /work/env.sh, then from $REPO_DIR run:"
echo "  python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 \\"
echo "      --asset assets/examples/unitree_go2 --prompt \"An object trots forward.\" --output_dir outputs/samples/custom"
