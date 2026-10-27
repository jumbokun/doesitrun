#!/usr/bin/env bash
# Reproduce the NanoJev CUDA inference setup from scratch on a fresh
# Ubuntu 24.04 + CUDA 12.8 devel image (git, git-lfs, curl, build-essential,
# python3, uv already present).  Non-interactive, idempotent, no credentials.
set -euo pipefail

REPO_URL="https://github.com/TianyuCodings/NanoJev.git"
REPO_DIR="/work/NanoJev"
VENV_DIR="/work/venv"
CKPT_DIR="checkpoints/NanoJev-unified"
DATA_DIR="data/NanoJev-unified"
REVISION="unified-games-v1"

export DEBIAN_FRONTEND=noninteractive
# Nothing beyond the base image is strictly required; ca-certificates is
# refreshed so the Hugging Face / PyPI TLS fetches below cannot fail on a
# stale trust store.
# python3-dev matters: triton JIT-compiles a small CUDA shim against Python.h
# the first time a non-`--disable-native-triton` entry point runs, and the base
# image has no headers.  ca-certificates/curl/git are refreshed so the PyPI and
# Hugging Face fetches below cannot fail on a stale trust store.
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq || true
  apt-get install -y -qq --no-install-recommends \
    ca-certificates curl git python3-dev \
    || echo "[setup] WARNING: apt install failed; the documented server command still works"
fi

# ---------------------------------------------------------------- clone ------
if [ -d "$REPO_DIR/.git" ]; then
  echo "[setup] repository already present at $REPO_DIR"
else
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

# ------------------------------------------------------- python env ---------
# README says `python -m pip install -r requirements-toy.txt`, which cannot work
# against Ubuntu 24.04's externally-managed system interpreter (and `python`
# does not exist there).  Same pins, installed into a dedicated venv instead.
if [ ! -x "$VENV_DIR/bin/python" ]; then
  uv venv --python 3.12 "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

uv pip install --python "$VENV_DIR/bin/python" \
  -r requirements-toy.txt huggingface_hub

# requirements-toy.txt pins torch==2.14.0; its default PyPI wheel is the cu13
# build, which ships sm_120 kernels for this Blackwell laptop GPU.
python - <<'PY'
import torch
assert torch.cuda.is_available(), "CUDA is not available to torch"
cap = torch.cuda.get_device_capability(0)
print("[setup] torch", torch.__version__, "cuda", torch.version.cuda,
      "device", torch.cuda.get_device_name(0), "sm_%d%d" % cap)
assert "sm_%d%d" % cap in torch.cuda.get_arch_list(), \
    "installed torch has no kernels for this GPU: %r" % (torch.cuda.get_arch_list(),)
assert torch.cuda.is_bf16_supported(), "checkpoint inference needs bf16"
PY

# -------------------------------------------- model + dataset download ------
# Exactly the Quick start snapshot_download calls, with retries because the
# anonymous Hub endpoint occasionally rate-limits.  Public repos, no token.
python - "$CKPT_DIR" "$DATA_DIR" "$REVISION" <<'PY'
import sys, time
from huggingface_hub import snapshot_download

ckpt_dir, data_dir, revision = sys.argv[1:4]

jobs = [
    dict(repo_id="C-Tianyu/NanoJev", revision=revision, local_dir=ckpt_dir,
         allow_patterns=["best.safetensors", "config.json", "tokenizer/*",
                         "backbone_config/*"]),
    dict(repo_id="C-Tianyu/NanoJev-Data", repo_type="dataset",
         revision=revision, local_dir=data_dir),
]
for job in jobs:
    for attempt in range(1, 6):
        try:
            print("[setup] downloading", job["repo_id"], flush=True)
            print("[setup] ->", snapshot_download(**job), flush=True)
            break
        except Exception as exc:
            print("[setup] attempt %d failed: %s" % (attempt, exc), flush=True)
            if attempt == 5:
                raise
            time.sleep(15 * attempt)
PY

# Fail loudly here rather than at server start if a file is missing.
python - "$CKPT_DIR" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
for rel in ("best.safetensors", "config.json", "tokenizer/tokenizer.json",
            "backbone_config/config.json"):
    p = root / rel
    assert p.is_file() and p.stat().st_size > 0, "missing checkpoint file: %s" % p
print("[setup] checkpoint complete:", root.resolve())
PY

echo "[setup] done. source /work/env.sh, then /work/run.sh"
