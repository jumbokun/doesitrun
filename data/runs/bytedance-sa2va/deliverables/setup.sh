#!/usr/bin/env bash
# Reproduce the CPU-only Sa2VA-1B demo setup from scratch (run as root).
set -euo pipefail

WORK=/work
REPO=$WORK/Sa2VA
VENV=$WORK/venv
REPO_COMMIT=f7b09adcabe55fc98b4f6369d0f54e61952a669e
MODEL_REVISION=82faf06c93f6ce3fdc0ad3d45b57fd52c463daeb
export DEBIAN_FRONTEND=noninteractive

# system libs needed by opencv-python (pulled in by mmengine)
apt-get update -qq
apt-get install -y -qq libgl1 libglib2.0-0t64

# clone
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/bytedance/Sa2VA "$REPO"
fi
git -C "$REPO" checkout -q "$REPO_COMMIT"

# python env: README "Quick Start" demo requirements, minus flash_attn, CPU torch wheels
[ -x "$VENV/bin/python" ] || uv venv --python 3.11 "$VENV"
grep -v '^flash_attn' "$REPO/projects/sa2va/demo/requirements.txt" > /tmp/sa2va_demo_req.txt
VIRTUAL_ENV=$VENV uv pip install \
  --index-url https://download.pytorch.org/whl/cpu \
  --extra-index-url https://pypi.org/simple \
  --index-strategy unsafe-best-match \
  -r /tmp/sa2va_demo_req.txt huggingface_hub==0.36.2

# CPU fallbacks for demo.py
if ! grep -q 'CPU fallback' "$REPO/projects/sa2va/demo/demo.py"; then
  git -C "$REPO" apply - <<'PATCH'
diff --git a/projects/sa2va/demo/demo.py b/projects/sa2va/demo/demo.py
index e5ff7c5..4fbf12a 100644
--- a/projects/sa2va/demo/demo.py
+++ b/projects/sa2va/demo/demo.py
@@ -7,6 +7,20 @@ from transformers import AutoModelForCausalLM, AutoTokenizer, AutoProcessor, Aut
 import torch
 
 import cv2
+
+# CPU fallback: the HF remote code calls .cuda() unconditionally.
+if not torch.cuda.is_available():
+    torch.Tensor.cuda = lambda self, *args, **kwargs: self
+    torch.nn.Module.cuda = lambda self, *args, **kwargs: self
+
+# The remote code only uses flash_attn optionally, but transformers' import check
+# rejects hub checkpoints when it is missing; drop it from the required imports.
+import importlib.util
+if importlib.util.find_spec('flash_attn') is None:
+    from transformers import dynamic_module_utils
+    _get_imports = dynamic_module_utils.get_imports
+    dynamic_module_utils.get_imports = lambda f: [i for i in _get_imports(f) if i != 'flash_attn']
+
 try:
     from mmengine.visualization import Visualizer
 except ImportError:
@@ -80,10 +94,24 @@ if __name__ == "__main__":
     model_path = cfg.model_path
     model = AutoModelForCausalLM.from_pretrained(
         model_path,
-        torch_dtype="auto",
+        torch_dtype="auto" if torch.cuda.is_available() else torch.float32,
+        low_cpu_mem_usage=True,
         #device_map="auto",
         trust_remote_code=True
     )
+    if not torch.cuda.is_available() and hasattr(model, 'preparing_for_generation'):
+        # bf16 is very slow / partly unsupported on CPU, run in fp32 instead
+        _prep = model.preparing_for_generation
+        model.preparing_for_generation = lambda *a, **kw: _prep(*a, **{**kw, 'torch_dtype': torch.float32})
+    if not torch.cuda.is_available() and hasattr(model, 'grounding_encoder'):
+        # the SAM2 video predictor hardcodes cuda as its state/storage device
+        _sam2 = model.grounding_encoder.sam2_model
+        _init_state = _sam2.init_state
+        def _cpu_init_state(*args, **kwargs):
+            state = _init_state(*args, **kwargs)
+            state["device"] = state["storage_device"] = torch.device("cpu")
+            return state
+        _sam2.init_state = _cpu_init_state
     """
     # For distributed inference, uncomment the following lines to get device_map
     device_map=split_model(model_path)
@@ -129,20 +157,22 @@ if __name__ == "__main__":
 
         print(f"Selected frame {cfg.select}")
         print(f"The input is:\n{cfg.text}")
-        result = model.predict_forward(
-            image=img_frame,
-            text=cfg.text,
-            tokenizer=tokenizer,
-            processor=processor,
-        ) # type: ignore
+        with torch.inference_mode():
+            result = model.predict_forward(
+                image=img_frame,
+                text=cfg.text,
+                tokenizer=tokenizer,
+                **({'processor': processor} if processor is not None else {}),
+            ) # type: ignore
     else:
         print(f"The input is:\n{cfg.text}")
-        result = model.predict_forward(
-            video=vid_frames,
-            text=cfg.text,
-            tokenizer=tokenizer,
-            processor=processor,
-        ) # type: ignore
+        with torch.inference_mode():
+            result = model.predict_forward(
+                video=vid_frames,
+                text=cfg.text,
+                tokenizer=tokenizer,
+                **({'processor': processor} if processor is not None else {}),
+            ) # type: ignore
 
     prediction = result['prediction']
     print(f"The output is:\n{prediction}")
@@ -150,7 +180,8 @@ if __name__ == "__main__":
     if '[SEG]' in prediction and Visualizer is not None:
         _seg_idx = 0
         pred_masks = result['prediction_masks'][_seg_idx]
-        for frame_idx in range(len(vid_frames)):
+        # the model only predicts masks for the first few (<=5) video frames
+        for frame_idx in range(min(len(vid_frames), len(pred_masks))):
             pred_mask = pred_masks[frame_idx]
             if cfg.work_dir:
                 os.makedirs(cfg.work_dir, exist_ok=True)
PATCH
fi

# model weights into the default HF cache (so --model_path ByteDance/Sa2VA-1B resolves offline)
"$VENV/bin/hf" download ByteDance/Sa2VA-1B --revision "$MODEL_REVISION"
# make refs/main point at the pinned revision
mkdir -p /root/.cache/huggingface/hub/models--ByteDance--Sa2VA-1B/refs
echo -n "$MODEL_REVISION" > /root/.cache/huggingface/hub/models--ByteDance--Sa2VA-1B/refs/main

echo "setup done"
