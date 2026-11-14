#!/usr/bin/env bash
# Reproduces the CPU-only PaddleFormers quickstart setup from scratch.
set -euo pipefail

WORK=/work
REPO=$WORK/PaddleFormers
VENV=$WORK/venv
COMMIT=b52811b3477da7cb4daf530bbbf1dba54079ad5d
export UV_LINK_MODE=copy

# 1. Clone the repo at a pinned commit
if [ ! -d "$REPO/.git" ]; then
    git clone https://github.com/PaddlePaddle/PaddleFormers "$REPO"
fi
cd "$REPO"
git fetch -q origin "$COMMIT" 2>/dev/null || true
git checkout -q -f "$COMMIT"

# 2. CPU-only fixes (no paddlefleet / no CPU bf16 matmul / no CPU fused_rms_norm kernel)
git apply --whitespace=nowarn - <<'PATCH'
diff --git a/paddleformers/nn/norm.py b/paddleformers/nn/norm.py
index 5a5b6f4a5c..9f0489279a 100644
--- a/paddleformers/nn/norm.py
+++ b/paddleformers/nn/norm.py
@@ -68,7 +68,11 @@ class RMSNorm(nn.Layer):
 
     def forward(self, hidden_states):
         current_device = detect_device()
-        if self.config.get("fuse_rms_norm", True) and current_device != "iluvatar_gpu":
+        if (
+            self.config.get("fuse_rms_norm", True)
+            and current_device != "iluvatar_gpu"
+            and not hidden_states.place.is_cpu_place()  # no CPU kernel for fused_rms_norm_ext
+        ):
             return fused_rms_norm_ext(hidden_states, self.weight, self.variance_epsilon)[0].astype(self.weight.dtype)
 
         with paddle.amp.auto_cast(False):
diff --git a/paddleformers/transformers/model_utils.py b/paddleformers/transformers/model_utils.py
index 01eb0d12cf..aed9a2a579 100644
--- a/paddleformers/transformers/model_utils.py
+++ b/paddleformers/transformers/model_utils.py
@@ -2842,6 +2842,14 @@ class PretrainedModel(Layer, GenerationMixin, ConversionMixin):
                 if (sub_config := getattr(config, sub_config_key)) is not None:
                     sub_config.dtype = dtype
 
+        # Paddle has no CPU matmul kernels for half precision, so fall back to float32 on CPU.
+        if paddle.device.get_device() == "cpu" and str(dtype).replace("paddle.", "") in ("bfloat16", "float16"):
+            logger.warning(f"dtype `{dtype}` is not supported on CPU, using `float32` instead.")
+            dtype = "float32"
+            for sub_config_key in config.sub_configs:
+                if (sub_config := getattr(config, sub_config_key)) is not None:
+                    sub_config.dtype = dtype
+
         config.dtype = dtype
 
         init_contexts = []
diff --git a/paddleformers/transformers/qwen3/modeling.py b/paddleformers/transformers/qwen3/modeling.py
index 6176f810d3..0d6ff7d089 100644
--- a/paddleformers/transformers/qwen3/modeling.py
+++ b/paddleformers/transformers/qwen3/modeling.py
@@ -31,7 +31,12 @@ from paddle import Tensor, nn
 from paddle.distributed.fleet.recompute.recompute import recompute
 from paddle.distributed.fleet.utils.sequence_parallel_utils import ScatterOp
 
-from paddleformers.transformers.gpt_provider import GPTModelProvider
+from ...utils.import_utils import is_paddlefleet_available
+
+if is_paddlefleet_available():
+    from paddleformers.transformers.gpt_provider import GPTModelProvider
+else:  # CPU-only install: fall back to the pure-Paddle implementation
+    GPTModelProvider = object
 
 from ...nn.attention.interface import ALL_ATTENTION_FUNCTIONS
 from ...nn.criterion.interface import CriterionLayer
@@ -1081,6 +1086,10 @@ class Qwen3ForCausalLMPipeDeprecated(GeneralModelForCausalLMPipe):
     _gen_inv_aoa_config = Qwen3ForCausalLMDeprecated._gen_inv_aoa_config
 
 
