#!/usr/bin/env bash
# Reproduce the CPU-only PaddleFormers quickstart setup from scratch (self-contained).
set -euo pipefail
VENV=/work/.paddleformers-work
REPO=/work/PaddleFormers
COMMIT=f7fa77f02e   # commit this setup was validated against
export UV_HTTP_TIMEOUT=300 HF_HUB_DOWNLOAD_TIMEOUT=120 HF_HUB_ETAG_TIMEOUT=60
mkdir -p /work

retry() {  # retry <cmd...> : up to 5 attempts with backoff
  local n=1
  until "$@"; do
    if [ $n -ge 5 ]; then echo "failed after $n attempts: $*" >&2; return 1; fi
    echo "attempt $n failed: $* ; retrying" >&2; sleep $((n * 10)); n=$((n + 1))
  done
}

if [ ! -d "$REPO/.git" ]; then
  rm -rf "$REPO"
  retry git clone https://github.com/PaddlePaddle/PaddleFormers.git "$REPO" || { rm -rf "$REPO"; exit 1; }
fi
cd "$REPO"
git checkout -q "$COMMIT"

# CPU fixes: optional paddlefleet (GPU-only), no fused RMSNorm kernel on CPU, no bf16 matmul on CPU
PATCH=$(mktemp)
cat > "$PATCH" <<'PATCH_EOF'
diff --git a/paddleformers/nn/norm.py b/paddleformers/nn/norm.py
index 5a5b6f4a5c..f9c97021e7 100644
--- a/paddleformers/nn/norm.py
+++ b/paddleformers/nn/norm.py
@@ -68,7 +68,12 @@ class RMSNorm(nn.Layer):
 
     def forward(self, hidden_states):
         current_device = detect_device()
-        if self.config.get("fuse_rms_norm", True) and current_device != "iluvatar_gpu":
+        # The fused kernel is not registered for CPU, so use the plain implementation there.
+        if (
+            self.config.get("fuse_rms_norm", True)
+            and current_device != "iluvatar_gpu"
+            and paddle.get_device() != "cpu"
+        ):
             return fused_rms_norm_ext(hidden_states, self.weight, self.variance_epsilon)[0].astype(self.weight.dtype)
 
         with paddle.amp.auto_cast(False):
diff --git a/paddleformers/transformers/model_utils.py b/paddleformers/transformers/model_utils.py
index 05b54f215c..ce5eeb38c7 100644
--- a/paddleformers/transformers/model_utils.py
+++ b/paddleformers/transformers/model_utils.py
@@ -2841,6 +2841,14 @@ class PretrainedModel(Layer, GenerationMixin, ConversionMixin):
                 if (sub_config := getattr(config, sub_config_key)) is not None:
                     sub_config.dtype = dtype
 
+        # CPU Paddle has no bfloat16/float16 matmul kernels, so fall back to float32 on CPU.
+        if paddle.get_device() == "cpu" and str(dtype).replace("paddle.", "") in ("bfloat16", "float16"):
+            logger.warning(f"dtype {dtype} is not supported on CPU, using float32 instead.")
+            dtype = "float32"
+            for sub_config_key in config.sub_configs:
+                if (sub_config := getattr(config, sub_config_key)) is not None:
+                    sub_config.dtype = dtype
+
         config.dtype = dtype
 
         init_contexts = []
diff --git a/paddleformers/transformers/qwen2/modeling.py b/paddleformers/transformers/qwen2/modeling.py
index 4364dae760..e3b8bf4b74 100644
--- a/paddleformers/transformers/qwen2/modeling.py
+++ b/paddleformers/transformers/qwen2/modeling.py
@@ -31,7 +31,14 @@ from paddle import Tensor, nn
 from paddle.distributed.fleet.recompute.recompute import recompute
 from paddle.distributed.fleet.utils.sequence_parallel_utils import ScatterOp
 
