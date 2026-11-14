#!/usr/bin/env bash
# Reproduce CPU-only setup of HY-World-2.0 WorldMirror 2.0 (worldrecon).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# System libs needed by opencv-python (libGL) and friends
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64 libgomp1

# Clone
if [ ! -d /work/HY-World-2.0/.git ]; then
  git clone https://github.com/Tencent-Hunyuan/HY-World-2.0 /work/HY-World-2.0
fi

# Python 3.11 venv (README uses conda python 3.11)
[ -x /work/venv/bin/python ] || uv venv -p 3.11 /work/venv
source /work/venv/bin/activate

# CPU torch build, then requirements.txt minus cupy (CUDA-only, unused by worldrecon)
uv pip install torch==2.7.1 torchvision==0.22.1 --index-url https://download.pytorch.org/whl/cpu
grep -v '^cupy' /work/HY-World-2.0/requirements.txt > /tmp/hyworld_req_cpu.txt
uv pip install -r /tmp/hyworld_req_cpu.txt \
  --extra-index-url https://download.pytorch.org/whl/cpu --index-strategy unsafe-best-match

# gsplat: the git/source builds need CUDA_HOME + nvcc for a GPU; the PyPI wheel is
# pure-Python (JIT) and imports fine on CPU. Only imported, not used, by the CLI.
uv pip install gsplat

# No flash-attn on CPU: patch attention to fall back to SDPA
mkdir -p /work/patches
cat > /work/patches/cpu_patch.py <<'PYEOF'
"""Apply CPU-compat patches to HY-World-2.0 (idempotent)."""
import sys, pathlib
root = pathlib.Path(sys.argv[1])
p = root / "hyworld2/worldrecon/hyworldmirror/models/layers/attention.py"
s = p.read_text()
old = """try:
    from flash_attn_interface import flash_attn_func as flash_attn_func_v3
    _USE_FLASH_ATTN_V3 = True
except ImportError:
    from flash_attn.flash_attn_interface import flash_attn_func as flash_attn_func_v2
    _USE_FLASH_ATTN_V3 = False
"""
new = """_HAS_FLASH_ATTN = True
try:
    from flash_attn_interface import flash_attn_func as flash_attn_func_v3
    _USE_FLASH_ATTN_V3 = True
except ImportError:
    _USE_FLASH_ATTN_V3 = False
    try:
        from flash_attn.flash_attn_interface import flash_attn_func as flash_attn_func_v2
    except ImportError:
        # CPU / no flash-attn: fall back to F.scaled_dot_product_attention
        _HAS_FLASH_ATTN = False
"""
if old in s:
    s = s.replace(old, new)
    s = s.replace("        if q.dtype==torch.bfloat16 or q.dtype==torch.float16:",
                  "        if _HAS_FLASH_ATTN and q.is_cuda and (q.dtype==torch.bfloat16 or q.dtype==torch.float16):")
    p.write_text(s)
    print("patched", p)
else:
    print("already patched or changed:", p)
PYEOF
python /work/patches/cpu_patch.py /work/HY-World-2.0

# Pre-download WorldMirror 2.0 weights (public, no token)
python -c "from huggingface_hub import snapshot_download; snapshot_download('tencent/HY-World-2.0', allow_patterns=['HY-WorldMirror-2.0/*'])"
# skyseg.onnx is fetched lazily into the CWD; pre-fetch it into the repo root (env.sh cds there)
[ -f /work/HY-World-2.0/skyseg.onnx ] || curl -fsSL -o /work/HY-World-2.0/skyseg.onnx https://huggingface.co/JianyuanWang/skyseg/resolve/main/skyseg.onnx
echo "setup done"
