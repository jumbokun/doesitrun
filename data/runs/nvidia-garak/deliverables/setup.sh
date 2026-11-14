#!/usr/bin/env bash
# Reproducible CPU-only setup of NVIDIA/garak in /work
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
GARAK_COMMIT=892779207cbc38f65a738ef9cbdfbc1e83aa0b55
cd /work
if [ ! -d /work/garak/.git ]; then
  git clone https://github.com/NVIDIA/garak /work/garak
fi
git -C /work/garak checkout -q "$GARAK_COMMIT"

# python-magic needs libmagic
apt-get update -qq && apt-get install -y -qq libmagic1 >/dev/null

# Fix: HF Pipeline generator returned None for prompts longer than the model
# context (e.g. DAN 11.0 = 1057 tokens on gpt2's 1024 window -> "index out of range").
cd /work/garak
if ! grep -q 'handle_long_generation' garak/generators/huggingface.py; then
  git apply <<'PATCH'
diff --git a/garak/generators/huggingface.py b/garak/generators/huggingface.py
index 603b909..e6730d9 100644
--- a/garak/generators/huggingface.py
+++ b/garak/generators/huggingface.py
@@ -152,7 +152,14 @@ class Pipeline(Generator, HFCompatible):
                         generations_this_call
                     )
 
-                    raw_output = self.generator(formatted_prompt)
+                    call_kwargs = {
+                        "max_new_tokens": self.max_tokens,
+                        # left-truncate prompts that leave no room for generation within the context window
+                        "handle_long_generation": "hole",
+                    }
+                    if self.deprefix_prompt and not self.use_chat:
+                        call_kwargs["return_full_text"] = False
+                    raw_output = self.generator(formatted_prompt, **call_kwargs)
             except Exception as e:
                 logging.error(e)
                 raw_output = []  # could handle better than this
PATCH
fi
cd /work

[ -d /work/venv ] || uv venv --python 3.12 /work/venv
. /work/venv/bin/activate
# CPU-only torch (avoid pulling multi-GB CUDA wheels)
uv pip install --index-url https://download.pytorch.org/whl/cpu "torch>=2.13.0"
uv pip install pip
uv pip install -e /work/garak

# pre-download gpt2 (xet download path 404s unauthenticated; use plain HTTP)
export HF_HOME=/work/hf_cache
export HF_HUB_DISABLE_XET=1
python -c "from huggingface_hub import snapshot_download; snapshot_download('gpt2', allow_patterns=['*.json','*.txt','model.safetensors'])"
# fetch nltk/other first-run resources and sanity check
python -m garak --list_probes > /dev/null
