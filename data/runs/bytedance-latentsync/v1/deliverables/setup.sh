#!/usr/bin/env bash
# Reproducible CPU-only setup for LatentSync (bytedance/LatentSync, v1.6 checkpoints).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
WORK=${WORK:-/work}
REPO=$WORK/LatentSync
VENV=$WORK/venv
COMMIT=a229c3948406bc2cf6eaf4873e662e70c6a04746
export HF_HOME=$WORK/hf_cache

# 1. System packages (README uses conda for ffmpeg; we use apt instead)
apt-get update -qq
apt-get install -y -qq ffmpeg libgl1 libglib2.0-0 >/dev/null

# 2. Clone repo at a pinned commit
if [ ! -d "$REPO/.git" ]; then
    git clone https://github.com/bytedance/LatentSync "$REPO"
fi
cd "$REPO"
git fetch -q origin "$COMMIT" 2>/dev/null || true
git checkout -q -f "$COMMIT"

# 3. CPU patch (device selection, CPU face detection, fp32 affine, VAE slicing, mmap ckpt load)
git apply --whitespace=nowarn <<'PATCH'
diff --git a/latentsync/models/unet.py b/latentsync/models/unet.py
index 13722e0..a73a8da 100644
--- a/latentsync/models/unet.py
+++ b/latentsync/models/unet.py
@@ -496,7 +496,7 @@ class UNet3DConditionModel(ModelMixin, ConfigMixin):
         unet = cls.from_config(model_config).to(device)
         if ckpt_path != "":
             zero_rank_log(logger, f"Load from checkpoint: {ckpt_path}")
-            ckpt = torch.load(ckpt_path, map_location=device, weights_only=True)
+            ckpt = torch.load(ckpt_path, map_location=device, weights_only=True, mmap=True)
             if "global_step" in ckpt:
                 zero_rank_log(logger, f"resume from global_step: {ckpt['global_step']}")
                 resume_global_step = ckpt["global_step"]
diff --git a/latentsync/pipelines/lipsync_pipeline.py b/latentsync/pipelines/lipsync_pipeline.py
index 693155e..27428c1 100644
--- a/latentsync/pipelines/lipsync_pipeline.py
+++ b/latentsync/pipelines/lipsync_pipeline.py
@@ -339,7 +339,7 @@ class LipsyncPipeline(DiffusionPipeline):
         # 0. Define call parameters
         device = self._execution_device
         mask_image = load_fixed_mask(height, mask_image_path)
-        self.image_processor = ImageProcessor(height, device="cuda", mask_image=mask_image)
+        self.image_processor = ImageProcessor(height, device=device.type, mask_image=mask_image)
         self.set_progress_bar_config(desc=f"Sample frames: {num_frames}")
 
         # 1. Default height and width to unet
diff --git a/latentsync/utils/face_detector.py b/latentsync/utils/face_detector.py
index faa55c9..749d8fe 100644
--- a/latentsync/utils/face_detector.py
+++ b/latentsync/utils/face_detector.py
@@ -10,9 +10,10 @@ class FaceDetector:
         self.app = FaceAnalysis(
             allowed_modules=["detection", "landmark_2d_106"],
             root="checkpoints/auxiliary",
-            providers=["CUDAExecutionProvider"],
+            providers=["CPUExecutionProvider"] if device == "cpu" else ["CUDAExecutionProvider"],
         )
-        self.app.prepare(ctx_id=cuda_to_int(device), det_size=(INSIGHTFACE_DETECT_SIZE, INSIGHTFACE_DETECT_SIZE))
+        ctx_id = -1 if device == "cpu" else cuda_to_int(device)
+        self.app.prepare(ctx_id=ctx_id, det_size=(INSIGHTFACE_DETECT_SIZE, INSIGHTFACE_DETECT_SIZE))
 
     def __call__(self, frame, threshold=0.5):
         f_h, f_w, _ = frame.shape
