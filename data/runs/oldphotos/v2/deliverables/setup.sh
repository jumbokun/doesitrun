#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
REPO=/work/Bringing-Old-Photos-Back-to-Life
apt-get update
apt-get install -y --no-install-recommends python3-dev wget unzip bzip2 cmake libgl1 libglib2.0-0 libopenblas-dev liblapack-dev
mkdir -p /work && cd /work
[ -d "$REPO/.git" ] || git clone https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life "$REPO"
cd "$REPO"
# Synchronized-BatchNorm copies
for d in Face_Enhancement/models/networks Global/detection_models; do
  ( cd $d
    [ -d Synchronized-BatchNorm-PyTorch ] || git clone https://github.com/vacancy/Synchronized-BatchNorm-PyTorch
    cp -rf Synchronized-BatchNorm-PyTorch/sync_batchnorm . )
done
# dlib landmark model
( cd Face_Detection
  if [ ! -f shape_predictor_68_face_landmarks.dat ]; then
    wget -q -O shape_predictor_68_face_landmarks.dat.bz2 http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2
    bzip2 -df shape_predictor_68_face_landmarks.dat.bz2
  fi )
# checkpoints
( cd Face_Enhancement
  wget -q -c https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life/releases/download/v1.0/face_checkpoints.zip
  unzip -oq face_checkpoints.zip )
( cd Global
  wget -q -c https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life/releases/download/v1.0/global_checkpoints.zip
  unzip -oq global_checkpoints.zip )
# Python env
[ -d /work/venv ] || uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
uv pip install dlib scikit-image easydict PyYAML "dominate>=2.3.1" dill tensorboardX scipy opencv-python einops matplotlib
