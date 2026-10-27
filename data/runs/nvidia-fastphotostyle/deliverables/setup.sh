#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export UV_HTTP_TIMEOUT=300 UV_HTTP_RETRIES=5

retry() { local n=0; until "$@"; do n=$((n+1)); [ $n -ge 5 ] && return 1; echo "retry $n: $*"; sleep $((n*10)); done; }

mkdir -p /work && cd /work
if [ ! -d /work/FastPhotoStyle/.git ]; then
  rm -rf /work/FastPhotoStyle
  retry git clone https://github.com/NVIDIA/FastPhotoStyle /work/FastPhotoStyle
fi
cd /work/FastPhotoStyle
git lfs pull 2>/dev/null || true
# bundled model must be a real file (not an LFS pointer)
test "$(stat -c %s PhotoWCTModels/photo_wct.pth)" -gt 1000000

retry apt-get update -y
retry apt-get install -y --no-install-recommends libgl1 libglib2.0-0

[ -x /work/venv/bin/python ] || uv venv --python 3.12 /work/venv
retry uv pip install --python /work/venv/bin/python \
  --index-url https://download.pytorch.org/whl/cpu torch==2.5.1 torchvision==0.20.1
retry uv pip install --python /work/venv/bin/python \
  "numpy<2.3" scipy pillow opencv-contrib-python-headless==4.10.0.84

# CPU-compat source patches (idempotent)
mkdir -p /work/tools
cat > /work/tools/patch_cpu.py <<'PYEOF'
"""Idempotent CPU-compat patches for FastPhotoStyle. Usage: python patch_cpu.py REPO_DIR"""
import sys, os
repo = sys.argv[1]

def edit(fn, old, new):
    p = os.path.join(repo, fn)
    s = open(p).read()
    if old not in s:
        assert new in s, (fn, old)
        return
    open(p, 'w').write(s.replace(old, new, 1))

# 1. cupy/pynvrtc imported at module load -> import lazily (only needed for GPU post-processing)
edit('smooth_filter.py',
     "from cupy.cuda import function\nfrom pynvrtc.compiler import Program\n", "")
edit('smooth_filter.py',
     "def smooth_local_affine(output_cpu, input_cpu, epsilon, patch, h, w, f_r, f_e):\n",
     "def smooth_local_affine(output_cpu, input_cpu, epsilon, patch, h, w, f_r, f_e):\n"
     "    from cupy.cuda import function\n    from pynvrtc.compiler import Program\n")

# 2. load checkpoint on CPU
edit('demo.py', "torch.load(args.model))", "torch.load(args.model, map_location='cpu'))")

# 3. output size: images are resized in place before cw/ch are read, so output never got
#    restored to content size; record original size and resize final output back.
edit('process_stylization.py',
     "        new_cw, new_ch = memory_limit_image_resize(cont_img)\n",
     "        orig_cw, orig_ch = cont_img.width, cont_img.height\n"
     "        new_cw, new_ch = memory_limit_image_resize(cont_img)\n")
edit('process_stylization.py',
     "                    out_img = smooth_filter(out_img, cont_pilimg, f_radius=15, f_edge=1e-1)\n            out_img.save(output_image_path)\n",
     "                    out_img = smooth_filter(out_img, cont_pilimg, f_radius=15, f_edge=1e-1)\n"
     "            if out_img.size != (orig_cw, orig_ch):\n"
     "                out_img = out_img.resize((orig_cw, orig_ch), Image.BICUBIC)\n"
     "            out_img.save(output_image_path)\n")
# deprecated API
edit('process_stylization.py', "nn.functional.upsample(stylized_img", "nn.functional.interpolate(stylized_img")
edit('process_stylization.py', "nn.functional.upsample(stylized_img", "nn.functional.interpolate(stylized_img")
print("patched")
PYEOF
/work/venv/bin/python -I /work/tools/patch_cpu.py /work/FastPhotoStyle

/work/venv/bin/python -c "import torch, cv2, cv2.ximgproc, scipy; print('torch', torch.__version__, 'cv2', cv2.__version__)"
echo "setup complete"
