#!/usr/bin/env bash
# Reproducible CPU-only setup for NVlabs/stylegan2 (TensorFlow 1.15, Python 3.7)
set -euo pipefail
cd /work
[ -d stylegan2/.git ] || git clone https://github.com/NVlabs/stylegan2 /work/stylegan2
cd /work/stylegan2
git checkout -q bf0fe0b

# Python 3.7 + TF 1.15 CPU (TF1 has no wheels for Python >= 3.8; uv no longer ships 3.7,
# so use a static micromamba binary to get a conda-forge Python 3.7)
mkdir -p /work/tools
[ -x /work/tools/micromamba ] || curl -fsSL -o /work/tools/micromamba \
    https://github.com/mamba-org/micromamba-releases/releases/download/2.10.0-0/micromamba-linux-64
chmod +x /work/tools/micromamba
[ -x /work/py37/bin/python ] || /work/tools/micromamba create -y -q -r /work/mamba-root -p /work/py37 -c conda-forge python=3.7 pip
[ -x /work/venv/bin/python ] || /work/py37/bin/python -m venv /work/venv
/work/venv/bin/python -m pip install -q --upgrade "pip<24"
/work/venv/bin/python -m pip install -q \
    "tensorflow-cpu==1.15.0" "numpy==1.16.6" "protobuf==3.20.3" "h5py==2.10.0" \
    "scipy==1.3.3" "requests==2.22.0" "Pillow==6.2.1"

# CPU-only compatibility patch (see /work/NOTES.md):
#  - fused_bias_act / upfirdn_2d default impl -> 'ref' when TF is built without CUDA
#  - dnnlib/tflib/cpu_compat.py: run NCHW conv2d / conv2d_transpose as NHWC on CPU
#  - allow_soft_placement so the hard-coded /gpu:0 device falls back to CPU
#  - absolute, env-configurable download cache (STYLEGAN2_CACHE_DIR)
if ! git diff --quiet || [ -f dnnlib/tflib/cpu_compat.py ]; then
    echo 'CPU patch already applied'
else
git apply --whitespace=nowarn - <<'CPU_PATCH_EOF'
diff --git a/dnnlib/tflib/__init__.py b/dnnlib/tflib/__init__.py
index 02c2517..97777c6 100755
--- a/dnnlib/tflib/__init__.py
+++ b/dnnlib/tflib/__init__.py
@@ -4,6 +4,7 @@
 # To view a copy of this license, visit
 # https://nvlabs.github.io/stylegan2/license.html
 
+from . import cpu_compat
 from . import autosummary
 from . import network
 from . import optimizer
diff --git a/dnnlib/tflib/cpu_compat.py b/dnnlib/tflib/cpu_compat.py
new file mode 100644
index 0000000..9876254
--- /dev/null
+++ b/dnnlib/tflib/cpu_compat.py
@@ -0,0 +1,52 @@
+# CPU compatibility shim (not part of the original repo).
+#
+# TensorFlow's CPU kernels for Conv2D / Conv2DBackpropInput only support NHWC,
+# while StyleGAN2 (including the network code embedded in the pretrained
+# pickles) uses data_format='NCHW' throughout. When TensorFlow is built without
+# CUDA, wrap tf.nn.conv2d and tf.nn.conv2d_transpose so that NCHW calls are
+# executed as NHWC with transposes around them.
+
+"""Run NCHW convolutions on CPU-only TensorFlow builds."""
+
+import os
+import tensorflow as tf
+
+def _to_nhwc(v):
+    return [v[0], v[2], v[3], v[1]] if isinstance(v, (list, tuple)) and len(v) == 4 else v
+
+def _install():
+    if getattr(tf.nn, '_stylegan2_cpu_compat', False):
+        return
+    orig_conv2d = tf.nn.conv2d
+    orig_conv2d_transpose = tf.nn.conv2d_transpose
+
+    def conv2d(input, filter=None, strides=None, padding=None, use_cudnn_on_gpu=True, data_format='NHWC', dilations=None, name=None, filters=None):
+        if filter is None:
+            filter = filters
+        if data_format != 'NCHW':
+            return orig_conv2d(input, filter, strides=strides, padding=padding, use_cudnn_on_gpu=use_cudnn_on_gpu, data_format=data_format, dilations=dilations, name=name)
+        x = tf.transpose(input, [0, 2, 3, 1])
+        x = orig_conv2d(x, filter, strides=_to_nhwc(strides), padding=padding, use_cudnn_on_gpu=use_cudnn_on_gpu, data_format='NHWC', dilations=_to_nhwc(dilations), name=name)
+        return tf.transpose(x, [0, 3, 1, 2])
+
+    def conv2d_transpose(value=None, filter=None, output_shape=None, strides=None, padding='SAME', data_format='NHWC', name=None, input=None, filters=None, dilations=None):
+        if value is None:
+            value = input
+        if filter is None:
+            filter = filters
+        if data_format != 'NCHW':
+            return orig_conv2d_transpose(value, filter, output_shape, strides, padding=padding, data_format=data_format, name=name, dilations=dilations)
+        if isinstance(output_shape, (list, tuple)):
+            output_shape = _to_nhwc(list(output_shape))
+        else:
+            output_shape = tf.gather(output_shape, [0, 2, 3, 1])
+        x = tf.transpose(value, [0, 2, 3, 1])
+        x = orig_conv2d_transpose(x, filter, output_shape, _to_nhwc(strides), padding=padding, data_format='NHWC', name=name, dilations=_to_nhwc(dilations))
+        return tf.transpose(x, [0, 3, 1, 2])
+
+    tf.nn.conv2d = conv2d
+    tf.nn.conv2d_transpose = conv2d_transpose
+    tf.nn._stylegan2_cpu_compat = True
+
+if os.environ.get('STYLEGAN2_CPU_COMPAT', '1' if not tf.test.is_built_with_cuda() else '0') == '1':
+    _install()
diff --git a/dnnlib/tflib/ops/fused_bias_act.py b/dnnlib/tflib/ops/fused_bias_act.py
index 52f6bfd..0b5f556 100755
--- a/dnnlib/tflib/ops/fused_bias_act.py
+++ b/dnnlib/tflib/ops/fused_bias_act.py
@@ -9,6 +9,7 @@
 import os
 import numpy as np
 import tensorflow as tf
