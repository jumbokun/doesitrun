#!/usr/bin/env bash
# Reproduce the CPU-only StyleGAN (TF 1.15 / Python 3.7) setup from scratch.
set -euo pipefail
cd /work

# 1. Clone the repo.
[ -d /work/stylegan/.git ] || git clone https://github.com/NVlabs/stylegan /work/stylegan

# 2. Python 3.7 via micromamba (uv in this image no longer ships 3.7 builds).
if [ ! -x /opt/micromamba/bin/micromamba ]; then
  mkdir -p /opt/micromamba
  curl -fsSL https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xj -C /opt/micromamba bin/micromamba
fi
[ -x /work/conda/bin/python ] || /opt/micromamba/bin/micromamba create -y -q -r /opt/micromamba/root -p /work/conda -c conda-forge python=3.7 pip

# 3. TensorFlow 1.15 (CPU use of the standard wheel) + deps.
/work/conda/bin/python -m pip install -q --root-user-action=ignore \
  tensorflow==1.15.5 numpy==1.18.5 protobuf==3.20.3 "h5py<3" pillow requests gdown

# 4. CPU patches: soft device placement + NCHW->NHWC shims for ops exec'd from the pickle.
cd /work/stylegan
if ! [ -f dnnlib/tflib/cpu_compat.py ]; then
git apply <<'PATCH'
diff --git a/dnnlib/tflib/cpu_compat.py b/dnnlib/tflib/cpu_compat.py
new file mode 100644
index 0000000..b7dbd79
--- /dev/null
+++ b/dnnlib/tflib/cpu_compat.py
@@ -0,0 +1,54 @@
+# CPU compatibility shims: TensorFlow's CPU kernels do not support NCHW for
+# conv2d_transpose / depthwise_conv2d / avg_pool (and conv2d on some builds).
+# These wrappers accept NCHW tensors, run the op in NHWC and transpose back.
+
+"""NCHW-on-CPU workarounds for networks loaded from pickles."""
+
+import re
+import tensorflow as tf
+
+_has_gpu = None
+
+def has_gpu() -> bool:
+    global _has_gpu
+    if _has_gpu is None:
+        from tensorflow.python.client import device_lib
+        _has_gpu = any(d.device_type == "GPU" for d in device_lib.list_local_devices())
+    return _has_gpu
+
+def _to_nhwc(x):
+    return tf.transpose(x, [0, 2, 3, 1])
+
+def _to_nchw(x):
+    return tf.transpose(x, [0, 3, 1, 2])
+
+def _vec_to_nhwc(v):
+    return [v[0], v[2], v[3], v[1]]
+
+def conv2d(x, w, strides, padding, data_format="NHWC", **kwargs):
+    if data_format != "NCHW":
+        return tf.nn.conv2d(x, w, strides=strides, padding=padding, data_format=data_format, **kwargs)
+    return _to_nchw(tf.nn.conv2d(_to_nhwc(x), w, strides=_vec_to_nhwc(strides), padding=padding, data_format="NHWC", **kwargs))
+
+def conv2d_transpose(x, w, output_shape, strides, padding, data_format="NHWC", **kwargs):
+    if data_format != "NCHW":
+        return tf.nn.conv2d_transpose(x, w, output_shape, strides=strides, padding=padding, data_format=data_format, **kwargs)
+    y = tf.nn.conv2d_transpose(_to_nhwc(x), w, _vec_to_nhwc(output_shape), strides=_vec_to_nhwc(strides), padding=padding, data_format="NHWC", **kwargs)
+    return _to_nchw(y)
+
+def depthwise_conv2d(x, f, strides, padding, data_format="NHWC", **kwargs):
+    if data_format != "NCHW":
+        return tf.nn.depthwise_conv2d(x, f, strides=strides, padding=padding, data_format=data_format, **kwargs)
+    return _to_nchw(tf.nn.depthwise_conv2d(_to_nhwc(x), f, strides=_vec_to_nhwc(strides), padding=padding, data_format="NHWC", **kwargs))
+
+def avg_pool(x, ksize, strides, padding, data_format="NHWC", **kwargs):
+    if data_format != "NCHW":
+        return tf.nn.avg_pool(x, ksize=ksize, strides=strides, padding=padding, data_format=data_format, **kwargs)
+    return _to_nchw(tf.nn.avg_pool(_to_nhwc(x), ksize=_vec_to_nhwc(ksize), strides=_vec_to_nhwc(strides), padding=padding, data_format="NHWC", **kwargs))
+
+def patch_source(src: str) -> str:
+    """Redirect NCHW tf.nn ops in network build source to the wrappers above when no GPU is present."""
+    if has_gpu():
+        return src
+    src = re.sub(r"\btf\.nn\.(conv2d_transpose|conv2d|depthwise_conv2d|avg_pool)\(", r"_cpu_compat.\1(", src)
+    return "import dnnlib.tflib.cpu_compat as _cpu_compat\n" + src
diff --git a/dnnlib/tflib/network.py b/dnnlib/tflib/network.py
index d888a90..51aa129 100755
--- a/dnnlib/tflib/network.py
+++ b/dnnlib/tflib/network.py
@@ -19,6 +19,7 @@ from collections import OrderedDict
 from typing import Any, List, Tuple, Union
 
 from . import tfutil
