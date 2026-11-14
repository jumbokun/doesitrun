#!/usr/bin/env bash
# Reproduce the CPU-only Transformers setup for baidu/Unlimited-OCR (model: baidu/Unlimited-OCR-2).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
export HF_HOME=/root/.cache/huggingface
MODEL_REV=0480966938291445591f69f08a13b041c073a96a
cd /work

# 1. repo (large PDFs in LFS are not needed for inference)
if [ ! -d /work/Unlimited-OCR/.git ]; then
  GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/baidu/Unlimited-OCR /work/Unlimited-OCR
fi

# 2. python env (README: Python 3.10 + pinned versions); torch from the CPU wheel index
[ -x /work/.venv/bin/python ] || uv venv --python 3.10 /work/.venv
source /work/.venv/bin/activate
uv pip install --index-url https://download.pytorch.org/whl/cpu torch==2.13.0 torchvision
uv pip install pillow transformers==4.52.1 huggingface-hub==0.36.0 \
  tokenizers==0.21.4 addict==2.4.0 einops==0.8.2 easydict==1.13
# remote code imports triton unconditionally (transformers check_imports); not in README
uv pip install triton==3.7.1

# 3. model weights + remote code, pinned to the revision the patches were written against
python - <<PY
from huggingface_hub import snapshot_download
p = snapshot_download("baidu/Unlimited-OCR-2", revision="$MODEL_REV")
print(p)
PY
mkdir -p $HF_HOME/hub/models--baidu--Unlimited-OCR-2/refs
echo -n "$MODEL_REV" > $HF_HOME/hub/models--baidu--Unlimited-OCR-2/refs/main

# 4. CPU / float32 patches for the remote modeling code
mkdir -p /work/patches
cat > /work/patches/patch_model.py <<'PATCH_EOF'
"""Make baidu/Unlimited-OCR-2 remote code run on CPU / float32.
Usage: python patch_model.py <snapshot_dir>. Idempotent."""
import os, sys

SNAP = sys.argv[1]

PATCHES = {
    "deepencoder.py": [
        # SAM global attention materialises a full (B, heads, 4096, 4096) rel-pos bias plus the
        # score matrix; on CPU in fp32 that OOMs a 16 GB box next to the 12 GB of weights.
        # Compute it in query chunks instead (numerically identical).
        ("""            attn_bias = (rel_h + rel_w).view(B, self.num_heads, rel_h.size(2), rel_h.size(3) * rel_w.size(4))
            x = torch.nn.functional.scaled_dot_product_attention(q, k, v, attn_mask=attn_bias)""",
         """            _chunk = 512
            x = torch.empty_like(q)
            for _b in range(B):
                for _s in range(0, q.size(2), _chunk):
                    _e = min(_s + _chunk, q.size(2))
                    _bias = (rel_h[_b:_b + 1, :, _s:_e] + rel_w[_b:_b + 1, :, _s:_e]).reshape(
                        1, self.num_heads, _e - _s, rel_h.size(3) * rel_w.size(4))
                    x[_b:_b + 1, :, _s:_e] = torch.nn.functional.scaled_dot_product_attention(
                        q[_b:_b + 1, :, _s:_e], k[_b:_b + 1], v[_b:_b + 1], attn_mask=_bias)
                    del _bias"""),
    ],
    "modeling_unlimitedocr.py": [
        # images are hard-cast to bf16; cast them to the model dtype instead
        ("kw = dict(images=[(imgs[0].to(device), imgs[1].to(device), spatial)],",
         "kw = dict(images=[(imgs[0].to(device, dtype=self.lm_head.weight.dtype), imgs[1].to(device, dtype=self.lm_head.weight.dtype), spatial)],"),
        # hard-coded .cuda()
        ("images_seq_mask[idx].unsqueeze(-1).cuda()", "images_seq_mask[idx].unsqueeze(-1).to(inputs_embeds.device)"),
        ("images_seq_mask[0].unsqueeze(-1).cuda()", "images_seq_mask[0].unsqueeze(-1).to(inputs_embeds.device)"),
    ],
}

for fname, subs in PATCHES.items():
    path = os.path.join(SNAP, fname)
    real = os.path.realpath(path)
    src = open(real, encoding="utf-8").read()
    for old, new in subs:
        if new in src:
            continue
        if old not in src:
            sys.exit(f"patch anchor not found in {fname}: {old[:60]}")
        src = src.replace(old, new)
    # replace the symlink with a real patched file so the blob store stays pristine
    if os.path.islink(path):
        os.unlink(path)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print("patched", fname)

# transformers never refreshes an already-copied module for a given commit hash
import shutil
mod = os.path.join(os.environ.get("HF_HOME", os.path.expanduser("~/.cache/huggingface")),
                   "modules", "transformers_modules", "baidu", "Unlimited-OCR-2")
shutil.rmtree(mod, ignore_errors=True)
PATCH_EOF
python /work/patches/patch_model.py $HF_HOME/hub/models--baidu--Unlimited-OCR-2/snapshots/$MODEL_REV
echo "setup done"
