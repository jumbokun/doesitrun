#!/usr/bin/env bash
# Reproduce the whole Kev setup from scratch on a fresh container.
# Image assumed: Ubuntu 24.04 + CUDA 12.8 devel, with git, git-lfs, curl,
# build-essential, python3 and uv already present.
#
# Target: Kev-0.8B served on an 8 GB NVIDIA RTX 5060 Laptop GPU (Blackwell,
# sm_120) in bf16 on port 8009.
set -euo pipefail

REPO_URL=https://github.com/jaredpalmer/kev.git
REPO_DIR=/work/kev
RUN=jaredpalmer/kev-0.8b
BASE=Qwen/Qwen3.5-0.8B-Base
# Base revision pinned by the checkpoint's training_config.json / provenance.json.
BASE_REVISION=dc7cdfe2ee4154fa7e30f5b51ca41bfa40174e68

export HF_HOME=/work/hf-cache
export HF_HUB_DISABLE_PROGRESS_BARS=1
export DEBIAN_FRONTEND=noninteractive

echo "== 1/4 system packages"
# Nothing the base image lacks is strictly required; keep the list minimal and
# tolerate a container with no apt mirrors reachable.
if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq --no-install-recommends \
        ca-certificates git git-lfs curl build-essential || \
        echo "   apt-get failed; continuing with the preinstalled packages"
fi

echo "== 2/4 clone $REPO_URL -> $REPO_DIR"
if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" fetch --quiet origin
    git -C "$REPO_DIR" checkout --quiet main
else
    git clone --quiet "$REPO_URL" "$REPO_DIR"
fi

echo "== 3/4 python environment (uv sync --extra serve)"
cd "$REPO_DIR"
# .python-version pins 3.13; uv downloads that interpreter itself.
# The lock resolves torch 2.8.0, whose PyPI wheel is the cu128 build and the
# first one that ships sm_120 kernels for this Blackwell GPU.
uv sync --extra serve
uv run python - <<'PY'
import torch
assert torch.cuda.is_available(), "torch cannot see the GPU"
cap = torch.cuda.get_device_capability(0)
arch = f"sm_{cap[0]}{cap[1]}"
assert arch in torch.cuda.get_arch_list(), f"{arch} missing from {torch.cuda.get_arch_list()}"
a = torch.randn(512, 512, device="cuda", dtype=torch.bfloat16)
_ = (a @ a).sum().item()
print(f"   torch {torch.__version__} ok on {torch.cuda.get_device_name(0)} ({arch})")
PY

echo "== 4/4 weights: $RUN adapter + $BASE base into $HF_HOME"
# Pre-pull so the first server start does not wait on the Hub. Public repos,
# no token needed.
uv run python - "$RUN" "$BASE" "$BASE_REVISION" <<'PY'
import sys
from huggingface_hub import snapshot_download

run, base, base_revision = sys.argv[1], sys.argv[2], sys.argv[3]
for repo, revision in ((run, None), (base, base_revision)):
    path = snapshot_download(repo_id=repo, revision=revision)
    print(f"   {repo}{'@' + revision[:8] if revision else ''} -> {path}")
PY

echo
echo "setup.sh done. Next: source /work/env.sh && /work/run.sh"