+from . import cpu_compat
 from .. import util
 
 from .tfutil import TfExpression, TfExpressionEx
@@ -288,7 +289,7 @@ class Network:
         module = types.ModuleType(module_name)
         sys.modules[module_name] = module
         _import_module_src[module] = self._build_module_src
-        exec(self._build_module_src, module.__dict__) # pylint: disable=exec-used
+        exec(cpu_compat.patch_source(self._build_module_src), module.__dict__) # pylint: disable=exec-used
 
         # Locate network build function in the temporary module.
         self._build_func = util.get_obj_from_module(module, self._build_func_name)
diff --git a/dnnlib/tflib/tfutil.py b/dnnlib/tflib/tfutil.py
index a431a4d..7d9cb94 100755
--- a/dnnlib/tflib/tfutil.py
+++ b/dnnlib/tflib/tfutil.py
@@ -84,6 +84,7 @@ def _sanitize_tf_config(config_dict: dict = None) -> dict:
     cfg["env.TF_CPP_MIN_LOG_LEVEL"]         = "1"       # 0 = Print all available debug info from TensorFlow. 1 = Print warnings and errors, but disable debug info.
     cfg["graph_options.place_pruned_graph"] = True      # False = Check that all ops are available on the designated device. True = Skip the check for ops that are not used.
     cfg["gpu_options.allow_growth"]         = True      # False = Allocate all GPU memory at the beginning. True = Allocate only as much GPU memory as needed.
+    cfg["allow_soft_placement"]             = True      # Fall back to CPU when no GPU is available.
 
     # User overrides.
     if config_dict is not None:
PATCH
fi

# 5. Pre-download the FFHQ generator with gdown (the repo's downloader chokes on Drive's
#    virus-scan page) and place it where dnnlib.util.open_url looks it up in its cache.
mkdir -p /work/downloads /work/stylegan/cache
PKL=/work/downloads/karras2019stylegan-ffhq-1024x1024.pkl
if [ "$(md5sum "$PKL" 2>/dev/null | cut -d' ' -f1)" != "5a20ed46ea6494a9e969db2f6b97a88a" ]; then
  rm -f "$PKL"
  /work/conda/bin/gdown -q 1MEGjdvVpUsu1jB4zrXZN7Y4kBBOzizDQ -O "$PKL"
fi
echo "5a20ed46ea6494a9e969db2f6b97a88a  $PKL" | md5sum -c -
# md5 of the URL 'https://drive.google.com/uc?id=1MEGjdvVpUsu1jB4zrXZN7Y4kBBOzizDQ'
rm -f /work/stylegan/cache/263e666dc20e26dcbfa514733c1d1f81_*
cp "$PKL" /work/stylegan/cache/263e666dc20e26dcbfa514733c1d1f81_karras2019stylegan-ffhq-1024x1024.pkl

echo "Setup complete. Run: source /work/env.sh && cd /work/stylegan && python pretrained_example.py"
