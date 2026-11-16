#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget unzip bzip2 cmake python3-dev libgl1 libglib2.0-0 ca-certificates
cd /work
REPO=/work/Bringing-Old-Photos-Back-to-Life
[ -d "$REPO/.git" ] || git clone https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life "$REPO"
cd "$REPO"
git checkout 33875eccf4ebcd3665cf38cc56f3a0ce563d3a9c

# Synchronized-BatchNorm copies
for d in Face_Enhancement/models/networks Global/detection_models; do
  (cd $d && { [ -d Synchronized-BatchNorm-PyTorch ] || git clone https://github.com/vacancy/Synchronized-BatchNorm-PyTorch; } \
     && cp -rf Synchronized-BatchNorm-PyTorch/sync_batchnorm .)
done

# dlib landmark model
cd Face_Detection
if [ ! -f shape_predictor_68_face_landmarks.dat ]; then
  wget -q http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2
  bzip2 -df shape_predictor_68_face_landmarks.dat.bz2
fi
cd ..

# checkpoints
cd Face_Enhancement
[ -f face_checkpoints.zip ] || wget -q https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life/releases/download/v1.0/face_checkpoints.zip
unzip -oq face_checkpoints.zip
cd ../Global
[ -f global_checkpoints.zip ] || wget -q https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life/releases/download/v1.0/global_checkpoints.zip
unzip -oq global_checkpoints.zip
cd ..

# Patch: newer scikit-image warp(order=0, preserve_range) returns uint8 for a uint8 mask,
# so in-place 'mask *= 255.0' raises a casting error in stage 4 blending.
sed -i 's/^    mask \*= 255.0$/    mask = mask.astype(np.float64) * 255.0/' \
  Face_Detection/align_warp_back_multiple_dlib.py Face_Detection/align_warp_back_multiple_dlib_HR.py

# Python env: torch cu128 wheels needed for Blackwell sm_120
uv venv --clear --python 3.12 /work/venv
source /work/venv/bin/activate
uv pip install torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cu128
# dlib only runs face landmark detection on CPU; avoid a CUDA build (needs cuDNN)
export DLIB_USE_CUDA=0
uv pip install -r requirements.txt
