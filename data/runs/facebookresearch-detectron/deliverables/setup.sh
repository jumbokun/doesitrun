#!/usr/bin/env bash
# Reproduces a CPU-only Detectron (Caffe2) inference setup in /work.
set -euo pipefail
retry() { for i in 1 2 3 4 5; do "$@" && return 0; echo "retry $i: $*"; sleep 10; done; return 1; }
W=${WORK_DIR:-/work}
cd "$W"
MODEL_URL="https://dl.fbaipublicfiles.com/detectron/35861858/12_2017_baselines/e2e_mask_rcnn_R-101-FPN_2x.yaml.02_32_51.SgT4y1cO/output/train/coco_2014_train:coco_2014_valminusminival/generalized_rcnn/model_final.pkl"

# 1. Clone
if [ ! -d Detectron/.git ]; then
  rm -rf Detectron; retry git clone https://github.com/facebookresearch/Detectron Detectron
fi
git -C Detectron checkout -q 04155a0

# 2. Python 3.8 venv with PyTorch 1.7.1 CPU wheel (ships caffe2 + libcaffe2_detectron_ops.so)
export UV_PYTHON_INSTALL_DIR="$W/.uv-python"
[ -x venv/bin/python ] || retry uv venv -p 3.8 venv
source venv/bin/activate
export UV_HTTP_TIMEOUT=600 UV_HTTP_RETRIES=10
retry uv pip install "torch==1.7.1+cpu" -f https://download.pytorch.org/whl/torch_stable.html
retry uv pip install "numpy<1.20" "protobuf<3.21" "pyyaml==5.3.1" "matplotlib<3.4" \
  "opencv-python-headless<4.6" "scipy<1.11" six future mock Cython "setuptools<60" pycocotools

# 3. CPU patches (ops lib fallback, CPU device fallback, unsafe yaml loader)
cd Detectron
if ! grep -q "Fall back to the CPU-only build" detectron/utils/env.py; then
  git apply <<'PATCH_EOF'
diff --git a/detectron/utils/c2.py b/detectron/utils/c2.py
index ba0cb3e..afb7eab 100644
--- a/detectron/utils/c2.py
+++ b/detectron/utils/c2.py
@@ -135,7 +135,9 @@ def CpuScope():
 
 
 def CudaDevice(gpu_id):
-    """Create a Cuda device."""
+    """Create a Cuda device (falls back to CPU when no GPU is available)."""
+    if workspace.NumCudaDevices() <= 0:
+        return core.DeviceOption(caffe2_pb2.CPU)
     return core.DeviceOption(caffe2_pb2.CUDA, gpu_id)
 
 
diff --git a/detectron/utils/env.py b/detectron/utils/env.py
index 128162f..2acb3a9 100644
--- a/detectron/utils/env.py
+++ b/detectron/utils/env.py
@@ -72,6 +72,14 @@ def get_detectron_ops_lib():
             if os.path.exists(ops_path):
                 print('Found Detectron ops lib: {}'.format(ops_path))
                 return ops_path
+    # Fall back to the CPU-only build of the Detectron ops (e.g. CPU PyTorch wheels)
+    cpu_lib = _DETECTRON_OPS_LIB.replace('_gpu', '')
+    for prefix in prefixes:
+        for subdir in subdirs:
+            ops_path = os.path.join(prefix, subdir, cpu_lib)
+            if os.path.exists(ops_path):
+                print('Found Detectron ops lib: {}'.format(ops_path))
+                return ops_path
     raise Exception('Detectron ops lib not found')
 
 
@@ -87,5 +95,10 @@ def get_custom_ops_lib():
 
 
 # YAML load/dump function aliases
-yaml_load = yaml.load
+# The weights files embed cfgs containing Python objects (AttrDict, numpy
+# scalars), which newer PyYAML only loads with the unsafe loader
+def yaml_load(stream):
+    return yaml.load(stream, Loader=getattr(yaml, 'UnsafeLoader', yaml.Loader))
+
+
 yaml_dump = yaml.dump
PATCH_EOF
fi
retry python setup.py develop   # equivalent of `make` (which would add --user inside a venv)
cd "$W"

# 4. Weights: keep a copy and pre-populate Detectron's download cache
mkdir -p models
if [ ! -s models/model_final.pkl ]; then
  retry curl -fL --retry 5 --retry-all-errors -C - -o models/model_final.pkl.part "$MODEL_URL"
  mv models/model_final.pkl.part models/model_final.pkl
fi
CACHE=/tmp/detectron-download-cache/${MODEL_URL#https://dl.fbaipublicfiles.com/detectron/}
mkdir -p "$(dirname "$CACHE")"
[ -s "$CACHE" ] || cp models/model_final.pkl "$CACHE"
echo "setup done"