-from paddleformers.transformers.gpt_provider import GPTModelProvider
+from ...utils.import_utils import is_paddlefleet_available
+
+try:
+    from paddleformers.transformers.gpt_provider import GPTModelProvider
+except ImportError:  # paddlefleet (GPU-only) not installed, e.g. CPU inference
+    @dataclass
+    class GPTModelProvider:
+        pass
 
 from ...nn.attention.interface import ALL_ATTENTION_FUNCTIONS
 from ...nn.criterion.interface import CriterionLayer
@@ -1059,6 +1066,12 @@ class Qwen2ForCausalLMPipeDeprecated(GeneralModelForCausalLMPipe):
     _gen_inv_aoa_config = Qwen2ForCausalLMDeprecated._gen_inv_aoa_config
 
 
+if not is_paddlefleet_available():
+    # The fleet-based classes need paddlefleet (GPU-only); fall back to the plain implementations on CPU.
+    Qwen2ForCausalLM = Qwen2ForCausalLMDeprecated
+    Qwen2ForCausalLMPipe = Qwen2ForCausalLMPipeDeprecated
+
+
 __all__ = [
     "Qwen2Model",
     "Qwen2PretrainedModel",
diff --git a/paddleformers/transformers/qwen3/modeling.py b/paddleformers/transformers/qwen3/modeling.py
index 6176f810d3..5a36116b2c 100644
--- a/paddleformers/transformers/qwen3/modeling.py
+++ b/paddleformers/transformers/qwen3/modeling.py
@@ -31,7 +31,14 @@ from paddle import Tensor, nn
 from paddle.distributed.fleet.recompute.recompute import recompute
 from paddle.distributed.fleet.utils.sequence_parallel_utils import ScatterOp
 
-from paddleformers.transformers.gpt_provider import GPTModelProvider
+from ...utils.import_utils import is_paddlefleet_available
+
+try:
+    from paddleformers.transformers.gpt_provider import GPTModelProvider
+except ImportError:  # paddlefleet (GPU-only) not installed, e.g. CPU inference
+    @dataclass
+    class GPTModelProvider:
+        pass
 
 from ...nn.attention.interface import ALL_ATTENTION_FUNCTIONS
 from ...nn.criterion.interface import CriterionLayer
@@ -1081,6 +1088,12 @@ class Qwen3ForCausalLMPipeDeprecated(GeneralModelForCausalLMPipe):
     _gen_inv_aoa_config = Qwen3ForCausalLMDeprecated._gen_inv_aoa_config
 
 
+if not is_paddlefleet_available():
+    # The fleet-based classes need paddlefleet (GPU-only); fall back to the plain implementations on CPU.
+    Qwen3ForCausalLM = Qwen3ForCausalLMDeprecated
+    Qwen3ForCausalLMPipe = Qwen3ForCausalLMPipeDeprecated
+
+
 __all__ = [
     "Qwen3Model",
     "Qwen3PretrainedModel",
PATCH_EOF
if git apply --reverse --check "$PATCH" 2>/dev/null; then
  echo "patch already applied"
else
  git apply "$PATCH"
fi
rm -f "$PATCH"

# --seed installs pip into the venv: paddleformers does `import pip` at runtime
[ -x "$VENV/bin/python" ] || retry uv venv --seed --python 3.12 "$VENV"
source "$VENV/bin/activate"

# README only documents CUDA wheels; use the official CPU index instead
retry uv pip install "paddlepaddle==3.3.1" \
  --index-url https://www.paddlepaddle.org.cn/packages/stable/cpu/ \
  --extra-index-url https://pypi.org/simple
retry uv pip install pip
# Source install without the [paddlefleet] extra (GPU-only, pinned version not published)
retry uv pip install -e .

# Pre-download the model (tokenizer + weights) into the HF cache
retry python - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("Qwen/Qwen3-0.6B-Base")
PY

# Smoke test
cd /tmp
python -c "
from paddleformers.transformers import AutoTokenizer
t = AutoTokenizer.from_pretrained('Qwen/Qwen3-0.6B-Base')
ids = t.encode('中华人民共和国'); print(ids)
assert list(ids) == [105492, 104773], ids
"
echo "setup complete"
