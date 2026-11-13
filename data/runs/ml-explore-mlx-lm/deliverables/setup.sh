#!/usr/bin/env bash
# Reproduces the mlx-lm CPU setup from scratch (Ubuntu 24.04, run as root).
set -euo pipefail
cd /work
COMMIT=56230fa02
if [ ! -d mlx-lm/.git ]; then
  git clone https://github.com/ml-explore/mlx-lm /work/mlx-lm
fi
cd /work/mlx-lm
git checkout -q "$COMMIT"

# Patch: compute in float32 on the CPU backend. bf16/fp16 quantized matmuls are
# 10-50x slower than fp32 on x86 CPUs (a single forward pass took ~8 minutes).
if ! grep -q MLX_LM_CPU_FLOAT32 mlx_lm/utils.py; then
git apply - <<'PATCH'
diff --git a/mlx_lm/utils.py b/mlx_lm/utils.py
--- a/mlx_lm/utils.py
+++ b/mlx_lm/utils.py
@@ -696,6 +696,10 @@ def load(
     if adapter_path is not None:
         model = load_adapters(model, adapter_path)
         model.eval()
+    # Half precision kernels are very slow on the CPU backend, so compute in
+    # float32 there (set MLX_LM_CPU_FLOAT32=0 to disable).
+    if mx.default_device() == mx.cpu and os.environ.get("MLX_LM_CPU_FLOAT32", "1") != "0":
+        model.set_dtype(mx.float32)
     tokenizer = load_tokenizer(
         model_path, tokenizer_config, eos_token_ids=config.get("eos_token_id", None)
     )
PATCH
fi

cd /work
[ -x /work/.venv/bin/python ] || uv venv --python 3.12 /work/.venv
. /work/.venv/bin/activate
# On Linux mlx is only installed via an extra; use the CPU backend.
uv pip install -e "/work/mlx-lm[cpu]"

export HF_HOME=/work/hf_cache
python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("mlx-community/Llama-3.2-3B-Instruct-4bit")
PY
echo "setup complete"
