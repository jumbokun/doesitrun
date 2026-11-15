#!/usr/bin/env bash
# Reproducible setup for microsoft/Bringing-Old-Photos-Back-to-Life
# Target: fresh Ubuntu 24.04 + CUDA 12.8 devel image, run as root.
# Follows the README "Installation" section; deviations are marked [DEVIATION].
set -euo pipefail

REPO_DIR=/work/Bringing-Old-Photos-Back-to-Life
REPO_URL=https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life
VENV=/work/venv
export DEBIAN_FRONTEND=noninteractive
export UV_HTTP_TIMEOUT=600   # [DEVIATION] torch/CUDA wheels exceed uv's 30s default timeout

dl() {  # dl <url> <outfile>
  wget -q --tries=5 --timeout=60 --continue -O "$2" "$1"
}

### 0. System packages ########################################################
# python3-dev: dlib has no wheel for cp312, it is compiled from source and needs
#              the CPython headers (cmake fails on missing /usr/include/python3.12).
# libgl1 / libglib2.0-0: runtime deps of opencv-python.
apt-get update -qq
apt-get install -y -qq \
  wget unzip bzip2 cmake python3-dev libgl1 libglib2.0-0 libgtk2.0-dev

### 1. Clone the project ######################################################
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone --quiet "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"

### 2. Synchronized-BatchNorm-PyTorch copies (README step 1) ##################
sync_bn() {  # sync_bn <dest dir>
  local d="$1"
  [ -d "$d/sync_batchnorm" ] && return 0
  ( cd "$d"
    [ -d Synchronized-BatchNorm-PyTorch ] || \
      git clone --quiet https://github.com/vacancy/Synchronized-BatchNorm-PyTorch
    cp -rf Synchronized-BatchNorm-PyTorch/sync_batchnorm . )
}
sync_bn "$REPO_DIR/Face_Enhancement/models/networks"
sync_bn "$REPO_DIR/Global/detection_models"

### 3. dlib landmark model (README step 2) ####################################
if [ ! -f "$REPO_DIR/Face_Detection/shape_predictor_68_face_landmarks.dat" ]; then
  cd "$REPO_DIR/Face_Detection"
  dl http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2 \
     shape_predictor_68_face_landmarks.dat.bz2
  bzip2 -d -f shape_predictor_68_face_landmarks.dat.bz2
fi

### 4. Pretrained checkpoints (README step 3) #################################
if [ ! -d "$REPO_DIR/Face_Enhancement/checkpoints" ]; then
  cd "$REPO_DIR/Face_Enhancement"
  dl "$REPO_URL/releases/download/v1.0/face_checkpoints.zip" face_checkpoints.zip
  unzip -q -o face_checkpoints.zip
fi
if [ ! -d "$REPO_DIR/Global/checkpoints" ]; then
  cd "$REPO_DIR/Global"
  dl "$REPO_URL/releases/download/v1.0/global_checkpoints.zip" global_checkpoints.zip
  unzip -q -o global_checkpoints.zip
fi
test -f "$REPO_DIR/Face_Enhancement/checkpoints/Setting_9_epoch_100/latest_net_G.pth"
test -f "$REPO_DIR/Global/checkpoints/detection/FT_Epoch_latest.pt"
test -d "$REPO_DIR/Global/checkpoints/restoration/mapping_scratch"

### 5. Source patch: stage 4 blending vs. modern scikit-image #################
# [DEVIATION] skimage >= 0.20 keeps the input dtype for warp(..., preserve_range=True),
# so the warped mask arrives as uint8 and the in-place `mask *= 255.0` raises
# UFuncOutputCastingError, killing stage 4 (face blending). Cast to float first.
cd "$REPO_DIR"
for f in Face_Detection/align_warp_back_multiple_dlib.py \
         Face_Detection/align_warp_back_multiple_dlib_HR.py; do
  sed -i 's/^    mask \*= 255\.0$/    mask = mask.astype(np.float64) * 255.0  # skimage>=0.20 warp(preserve_range=True) keeps uint8 dtype/' "$f"
  grep -q 'mask.astype(np.float64) \* 255.0' "$f"
done

### 6. Python environment #####################################################
# [DEVIATION] requirements.txt is unpinned and predates this GPU: the RTX 5060
# (Blackwell, sm_120) needs a CUDA 12.8 build of torch, so torch/torchvision come
# from the cu128 index instead of PyPI.
uv venv --python 3.12 "$VENV"
uv pip install --python "$VENV/bin/python" \
  --index-url https://download.pytorch.org/whl/cu128 \
  torch==2.11.0+cu128 torchvision==0.26.0+cu128

# [DEVIATION] numpy is pinned <2 because this 2020 code relies on numpy 1.x
# behaviour, and PySimpleGUI is dropped from requirements.txt because it is no
# longer installable from PyPI (license-gated) and is only used by GUI.py, which
# the full pipeline never imports.
uv pip install --python "$VENV/bin/python" \
  numpy==1.26.4 \
  dlib==20.0.1 \
  scikit-image==0.26.0 \
  easydict==1.13 \
  PyYAML==6.0.3 \
  dominate==2.9.1 \
  dill==0.4.1 \
  tensorboardX==2.6.5 \
  scipy==1.17.1 \
  opencv-python==4.11.0.86 \
  einops==0.8.2 \
  matplotlib==3.11.2

### 7. Smoke check ############################################################
"$VENV/bin/python" - <<'PY'
import torch, cv2, skimage, dlib, numpy
assert torch.cuda.is_available(), "CUDA not available"
print("torch", torch.__version__, "sm", torch.cuda.get_device_capability(),
      "| numpy", numpy.__version__, "| skimage", skimage.__version__)
PY

echo "Setup complete. Source /work/env.sh, then run run.py from $REPO_DIR"
