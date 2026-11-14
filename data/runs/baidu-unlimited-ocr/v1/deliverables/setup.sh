#!/usr/bin/env bash
# Reproduce the CPU-only Transformers setup for baidu/Unlimited-OCR (model baidu/Unlimited-OCR-2).
set -euo pipefail
cd /work
export HF_HOME="${HF_HOME:-/root/.cache/huggingface}"

if [ ! -d Unlimited-OCR/.git ]; then
  git clone https://github.com/baidu/Unlimited-OCR /work/Unlimited-OCR
fi

# README: Python 3.10 + pinned deps; torch from the CPU wheel index (no GPU here)
[ -x .venv/bin/python ] || uv venv --python 3.10 /work/.venv
uv pip install --python /work/.venv/bin/python \
  --index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple \
  --index-strategy unsafe-best-match \
  torch==2.13.0 torchvision pillow transformers==4.52.1 huggingface-hub==0.36.0 \
  tokenizers==0.21.4 addict==2.4.0 einops==0.8.2 easydict==1.13
# The remote code imports triton at module level (transformers' check_imports fails without it);
# kernels are only used for CUDA tensors, so the plain wheel is enough on CPU.
uv pip install --python /work/.venv/bin/python triton==3.8.0

# Download the model at a fixed revision, then patch its remote code for CPU / fp32
mkdir -p /work/patches
cat > /work/patches/patch_cpu.py <<'PYEOF'
"""Make baidu/Unlimited-OCR-2 remote code run on CPU / non-bf16 dtypes.
Patches the files inside the HF hub snapshot (replacing blob symlinks with real files)."""
import os, sys, shutil, glob
from huggingface_hub import snapshot_download

snap = snapshot_download("baidu/Unlimited-OCR-2", revision="90a9c06e034b9d0486f83b30265da9d8155e1a1b")
REPL = {
    "modeling_unlimitedocr.py": [
        # vision features were scattered with a hardcoded .cuda() mask
        ("images_seq_mask[idx].unsqueeze(-1).cuda()", "images_seq_mask[idx].unsqueeze(-1).to(inputs_embeds.device)"),
        ("images_seq_mask[0].unsqueeze(-1).cuda()", "images_seq_mask[0].unsqueeze(-1).to(inputs_embeds.device)"),
        # image tensors are hardcoded to bf16; cast to the model's dtype instead
        ("images=[(imgs[0].to(device), imgs[1].to(device), spatial)]",
         "images=[(imgs[0].to(device=device, dtype=self.lm_head.weight.dtype), imgs[1].to(device=device, dtype=self.lm_head.weight.dtype), spatial)]"),
    ],
}
for fname, reps in REPL.items():
    p = os.path.join(snap, fname)
    src = open(p, encoding="utf-8").read()
    for old, new in reps:
        if new in src:
            continue
        if old not in src:
            sys.exit(f"patch anchor not found in {fname}: {old}")
        src = src.replace(old, new)
    if os.path.islink(p):
        os.unlink(p)
    with open(p, "w", encoding="utf-8") as f:
        f.write(src)
    print("patched", p)
# drop stale copies in the dynamic-module cache so the patched files get re-copied
hf_home = os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface"))
for d in glob.glob(os.path.join(hf_home, "modules", "transformers_modules", "*Unlimited*OCR*2*")) + \
         glob.glob(os.path.join(hf_home, "modules", "transformers_modules", "baidu", "Unlimited-OCR-2")):
    shutil.rmtree(d, ignore_errors=True)
PYEOF
/work/.venv/bin/python -I -c "from huggingface_hub import snapshot_download; snapshot_download('baidu/Unlimited-OCR-2', revision='90a9c06e034b9d0486f83b30265da9d8155e1a1b')"
/work/.venv/bin/python -I /work/patches/patch_cpu.py
# offline loading (HF_HUB_OFFLINE=1 in env.sh) resolves "main" via refs/main; pinned downloads don't write it
REPO_CACHE="$HF_HOME/hub/models--baidu--Unlimited-OCR-2"
mkdir -p "$REPO_CACHE/refs"
printf '%s' 90a9c06e034b9d0486f83b30265da9d8155e1a1b > "$REPO_CACHE/refs/main"
echo "setup done"
