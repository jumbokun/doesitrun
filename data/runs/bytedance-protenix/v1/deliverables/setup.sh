#!/usr/bin/env bash
# Reproducible CPU-only setup of Protenix in /work. Run as root.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

# 1. Clone
if [ ! -d /work/Protenix/.git ]; then
  git clone https://github.com/bytedance/Protenix /work/Protenix
fi

# 2. Python env (uv-managed 3.12 ships Python.h, needed to build scikit-learn-extra)
if [ ! -x /work/venv/bin/python ]; then
  uv venv --managed-python -p 3.12 /work/venv
fi
source /work/venv/bin/activate
uv pip install torch==2.7.1 torchvision==0.22.1 torchaudio==2.7.1 \
  --index-url https://download.pytorch.org/whl/cpu
# Drop torch (installed as CPU wheel above) and GPU-only packages
grep -v -E '^(torch|torchvision|torchaudio|cuequivariance|triton|deepspeed)' \
  /work/Protenix/requirements.txt > /work/req-cpu.txt
uv pip install -r /work/req-cpu.txt
uv pip install --no-deps -e /work/Protenix

# 3. Patch: fall back to torch layernorm / triangle kernels when no CUDA device
cd /work/Protenix
cat > /tmp/protenix_cpu_fallback.patch <<'PATCH'
--- a/runner/inference.py
+++ b/runner/inference.py
@@ -682,6 +682,15 @@ def update_gpu_compatible_configs(configs: Any) -> Any:
         cc = major + minor / 10.0
         return 7.0 <= cc < 8.0
 
+    if not torch.cuda.is_available():
+        # CPU-only: cuequivariance/triattention/deepspeed kernels need CUDA
+        configs.triangle_attention = "torch"
+        configs.triangle_multiplicative = "torch"
+        logger.info(
+            "No CUDA device detected; using torch triangle kernels."
+        )
+        return configs
+
     if is_gpu_capability_between_7_and_8():
         # V100 and similar architectures don't support some kernels or BF16 effectively
         configs.dtype = "fp32"
--- a/protenix/model/triangular/layers.py
+++ b/protenix/model/triangular/layers.py
@@ -30,7 +30,11 @@ from protenix.utils.torch_utils import (
     permute_final_dims,
 )
 
-fastln_is_installed = os.getenv("LAYERNORM_TYPE", "fast_layernorm") == "fast_layernorm"
+# The fused layernorm is a CUDA kernel; fall back to torch on CPU-only hosts
+fastln_is_installed = (
+    os.getenv("LAYERNORM_TYPE", "fast_layernorm" if torch.cuda.is_available() else "torch")
+    == "fast_layernorm"
+)
 if fastln_is_installed:
     from protenix.model.layer_norm.layer_norm import FusedLayerNorm
 
PATCH
if git apply --check /tmp/protenix_cpu_fallback.patch 2>/dev/null; then
  git apply /tmp/protenix_cpu_fallback.patch
else
  git apply --reverse --check /tmp/protenix_cpu_fallback.patch  # already applied
fi

# env.sh (normally shipped alongside this script)
if [ ! -f /work/env.sh ]; then
  cat > /work/env.sh <<'ENV'
# source /work/env.sh
source /work/venv/bin/activate
export LAYERNORM_TYPE=torch   # fused layernorm is a CUDA-only JIT kernel
cd /work/Protenix
ENV
fi

# 4. Warm-up prediction: downloads checkpoint (~1.4G) to $HOME/checkpoint and CCD data to $HOME/common
mkdir -p /work/test
cat > /work/test/ubq.json <<'JSON'
[{"name":"ubq","sequences":[{"proteinChain":{"count":1,"sequence":"MQIFVKTLTGKTITLEVEPSDTIENVKAKIQDKEGIPPDQQRLIFAGKQLEDGRTLSDYNIQKESTLHLVLRLRGG"}}]}]
JSON
source /work/env.sh
rm -rf /work/test/out
protenix pred -i /work/test/ubq.json -o /work/test/out -n protenix_base_default_v1.0.0 \
  --use_msa false -d fp32 -c 4 -p 20 -e 1
ls /work/test/out/ubq/seed_101/predictions/ubq_sample_0.cif \
   /work/test/out/ubq/seed_101/predictions/ubq_summary_confidence_sample_0.json