+_DEFAULT_IMPL = os.environ.get('STYLEGAN2_OPS_IMPL', 'cuda' if tf.test.is_built_with_cuda() else 'ref')
 from .. import custom_ops
 from ...util import EasyDict
 
@@ -31,7 +32,7 @@ activation_funcs = {
 
 #----------------------------------------------------------------------------
 
-def fused_bias_act(x, b=None, axis=1, act='linear', alpha=None, gain=None, impl='cuda'):
+def fused_bias_act(x, b=None, axis=1, act='linear', alpha=None, gain=None, impl=None):
     r"""Fused bias and activation function.
 
     Adds bias `b` to activation tensor `x`, evaluates activation function `act`,
@@ -60,6 +61,7 @@ def fused_bias_act(x, b=None, axis=1, act='linear', alpha=None, gain=None, impl=
     Returns:
         Tensor of the same shape and datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     impl_dict = {
         'ref':  _fused_bias_act_ref,
diff --git a/dnnlib/tflib/ops/upfirdn_2d.py b/dnnlib/tflib/ops/upfirdn_2d.py
index fd23777..2462f59 100755
--- a/dnnlib/tflib/ops/upfirdn_2d.py
+++ b/dnnlib/tflib/ops/upfirdn_2d.py
@@ -9,6 +9,7 @@
 import os
 import numpy as np
 import tensorflow as tf
+_DEFAULT_IMPL = os.environ.get('STYLEGAN2_OPS_IMPL', 'cuda' if tf.test.is_built_with_cuda() else 'ref')
 from .. import custom_ops
 
 def _get_plugin():
@@ -16,7 +17,7 @@ def _get_plugin():
 
 #----------------------------------------------------------------------------
 
-def upfirdn_2d(x, k, upx=1, upy=1, downx=1, downy=1, padx0=0, padx1=0, pady0=0, pady1=0, impl='cuda'):
+def upfirdn_2d(x, k, upx=1, upy=1, downx=1, downy=1, padx0=0, padx1=0, pady0=0, pady1=0, impl=None):
     r"""Pad, upsample, FIR filter, and downsample a batch of 2D images.
 
     Accepts a batch of 2D images of the shape `[majorDim, inH, inW, minorDim]`
@@ -54,6 +55,7 @@ def upfirdn_2d(x, k, upx=1, upy=1, downx=1, downy=1, padx0=0, padx1=0, pady0=0,
     Returns:
         Tensor of the shape `[majorDim, outH, outW, minorDim]`, and same datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     impl_dict = {
         'ref':  _upfirdn_2d_ref,
@@ -141,7 +143,7 @@ def _upfirdn_2d_cuda(x, k, upx, upy, downx, downy, padx0, padx1, pady0, pady1):
 
 #----------------------------------------------------------------------------
 
-def filter_2d(x, k, gain=1, data_format='NCHW', impl='cuda'):
+def filter_2d(x, k, gain=1, data_format='NCHW', impl=None):
     r"""Filter a batch of 2D images with the given FIR filter.
 
     Accepts a batch of 2D images of the shape `[N, C, H, W]` or `[N, H, W, C]`
@@ -159,6 +161,7 @@ def filter_2d(x, k, gain=1, data_format='NCHW', impl='cuda'):
     Returns:
         Tensor of the same shape and datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     k = _setup_kernel(k) * gain
     p = k.shape[0] - 1
@@ -166,7 +169,7 @@ def filter_2d(x, k, gain=1, data_format='NCHW', impl='cuda'):
 
 #----------------------------------------------------------------------------
 
-def upsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
+def upsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl=None):
     r"""Upsample a batch of 2D images with the given filter.
 
     Accepts a batch of 2D images of the shape `[N, C, H, W]` or `[N, H, W, C]`
@@ -189,6 +192,7 @@ def upsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
         Tensor of the shape `[N, C, H * factor, W * factor]` or
         `[N, H * factor, W * factor, C]`, and same datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     assert isinstance(factor, int) and factor >= 1
     if k is None:
@@ -199,7 +203,7 @@ def upsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
 
 #----------------------------------------------------------------------------
 
-def downsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
+def downsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl=None):
     r"""Downsample a batch of 2D images with the given filter.
 
     Accepts a batch of 2D images of the shape `[N, C, H, W]` or `[N, H, W, C]`
@@ -221,6 +225,7 @@ def downsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
         Tensor of the shape `[N, C, H // factor, W // factor]` or
         `[N, H // factor, W // factor, C]`, and same datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     assert isinstance(factor, int) and factor >= 1
     if k is None:
@@ -231,7 +236,7 @@ def downsample_2d(x, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
 
 #----------------------------------------------------------------------------
 
-def upsample_conv_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
+def upsample_conv_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl=None):
     r"""Fused `upsample_2d()` followed by `tf.nn.conv2d()`.
 
     Padding is performed only once at the beginning, not between the operations.
@@ -254,6 +259,7 @@ def upsample_conv_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl='c
         Tensor of the shape `[N, C, H * factor, W * factor]` or
         `[N, H * factor, W * factor, C]`, and same datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     assert isinstance(factor, int) and factor >= 1
 
@@ -293,7 +299,7 @@ def upsample_conv_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl='c
 
 #----------------------------------------------------------------------------
 
-def conv_downsample_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl='cuda'):
+def conv_downsample_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl=None):
     r"""Fused `tf.nn.conv2d()` followed by `downsample_2d()`.
 
     Padding is performed only once at the beginning, not between the operations.
@@ -315,6 +321,7 @@ def conv_downsample_2d(x, w, k=None, factor=2, gain=1, data_format='NCHW', impl=
         Tensor of the shape `[N, C, H // factor, W // factor]` or
         `[N, H // factor, W // factor, C]`, and same datatype as `x`.
     """
