#!/bin/bash
set -euxo pipefail
cd /work
command -v bzip2 >/dev/null || { apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y bzip2; }
[ -d PocketFlow ] || git clone https://github.com/Tencent/PocketFlow /work/PocketFlow
# Python env: TF 1.x needs an old Python (docs: 3.6 / TF 1.10); uv no longer ships <=3.7,
# so get Python 3.7 from conda-forge via micromamba, then TF 1.15 CPU via pip.
if [ ! -x /work/venv/bin/python ]; then
  mkdir -p /work/.mamba
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C /work/.mamba bin/micromamba
  MAMBA_ROOT_PREFIX=/work/.mamba /work/.mamba/bin/micromamba create -y -p /work/venv -c conda-forge python=3.7 pip
fi
uv pip install --python /work/venv/bin/python \
  "tensorflow==1.15.5" "numpy==1.18.5" "scipy==1.4.1" "pandas==1.1.5" \
  "scikit-learn==0.22.2" "docopt>=0.6.2" "hdfs>=2.1.0" "protobuf==3.20.3"
# CIFAR-10 binary
mkdir -p /work/data
if [ ! -f /work/data/cifar-10-batches-bin/test_batch.bin ]; then
  curl -fL -o /work/data/cifar-10-binary.tar.gz https://www.cs.toronto.edu/~kriz/cifar-10-binary.tar.gz
  tar -xzf /work/data/cifar-10-binary.tar.gz -C /work/data
  rm -f /work/data/cifar-10-binary.tar.gz
fi
# path.conf
cd /work/PocketFlow
sed 's#^data_dir_local_cifar10 = None#data_dir_local_cifar10 = /work/data/cifar-10-batches-bin#' path.conf.template > path.conf
# Code patch: TF >= 1.14 moved tf.contrib.lite to tf.lite (the import breaks every learner)
f=learners/uniform_quantization_tf/utils.py
if grep -q '^from tensorflow.contrib.lite.python import lite_constants' $f; then
  python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("from tensorflow.contrib.lite.python import lite_constants\n",
              "try:\n  from tensorflow.contrib.lite.python import lite_constants\n"
              "except ImportError:  # TF >= 1.14\n  from tensorflow.lite.python import lite_constants\n")
s = s.replace("tf.contrib.lite.TFLiteConverter", "tf.lite.TFLiteConverter")
open(p, 'w').write(s)
PY
fi
# Code patch: absl.logging (imported by TF >= 1.14) already defines --log_dir -> DuplicateFlagError
for f in nets/*_run.py examples/*_run.py; do
  grep -q "absl.logging also defines" $f && continue
  sed -i "s|^tf.app.flags.DEFINE_string('log_dir'|if 'log_dir' in tf.app.flags.FLAGS:  # absl.logging also defines it in TF >= 1.14\n  delattr(tf.app.flags.FLAGS, 'log_dir')\n&|" $f
done
# Code patch: module-level tf.constant lives in the global default graph; TF 1.15's dataset.map
# refuses to capture it from the learner's own tf.Graph -> use numpy constants instead
sed -i 's|^IMAGE_AVE = tf.constant(\(.*\), dtype=tf.float32)|IMAGE_AVE = np.array(\1, dtype=np.float32)|; s|^IMAGE_STD = tf.constant(\(.*\), dtype=tf.float32)|IMAGE_STD = np.array(\1, dtype=np.float32)|' datasets/cifar10_dataset.py
grep -q '^import numpy as np' datasets/cifar10_dataset.py || sed -i 's|^import tensorflow as tf$|import numpy as np\nimport tensorflow as tf|' datasets/cifar10_dataset.py