diff --git a/latentsync/utils/image_processor.py b/latentsync/utils/image_processor.py
index 5ac9f4e..ff386a9 100644
--- a/latentsync/utils/image_processor.py
+++ b/latentsync/utils/image_processor.py
@@ -39,17 +39,15 @@ class ImageProcessor:
         )
         self.normalize = transforms.Normalize([0.5], [0.5], inplace=True)
 
-        self.restorer = AlignRestore(resolution=resolution, device=device)
+        dtype = torch.float32 if device == "cpu" else torch.float16
+        self.restorer = AlignRestore(resolution=resolution, device=device, dtype=dtype)
 
         if mask_image is None:
             self.mask_image = load_fixed_mask(resolution)
         else:
             self.mask_image = mask_image
 
-        if device == "cpu":
-            self.face_detector = None
-        else:
-            self.face_detector = FaceDetector(device=device)
+        self.face_detector = FaceDetector(device=device)
 
     def affine_transform(self, image: torch.Tensor) -> np.ndarray:
         if self.face_detector is None:
diff --git a/scripts/inference.py b/scripts/inference.py
index ae2ff67..0876441 100644
--- a/scripts/inference.py
+++ b/scripts/inference.py
@@ -33,6 +33,7 @@ def main(config, args):
     # Check if the GPU supports float16
     is_fp16_supported = torch.cuda.is_available() and torch.cuda.get_device_capability()[0] > 7
     dtype = torch.float16 if is_fp16_supported else torch.float32
+    device = "cuda" if torch.cuda.is_available() else "cpu"
 
     print(f"Input video path: {args.video_path}")
     print(f"Input audio path: {args.audio_path}")
@@ -49,7 +50,7 @@ def main(config, args):
 
     audio_encoder = Audio2Feature(
         model_path=whisper_model_path,
-        device="cuda",
+        device=device,
         num_frames=config.data.num_frames,
         audio_feat_length=config.data.audio_feat_length,
     )
@@ -57,6 +58,9 @@ def main(config, args):
     vae = AutoencoderKL.from_pretrained("stabilityai/sd-vae-ft-mse", torch_dtype=dtype)
     vae.config.scaling_factor = 0.18215
     vae.config.shift_factor = 0
+    if device == "cpu":
+        # Encode/decode one frame at a time to keep CPU RAM usage bounded
+        vae.enable_slicing()
 
     unet, _ = UNet3DConditionModel.from_pretrained(
         OmegaConf.to_container(config.model),
@@ -71,7 +75,7 @@ def main(config, args):
         audio_encoder=audio_encoder,
         unet=unet,
         scheduler=scheduler,
-    ).to("cuda")
+    ).to(device)
 
     # use DeepCache
     if args.enable_deepcache:
PATCH

# 4. Python 3.10 venv (uv instead of conda), CPU torch + CPU onnxruntime
uv venv -q --allow-existing -p 3.10.13 "$VENV"
uv pip install -q --python "$VENV/bin/python" torch==2.5.1 torchvision==0.20.1 \
    --index-url https://download.pytorch.org/whl/cpu
grep -v -e '^--extra-index-url' -e '^torch' -e '^onnxruntime-gpu' requirements.txt > "$WORK/requirements-cpu.txt"
echo "onnxruntime==1.21.0" >> "$WORK/requirements-cpu.txt"
uv pip install -q --python "$VENV/bin/python" -r "$WORK/requirements-cpu.txt"

# 5. Checkpoints (as in setup_env.sh) + VAE + InsightFace buffalo_l, so inference needs no downloads
source "$VENV/bin/activate"
huggingface-cli download ByteDance/LatentSync-1.6 whisper/tiny.pt --local-dir checkpoints
huggingface-cli download ByteDance/LatentSync-1.6 latentsync_unet.pt --local-dir checkpoints
huggingface-cli download stabilityai/sd-vae-ft-mse config.json diffusion_pytorch_model.safetensors
python -c "from latentsync.utils.face_detector import FaceDetector; FaceDetector(device='cpu')"

echo "Setup complete."
