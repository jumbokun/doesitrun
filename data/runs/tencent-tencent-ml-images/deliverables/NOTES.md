# Tencent ML-Images: setup notes (CPU only)

## What broke when following the README
- **Python 2.7**: neither Ubuntu 24.04 nor uv can provide it. I built a conda-forge Python 2.7.15 env with micromamba at `/opt/mlimg`.
- **TensorFlow version**: with TF 1.15, `flags.py` crashes with `DuplicateFlagError: log_dir` (absl.logging already defines `--log_dir`). I pinned TF **1.13.2**, which still meets the README's ">= 1.6".
- **py2 dependency resolution**: pip tries to build the newest grpcio from source and fails. I pinned `grpcio==1.39.0`, `h5py==2.10.0`, `numpy==1.16.6` and used `--prefer-binary`.
- **OpenCV**: the README never mentions it. I installed `opencv-python-headless==4.1.2.30` (the newest py2 wheel). It needs the system library `libglib2.0-0t64` (for libgthread).
- **`image_classification.py` SyntaxError**: the second docstring comes before `from __future__ import ...`, which isn't allowed. I turned it into a `#` comment.
- **`example/image_classification.sh` isn't executable**, so `./example/...` fails. I ran `chmod +x`.
- **Checkpoint**: the Google Drive link (link1) still works. It's a zip holding `ckpt-resnet101-mlimages-imagenet/resnet.ckpt.{data,index,meta}`. The README only says "move them into checkpoints/". To match `--model_dir=checkpoints/resnet.ckpt`, the `resnet.ckpt.*` files have to sit directly in `checkpoints/`.
- **`data/tfrecord.py`**: `-idx` only accepted a directory (`os.listdir`). I patched it so `-idx` can also be a single index file; directories behave as before. The scripts' `#!/usr/bin/python` shebang points to a file that doesn't exist, so I symlinked `/usr/bin/python` to the env's python.

## Result
- `./example/image_classification.sh` writes the top 5 predictions per image to `label_pred.txt`: daisy, speedboat, parachute, jaguar.
- `tfrecord.py` writes 4 records. Each has the correct name, the original JPEG bytes, and an 11166-dim float32 label vector.
