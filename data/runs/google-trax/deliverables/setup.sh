#!/usr/bin/env bash
# Reproduce the trax CPU setup from scratch. Run as root on a fresh sandbox.
set -euo pipefail
cd /work

# 1. Clone (pinned to the commit that was tested).
if [ ! -d /work/trax/.git ]; then
  git clone https://github.com/google/trax /work/trax
fi
git -C /work/trax checkout -q 31022d6cd7dd525ed11a04d84cd3936228499173

# 2. Patch: tf.estimator was removed in TensorFlow 2.16; trax only uses its ModeKeys strings.
if ! grep -q "tf.estimator was removed" /work/trax/trax/data/tf_inputs.py; then
  python3 - <<'PY'
p = '/work/trax/trax/data/tf_inputs.py'
s = open(p).read()
s = s.replace("from tensorflow import estimator as tf_estimator\n", """try:
  from tensorflow import estimator as tf_estimator
except ImportError:  # tf.estimator was removed in TensorFlow 2.16.
  class tf_estimator:  # pylint: disable=invalid-name
    class ModeKeys:
      TRAIN = 'train'
      EVAL = 'eval'
""", 1)
open(p, 'w').write(s)
PY
fi

# 3. Python env. jax must predate removal of the `jax_pmap_shmap_merge` flag used by trax HEAD.
uv venv -q --allow-existing -p 3.12 /work/venv
. /work/venv/bin/activate
uv pip install -q -e /work/trax \
  "jax==0.7.2" "jaxlib==0.7.2" \
  "tensorflow==2.21.0" "tensorflow-text==2.21.1" "tensorflow-datasets==4.9.10" \
  "gin-config==0.5.0" "gym==0.26.2"

# 4. Pre-trained checkpoint + vocab. The README reads gs://trax-ml/... directly; as of
#    2026-10 that bucket refuses anonymous access (HTTP 403) and no public mirror exists.
#    Try anyway, so this works again if Google re-opens the bucket.
mkdir -p /work/assets
for f in models/translation/ende_wmt32k.pkl.gz vocabs/ende_32k.subword; do
  if curl -fsSL -o "/work/assets/$(basename $f)" "https://storage.googleapis.com/trax-ml/$f"; then
    echo "downloaded $f"
  else
    rm -f "/work/assets/$(basename $f)"
    echo "WARNING: gs://trax-ml/$f is not publicly accessible (403); README snippet cannot load it." >&2
  fi
done
echo "setup done"