+    impl = impl or _DEFAULT_IMPL
 
     assert isinstance(factor, int) and factor >= 1
     w = tf.convert_to_tensor(w)
@@ -350,7 +357,8 @@ def _setup_kernel(k):
     assert k.shape[0] == k.shape[1]
     return k
 
-def _simple_upfirdn_2d(x, k, up=1, down=1, pad0=0, pad1=0, data_format='NCHW', impl='cuda'):
+def _simple_upfirdn_2d(x, k, up=1, down=1, pad0=0, pad1=0, data_format='NCHW', impl=None):
+    impl = impl or _DEFAULT_IMPL
     assert data_format in ['NCHW', 'NHWC']
     assert x.shape.rank == 4
     y = x
diff --git a/dnnlib/tflib/tfutil.py b/dnnlib/tflib/tfutil.py
index 1127c7b..284d3de 100755
--- a/dnnlib/tflib/tfutil.py
+++ b/dnnlib/tflib/tfutil.py
@@ -89,6 +89,7 @@ def _sanitize_tf_config(config_dict: dict = None) -> dict:
     cfg["env.TF_CPP_MIN_LOG_LEVEL"]         = "1"       # 0 = Print all available debug info from TensorFlow. 1 = Print warnings and errors, but disable debug info.
     cfg["graph_options.place_pruned_graph"] = True      # False = Check that all ops are available on the designated device. True = Skip the check for ops that are not used.
     cfg["gpu_options.allow_growth"]         = True      # False = Allocate all GPU memory at the beginning. True = Allocate only as much GPU memory as needed.
+    cfg["allow_soft_placement"]             = True      # Fall back to CPU when the requested GPU device does not exist.
 
     # Remove defaults for environment variables that are already set.
     for key in list(cfg):
diff --git a/pretrained_networks.py b/pretrained_networks.py
index 58c1c63..daf8fda 100755
--- a/pretrained_networks.py
+++ b/pretrained_networks.py
@@ -6,6 +6,7 @@
 
 """List of pre-trained StyleGAN2 networks located on Google Drive."""
 
+import os
 import pickle
 import dnnlib
 import dnnlib.tflib as tflib
@@ -67,7 +68,7 @@ def load_networks(path_or_gdrive_path):
         return _cached_networks[path_or_url]
 
     if dnnlib.util.is_url(path_or_url):
-        stream = dnnlib.util.open_url(path_or_url, cache_dir='.stylegan2-cache')
+        stream = dnnlib.util.open_url(path_or_url, cache_dir=os.environ.get('STYLEGAN2_CACHE_DIR', '.stylegan2-cache'))
     else:
         stream = open(path_or_url, 'rb')
 
CPU_PATCH_EOF
fi

# Pre-download the FFHQ config-f pickle into dnnlib's cache (.stylegan2-cache in CWD and ~)
. /work/env.sh 2>/dev/null || export PATH=/work/venv/bin:$PATH
cd /work/stylegan2
python -c "
import pretrained_networks, dnnlib
f = dnnlib.util.open_url(pretrained_networks.gdrive_urls['gdrive:networks/stylegan2-ffhq-config-f.pkl'], cache_dir='/work/stylegan2-cache')
print('cached', len(f.read()))
"