+if not is_paddlefleet_available():
+    Qwen3ForCausalLM = Qwen3ForCausalLMDeprecated
+    Qwen3ForCausalLMPipe = Qwen3ForCausalLMPipeDeprecated
+
 __all__ = [
     "Qwen3Model",
     "Qwen3PretrainedModel",
PATCH

# 3. Python venv (--seed: paddleformers does `import pip` at import time)
uv venv --seed -p 3.12 "$VENV"
LOCK=$(mktemp)
cat > "$LOCK" <<'LOCKEOF'
aistudio-sdk==0.3.9
annotated-doc==0.0.6
annotated-types==0.8.0
anyio==4.16.0
audioread==3.1.0
babel==2.18.0
bce-python-sdk==0.9.79
binpacking==2.0.1
blinker==1.9.0
certifi==2026.10.23
cffi==2.1.1
charset-normalizer==3.5.2
click==8.5.1
cloudpickle==3.1.2
colorlog==6.12.0
contourpy==1.3.3
crc32c==2.9.post0
cryptography==50.0.2
cycler==0.12.1
datasets==5.2.0
decorator==5.3.1
dill==0.4.1
fast-dataindex==0.1.2
filelock==4.2.10
flask==3.1.3
flask-babel==4.0.0
fonttools==4.68.0
fsspec==2026.9.0
future==1.0.0
gputil==1.4.0
h11==0.16.0
hf-xet==1.8.0
httpcore==1.0.9
httpx==0.28.1
huggingface-hub==1.33.0
idna==3.20
importlib-metadata==10.2.0
itsdangerous==2.2.0
jinja2==3.1.6
joblib==1.6.0
kiwisolver==1.5.1
lazy-importer==0.1.0
lazy-loader==0.6
librosa==0.11.0
llvmlite==0.50.0
markdown-it-py==4.3.0
markupsafe==3.0.4
matplotlib==3.11.2
mdurl==0.1.2
ml-dtypes==0.5.4
modelscope==1.40.3
modelscope-hub==0.7.1
msgpack==1.2.4
multiprocess==0.70.19
narwhals==2.28.0
networkx==3.7
numba==0.68.1
numpy==1.26.4
omegaconf==2.4.0
opt-einsum==3.3.0
orjson==3.13.0
packaging==26.3
paddlecodec==0.2.0
paddlepaddle==3.3.1
pandas==3.0.6
pillow==13.0.0
pip==26.3
platformdirs==4.14.5
pooch==1.9.0
prettytable==3.18.0
protobuf==7.36.2
psutil==7.2.2
pyarrow==26.0.1
pybind11==3.1.0
pycparser==3.12
pycryptodome==4.4.0
pydantic==2.14.3
pydantic-core==2.50.4
pygments==2.21.0
pyparsing==3.3.3
python-dateutil==4.0.0
pytz==2026.6
pyyaml==6.0.3
rarfile==4.5
regex==2026.11.9
requests==2.34.2
rich==15.0.0
ruamel-yaml==0.19.1
safetensors==0.8.0
scikit-learn==1.9.1
scipy==1.17.1
sentencepiece==0.2.3
setuptools==84.2.1
shellingham==1.5.4
six==1.17.0
soundfile==0.14.0
soxr==1.1.0
threadpoolctl==3.8.0
tiktoken==0.14.0
tokenizers==0.22.2
tqdm==4.70.1
transformers==5.3.0
typer==0.29.1
typing-extensions==4.16.0
typing-inspection==0.4.5
tzdata==2026.6
urllib3==2.8.0
visualdl==2.5.3
wcwidth==0.9.4
werkzeug==3.1.9
xxhash==4.1.0
zipp==4.1.2
LOCKEOF
# paddlepaddle (CPU build) comes from PyPI; README only documents GPU (cuXXX) indexes + paddlefleet
uv pip install --python "$VENV/bin/python" -c "$LOCK" paddlepaddle==3.3.1
uv pip install --python "$VENV/bin/python" -c "$LOCK" -e "$REPO"
rm -f "$LOCK"

# 4. Pre-download the model/tokenizer into the HF cache
cd /tmp
"$VENV/bin/python" - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("Qwen/Qwen3-0.6B-Base")
PY

# 5. Smoke test
"$VENV/bin/python" - <<'PY'
from paddleformers.transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained("Qwen/Qwen3-0.6B-Base")
ids = tok.encode("中华人民共和国")
print(ids)
PY
echo "setup complete"
