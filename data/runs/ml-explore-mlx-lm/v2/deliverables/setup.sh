#!/usr/bin/env bash
# Reproduce the mlx-lm CPU setup from scratch. Run as root.
set -euo pipefail
cd /work
[ -d mlx-lm/.git ] || git clone https://github.com/ml-explore/mlx-lm /work/mlx-lm

# Patch: upcast models to float32 on the CPU backend. MLX's CPU bf16
# quantized matmul is ~40x slower than fp32 (~140 s/token vs ~3 s/token).
cd /work/mlx-lm
if ! grep -q MLX_LM_CPU_FLOAT32 mlx_lm/utils.py; then
  git apply <<'PATCH'
diff --git a/mlx_lm/utils.py b/mlx_lm/utils.py
--- a/mlx_lm/utils.py
+++ b/mlx_lm/utils.py
@@ -598,6 +598,13 @@ def load_model(
     model.eval()
     model.load_weights(list(weights.items()), strict=strict)
 
+    # bf16/fp16 quantized matmul is very slow on the CPU backend; use fp32
+    if (
+        mx.default_device().type == mx.DeviceType.cpu
+        and os.environ.get("MLX_LM_CPU_FLOAT32", "1") != "0"
+    ):
+        model.set_dtype(mx.float32)
+
     if not lazy:
         mx.eval(model.parameters())
 
PATCH
fi
cd /work

uv venv --allow-existing --python 3.12 /work/venv
# On Linux, mlx is only pulled in via an extra; use the CPU build.
uv pip install --python /work/venv/bin/python -e "/work/mlx-lm[cpu]"

export HF_HOME=/work/hf_cache
/work/venv/bin/python -c "from huggingface_hub import snapshot_download; snapshot_download('mlx-community/Llama-3.2-3B-Instruct-4bit')"
echo "setup done"
