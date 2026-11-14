#!/usr/bin/env bash
# Reproducible setup for Tencent ML-Images (Python 2.7 + TensorFlow 1.13.2, CPU)
set -euo pipefail
REPO=/work/tencent-ml-images
ENV=/opt/mlimg
MAMBA_ROOT=/opt/mamba
mkdir -p /work && cd /work

# 1. system packages (libglib needed by opencv's cv2.so; unzip for the checkpoint archive)
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends libglib2.0-0t64 unzip bzip2 ca-certificates curl git

# 2. clone
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/Tencent/tencent-ml-images "$REPO"
fi

# 3. Python 2.7 env via micromamba (uv / Ubuntu 24.04 cannot provide Python 2.7)
if [ ! -x "$MAMBA_ROOT/bin/micromamba" ]; then
  mkdir -p "$MAMBA_ROOT"
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C "$MAMBA_ROOT" bin/micromamba
fi
if [ ! -x "$ENV/bin/python2.7" ]; then
  "$MAMBA_ROOT/bin/micromamba" create -y -q -r "$MAMBA_ROOT" -p "$ENV" -c conda-forge python=2.7 pip
fi
# TF 1.13.2: TF>=1.14 makes absl.logging define --log_dir, which clashes with flags.py
"$ENV/bin/pip" install -q --no-cache-dir --prefer-binary \
  tensorflow==1.13.2 numpy==1.16.6 grpcio==1.39.0 h5py==2.10.0 \
  opencv-python-headless==4.1.2.30
# scripts use '#!/usr/bin/python' shebangs
[ -e /usr/bin/python ] || ln -s "$ENV/bin/python" /usr/bin/python

# 4. code patches
cd "$REPO"
# second docstring before 'from __future__' is a SyntaxError
sed -i 's/^"""Use the saved checkpoint to run single-label image classification"""$/# Use the saved checkpoint to run single-label image classification/' image_classification.py
# allow -idx to be a single index file as well as a directory of index files
"$ENV/bin/python" - <<'PY'
p='data/tfrecord.py'
s=open(p).read()
old="  files = os.listdir(args.indexs)\n"
new=("  if os.path.isfile(args.indexs):\n"
     "    files = [os.path.basename(args.indexs)]\n"
     "    args.indexs = os.path.dirname(args.indexs)\n"
     "  else:\n"
     "    files = os.listdir(args.indexs)\n")
if "os.path.isfile(args.indexs)" not in s:
    assert old in s
    open(p,'w').write(s.replace(old,new))
PY
chmod +x example/*.sh data/*.sh data/tfrecord.py

# 5. checkpoint ckpt-resnet101-mlimages-imagenet (README Google Drive link1)
mkdir -p checkpoints
if [ ! -s checkpoints/resnet.ckpt.index ]; then
  DL=$(mktemp -d)
  for i in 1 2 3; do
    curl -fL --retry 3 -o "$DL/ckpt.zip" \
      "https://drive.usercontent.google.com/download?id=1wIhRemoPxTw7uDz-TlwfYJsOR2usb2kg&export=download&confirm=t" && break
    sleep 5
  done
  unzip -q -o "$DL/ckpt.zip" -d "$DL"
  mv "$DL"/ckpt-resnet101-mlimages-imagenet/resnet.ckpt.* checkpoints/
  rm -rf "$DL"
fi
echo "setup done"
