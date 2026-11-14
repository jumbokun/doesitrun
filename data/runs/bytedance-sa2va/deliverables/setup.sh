#!/usr/bin/env bash
# Reproducible CPU-only setup for Sa2VA demo (projects/sa2va/demo/demo.py) with ByteDance/Sa2VA-1B.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
REPO_DIR=/work/Sa2VA
REPO_COMMIT=c2c28a683627c6900e9652c253e205e9ecf4e563
MODEL_REV=82faf06c93f6ce3fdc0ad3d45b57fd52c463daeb
export HF_HOME=/work/hf_home
export PATH="$HOME/.local/bin:$PATH"
command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh

mkdir -p /work
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://github.com/bytedance/Sa2VA "$REPO_DIR"
fi
cd "$REPO_DIR"
git checkout -q "$REPO_COMMIT"

# CPU patch for demo.py (flash-attn off, .cuda() no-op, bf16 cast, SAM2 cpu device/autocast,
# inference_mode, no `processor` kwarg for InternVL-based models).
git checkout -q -- projects/sa2va/demo/demo.py
git apply - <<'PATCH'
diff --git a/projects/sa2va/demo/demo.py b/projects/sa2va/demo/demo.py
index e5ff7c5..157bc89 100644
--- a/projects/sa2va/demo/demo.py
+++ b/projects/sa2va/demo/demo.py
@@ -78,12 +78,38 @@ def visualize(pred_mask, image_path, work_dir):
 if __name__ == "__main__":
     cfg = parse_args()
     model_path = cfg.model_path
+    # CPU fallback: the HF remote code hard-codes .cuda() and flash-attn.
+    cpu_kwargs = {}
+    if not torch.cuda.is_available():
+        torch.Tensor.cuda = lambda self, *args, **kwargs: self
+        cpu_kwargs['use_flash_attn'] = False
     model = AutoModelForCausalLM.from_pretrained(
         model_path,
         torch_dtype="auto",
         #device_map="auto",
-        trust_remote_code=True
+        trust_remote_code=True,
+        **cpu_kwargs
     )
+    if not torch.cuda.is_available():
+        # "auto" leaves some modules in fp32; the remote code feeds bf16 inputs.
+        model = model.to(torch.bfloat16)
+        # The SAM2 remote code uses autocast(device_type="cuda") and a hard-coded
+        # torch.device("cuda") inference state; redirect both to CPU.
+        _autocast = torch.autocast
+        def _cpu_autocast(device_type, *args, **kwargs):
+            if device_type == "cuda":
+                device_type = "cpu"
+            return _autocast(device_type, *args, **kwargs)
+        torch.autocast = _cpu_autocast
+        sam2_model = getattr(getattr(model, 'grounding_encoder', None), 'sam2_model', None)
+        if sam2_model is not None and hasattr(sam2_model, 'init_state'):
+            _init_state = sam2_model.init_state
+            def _cpu_init_state(*args, **kwargs):
+                state = _init_state(*args, **kwargs)
+                state["device"] = torch.device("cpu")
+                state["storage_device"] = torch.device("cpu")
+                return state
+            sam2_model.init_state = _cpu_init_state
     """
     # For distributed inference, uncomment the following lines to get device_map
     device_map=split_model(model_path)
@@ -124,25 +150,30 @@ if __name__ == "__main__":
         vid_frames.append(img)
 
 
+    # InternVL-based models (e.g. Sa2VA-1B/4B/8B) do not accept a `processor` kwarg.
+    predict_kwargs = {'processor': processor} if processor is not None else {}
+
     if cfg.select > 0:
         img_frame = vid_frames[cfg.select - 1]
 
         print(f"Selected frame {cfg.select}")
         print(f"The input is:\n{cfg.text}")
-        result = model.predict_forward(
-            image=img_frame,
-            text=cfg.text,
-            tokenizer=tokenizer,
-            processor=processor,
-        ) # type: ignore
+        with torch.inference_mode():  # avoid keeping the SAM2 autograd graph
+            result = model.predict_forward(
+                image=img_frame,
+                text=cfg.text,
+                tokenizer=tokenizer,
+                **predict_kwargs,
+            ) # type: ignore
     else:
         print(f"The input is:\n{cfg.text}")
-        result = model.predict_forward(
-            video=vid_frames,
-            text=cfg.text,
-            tokenizer=tokenizer,
-            processor=processor,
-        ) # type: ignore
+        with torch.inference_mode():  # avoid keeping the SAM2 autograd graph
+            result = model.predict_forward(
+                video=vid_frames,
+                text=cfg.text,
+                tokenizer=tokenizer,
+                **predict_kwargs,
+            ) # type: ignore
 
     prediction = result['prediction']
     print(f"The output is:\n{prediction}")
PATCH

# Python env: documented manual path (uv sync --extra=legacy for InternVL2.5-based Sa2VA-1B).
# Python 3.11 is fetched by uv. flash-attn builds python-only (FLASH_ATTENTION_SKIP_CUDA_BUILD in pyproject).
( cd projects/sa2va && uv sync --extra=legacy )

# Model weights (pinned revision) into HF cache; also expose a local path.
projects/sa2va/.venv/bin/hf download ByteDance/Sa2VA-1B --revision "$MODEL_REV"
SNAP="$HF_HOME/hub/models--ByteDance--Sa2VA-1B/snapshots/$MODEL_REV"
mkdir -p /work/models
ln -sfn "$SNAP" /work/models/Sa2VA-1B

# Sample frames from the bundled video for a quick test.
mkdir -p /work/frames
projects/sa2va/.venv/bin/python - <<'PY'
import cv2
cap = cv2.VideoCapture('/work/Sa2VA/assets/videos/gf_exp1.mp4')
n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
for k, i in enumerate(range(0, n, max(1, n // 4))[:4]):
    cap.set(cv2.CAP_PROP_POS_FRAMES, i)
    ok, f = cap.read()
    if ok:
        cv2.imwrite(f'/work/frames/{k:03d}.jpg', f)
PY
echo "[setup] done. source /work/env.sh, then from /work/Sa2VA:"
echo "  PYTHONPATH=. python projects/sa2va/demo/demo.py /work/frames --model_path ByteDance/Sa2VA-1B --work-dir /work/out --text '<image>Please segment the man.'"
