#!/usr/bin/env bash
# Reproducible setup for the yolov7 README image demo on an RTX 5060 (Blackwell, sm_120).
# Run as root on a fresh Ubuntu 24.04 + CUDA 12.8 devel image (git, git-lfs, curl,
# build-essential, python3, uv preinstalled).
set -euo pipefail

REPO_DIR=/work/yolov7
VENV_DIR=/work/venv
REPO_URL=https://github.com/WongKinYiu/yolov7
REPO_SHA=a207844b1ce82d204ab36d87d496728d3d2348e7
WEIGHTS_URL=https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7.pt
WEIGHTS_SHA256=d1ac3c74eb96a3eec77949c0f37a06bc272756606ff011d9353f7abff4e0c71d

# ---------------------------------------------------------------- system packages
# opencv-python (pinned by requirements.txt) needs libGL/glib at import time; the
# README's docker recipe installs libgl1-mesa-glx, which no longer exists on 24.04.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends libgl1 libglib2.0-0t64

# ---------------------------------------------------------------- source checkout
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch --depth 1 origin "$REPO_SHA" 2>/dev/null || git fetch origin || true
git checkout -q "$REPO_SHA"

# ---------------------------------------------------------------- python env
# Python 3.11: yolov7 is a 2022 codebase, and 3.11 is the newest interpreter with
# wheels for every pinned dependency here (incl. numpy 1.x, required because the
# repo still calls removed numpy-1 APIs such as np.int).
uv venv --python 3.11 "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

# requirements.txt asks for torch>=1.7; no such torch knows about sm_120, so the
# demo would die with "no kernel image is available for execution on the device".
# Blackwell needs a cu128 build -> torch 2.11.0+cu128.
uv pip install --index-url https://download.pytorch.org/whl/cu128 \
  "torch==2.11.0+cu128" "torchvision==0.26.0+cu128"

# Remaining requirements.txt entries, pinned to what was verified.
uv pip install \
  "numpy==1.26.4" \
  "matplotlib==3.11.2" \
  "opencv-python==4.11.0.86" \
  "pillow==12.3.0" \
  "pyyaml==6.0.3" \
  "requests==2.34.2" \
  "scipy==1.17.1" \
  "tqdm==4.70.1" \
  "protobuf==4.21.2" \
  "tensorboard==2.20.0" \
  "pandas==3.0.6" \
  "seaborn==0.13.2" \
  "ipython==9.17.1" \
  "psutil==7.2.2" \
  "thop==0.1.1.post2209072238"

# ---------------------------------------------------------------- source patches
# torch >= 2.6 defaults torch.load(weights_only=True), which refuses yolov7.pt
# (it pickles models.yolo.Model). The checkpoint is the official release asset,
# so load it with weights_only=False. Idempotent.
python - <<'PY'
import pathlib
edits = {
    "models/experimental.py": [
        ("ckpt = torch.load(w, map_location=map_location)  # load",
         "ckpt = torch.load(w, map_location=map_location, weights_only=False)  # load"),
    ],
    "utils/general.py": [
        ("x = torch.load(f, map_location=torch.device('cpu'))",
         "x = torch.load(f, map_location=torch.device('cpu'), weights_only=False)"),
    ],
    "utils/datasets.py": [
        ("cache, exists = torch.load(cache_path), True  # load",
         "cache, exists = torch.load(cache_path, weights_only=False), True  # load"),
    ],
}
for rel, subs in edits.items():
    p = pathlib.Path(rel)
    text = p.read_text()
    for old, new in subs:
        if new in text:
            continue
        assert old in text, f"{rel}: pattern not found: {old}"
        text = text.replace(old, new)
    p.write_text(text)
    print("patched", rel)
PY

# ---------------------------------------------------------------- weights
if [ ! -f yolov7.pt ] || ! echo "$WEIGHTS_SHA256  yolov7.pt" | sha256sum -c --status; then
  curl -fL --retry 5 --retry-delay 5 -o yolov7.pt "$WEIGHTS_URL"
  echo "$WEIGHTS_SHA256  yolov7.pt" | sha256sum -c -
fi

# ---------------------------------------------------------------- smoke test
log=$(mktemp)
ok=0
for attempt in 1 2 3; do
  if python detect.py --weights yolov7.pt --conf 0.25 --img-size 640 \
       --source inference/images/horses.jpg --device 0 2>&1 | tee "$log"; then
    if grep -q "horses" "$log"; then ok=1; break; fi
  fi
  echo "smoke test attempt $attempt failed (possible CUDA OOM); retrying in 30s"
  sleep 30
done
[ "$ok" = 1 ] || { echo "SETUP FAILED: detect.py did not report horse detections"; exit 1; }

# leave a clean output tree so the next detect.py run writes runs/detect/exp
rm -rf runs/detect
echo "setup.sh OK"
