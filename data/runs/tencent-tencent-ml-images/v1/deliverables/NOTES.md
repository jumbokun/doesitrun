# tencent-ml-images: data/tfrecord.py

README requires Python 2.7 + TensorFlow >= 1.6 but gives no install instructions.

What broke / what I did:
- Python 2.7 is not available on Ubuntu 24.04 (apt) or via uv -> installed micromamba and created a conda-forge `python=2.7` env at /opt/mamba/envs/py27.
- `pip install tensorflow==1.15.5` has no wheel for this cp27mu interpreter; used tensorflow==1.15.0.
- TF 1.15 pulls latest grpcio, which tries to build from source on py2.7 and fails (Cython 3) -> pinned grpcio==1.39.0 (last py27 wheel), plus numpy==1.16.6, protobuf==3.17.3, h5py==2.10.0, and pip `--prefer-binary`.
- `tfrecord.py` has shebang `#!/usr/bin/python`, which does not exist on Ubuntu 24.04 -> setup.sh symlinks it to the py27 interpreter so `./tfrecord.sh` / `./tfrecord.py` work.
- No code changes. Verified: 4 bundled images -> 0.tfrecords with 4 records (name, JPEG bytes, 11166-float32 label).
- env.sh puts the py27 env first on PATH.
