#!/usr/bin/env bash
# Reproducible CPU-only setup for Swin-Transformer Swin-T ImageNet-1K evaluation.
set -euo pipefail
cd /work

# 1. clone (pinned to the commit this setup was tested against)
if [ ! -d Swin-Transformer/.git ]; then
  git clone https://github.com/microsoft/Swin-Transformer.git
fi
cd Swin-Transformer
git checkout -q f82860b

# 2. CPU adaptation (cuda -> cpu fallback, nccl -> gloo, torch.load weights_only=False)
#    plus clamp LR-scheduler steps to >=1 so tiny datasets (< batch size) work.
cat > /tmp/swin_cpu_support.patch <<'SWIN_PATCH_EOF'
diff --git a/main.py b/main.py
index 7fa03ca..35f1ccc 100644
--- a/main.py
+++ b/main.py
@@ -29,6 +29,10 @@ from logger import create_logger
 from utils import load_checkpoint, load_pretrained, save_checkpoint, NativeScalerWithGradNormCount, auto_resume_helper, \
     reduce_tensor
 
+# fall back to CPU (gloo backend) when CUDA is not available
+USE_CUDA = torch.cuda.is_available()
+DEVICE = torch.device('cuda') if USE_CUDA else torch.device('cpu')
+
 # pytorch major version (1.x or 2.x)
 PYTORCH_MAJOR_VERSION = int(torch.__version__.split('.')[0])
 
@@ -100,17 +104,18 @@ def main(config):
         flops = model.flops()
         logger.info(f"number of GFLOPs: {flops / 1e9}")
 
-    model.cuda()
+    model.to(DEVICE)
     model_without_ddp = model
 
     optimizer = build_optimizer(config, model)
-    model = torch.nn.parallel.DistributedDataParallel(model, device_ids=[config.LOCAL_RANK], broadcast_buffers=False)
+    model = torch.nn.parallel.DistributedDataParallel(model, device_ids=[config.LOCAL_RANK] if USE_CUDA else None,
+                                                      broadcast_buffers=False)
     loss_scaler = NativeScalerWithGradNormCount()
 
     if config.TRAIN.ACCUMULATION_STEPS > 1:
-        lr_scheduler = build_scheduler(config, optimizer, len(data_loader_train) // config.TRAIN.ACCUMULATION_STEPS)
+        lr_scheduler = build_scheduler(config, optimizer, max(1, len(data_loader_train) // config.TRAIN.ACCUMULATION_STEPS))
     else:
-        lr_scheduler = build_scheduler(config, optimizer, len(data_loader_train))
+        lr_scheduler = build_scheduler(config, optimizer, max(1, len(data_loader_train)))
 
     if config.AUG.MIXUP > 0.:
         # smoothing is handled with mixup label transform
@@ -184,13 +189,13 @@ def train_one_epoch(config, model, criterion, data_loader, optimizer, epoch, mix
     start = time.time()
     end = time.time()
     for idx, (samples, targets) in enumerate(data_loader):
-        samples = samples.cuda(non_blocking=True)
-        targets = targets.cuda(non_blocking=True)
+        samples = samples.to(DEVICE, non_blocking=True)
+        targets = targets.to(DEVICE, non_blocking=True)
 
         if mixup_fn is not None:
             samples, targets = mixup_fn(samples, targets)
 
-        with torch.cuda.amp.autocast(enabled=config.AMP_ENABLE):
+        with torch.cuda.amp.autocast(enabled=config.AMP_ENABLE and USE_CUDA):
             outputs = model(samples)
         loss = criterion(outputs, targets)
         loss = loss / config.TRAIN.ACCUMULATION_STEPS
@@ -205,7 +210,8 @@ def train_one_epoch(config, model, criterion, data_loader, optimizer, epoch, mix
             lr_scheduler.step_update((epoch * num_steps + idx) // config.TRAIN.ACCUMULATION_STEPS)
         loss_scale_value = loss_scaler.state_dict()["scale"]
 
-        torch.cuda.synchronize()
+        if USE_CUDA:
+            torch.cuda.synchronize()
 
         loss_meter.update(loss.item(), targets.size(0))
         if grad_norm is not None:  # loss_scaler return None if not update
@@ -217,7 +223,7 @@ def train_one_epoch(config, model, criterion, data_loader, optimizer, epoch, mix
         if idx % config.PRINT_FREQ == 0:
             lr = optimizer.param_groups[0]['lr']
             wd = optimizer.param_groups[0]['weight_decay']
-            memory_used = torch.cuda.max_memory_allocated() / (1024.0 * 1024.0)
+            memory_used = torch.cuda.max_memory_allocated() / (1024.0 * 1024.0) if USE_CUDA else 0
             etas = batch_time.avg * (num_steps - idx)
             logger.info(
                 f'Train: [{epoch}/{config.TRAIN.EPOCHS}][{idx}/{num_steps}]\t'
@@ -243,11 +249,11 @@ def validate(config, data_loader, model):
 
     end = time.time()
     for idx, (images, target) in enumerate(data_loader):
-        images = images.cuda(non_blocking=True)
-        target = target.cuda(non_blocking=True)
+        images = images.to(DEVICE, non_blocking=True)
+        target = target.to(DEVICE, non_blocking=True)
 
         # compute output
-        with torch.cuda.amp.autocast(enabled=config.AMP_ENABLE):
+        with torch.cuda.amp.autocast(enabled=config.AMP_ENABLE and USE_CUDA):
             output = model(images)
 
         # measure accuracy and record loss
@@ -267,7 +273,7 @@ def validate(config, data_loader, model):
         end = time.time()
 
         if idx % config.PRINT_FREQ == 0:
-            memory_used = torch.cuda.max_memory_allocated() / (1024.0 * 1024.0)
+            memory_used = torch.cuda.max_memory_allocated() / (1024.0 * 1024.0) if USE_CUDA else 0
             logger.info(
                 f'Test: [{idx}/{len(data_loader)}]\t'
                 f'Time {batch_time.val:.3f} ({batch_time.avg:.3f})\t'
@@ -284,16 +290,18 @@ def throughput(data_loader, model, logger):
     model.eval()
 
     for idx, (images, _) in enumerate(data_loader):
-        images = images.cuda(non_blocking=True)
+        images = images.to(DEVICE, non_blocking=True)
         batch_size = images.shape[0]
         for i in range(50):
             model(images)
-        torch.cuda.synchronize()
+        if USE_CUDA:
+            torch.cuda.synchronize()
         logger.info(f"throughput averaged with 30 times")
         tic1 = time.time()
         for i in range(30):
             model(images)
-        torch.cuda.synchronize()
+        if USE_CUDA:
+            torch.cuda.synchronize()
         tic2 = time.time()
         logger.info(f"batch_size {batch_size} throughput {30 * batch_size / (tic2 - tic1)}")
         return
@@ -312,8 +320,9 @@ if __name__ == '__main__':
     else:
         rank = -1
         world_size = -1
-    torch.cuda.set_device(config.LOCAL_RANK)
-    torch.distributed.init_process_group(backend='nccl', init_method='env://', world_size=world_size, rank=rank)
+    if USE_CUDA:
+        torch.cuda.set_device(config.LOCAL_RANK)
+    torch.distributed.init_process_group(backend='nccl' if USE_CUDA else 'gloo', init_method='env://', world_size=world_size, rank=rank)
     torch.distributed.barrier()
 
     seed = config.SEED + dist.get_rank()
diff --git a/utils.py b/utils.py
index 328ad09..3b15b13 100644
--- a/utils.py
+++ b/utils.py
@@ -21,7 +21,7 @@ def load_checkpoint(config, model, optimizer, lr_scheduler, loss_scaler, logger)
         checkpoint = torch.hub.load_state_dict_from_url(
             config.MODEL.RESUME, map_location='cpu', check_hash=True)
     else:
-        checkpoint = torch.load(config.MODEL.RESUME, map_location='cpu')
+        checkpoint = torch.load(config.MODEL.RESUME, map_location='cpu', weights_only=False)
     msg = model.load_state_dict(checkpoint['model'], strict=False)
     logger.info(msg)
     max_accuracy = 0.0
@@ -44,7 +44,7 @@ def load_checkpoint(config, model, optimizer, lr_scheduler, loss_scaler, logger)
 
 def load_pretrained(config, model, logger):
     logger.info(f"==============> Loading weight {config.MODEL.PRETRAINED} for fine-tuning......")
-    checkpoint = torch.load(config.MODEL.PRETRAINED, map_location='cpu')
+    checkpoint = torch.load(config.MODEL.PRETRAINED, map_location='cpu', weights_only=False)
     state_dict = checkpoint['model']
 
     # delete relative_position_index since we always re-init it
@@ -200,7 +200,7 @@ class NativeScalerWithGradNormCount:
     state_dict_key = "amp_scaler"
 
     def __init__(self):
-        self._scaler = torch.cuda.amp.GradScaler()
+        self._scaler = torch.cuda.amp.GradScaler(enabled=torch.cuda.is_available())
 
     def __call__(self, loss, optimizer, clip_grad=None, parameters=None, create_graph=False, update_grad=True):
         self._scaler.scale(loss).backward(create_graph=create_graph)
SWIN_PATCH_EOF
if git apply --check /tmp/swin_cpu_support.patch 2>/dev/null; then
  git apply /tmp/swin_cpu_support.patch
fi

# 3. python env (README's py3.7 / torch 1.8 + CUDA 10.2 is not usable here)
export UV_PYTHON_INSTALL_DIR=/work/.uv-python
[ -x /work/venv/bin/python ] || uv venv --python 3.10 /work/venv
uv pip install --python /work/venv/bin/python \
  --index-url https://download.pytorch.org/whl/cpu --extra-index-url https://pypi.org/simple \
  torch==2.4.1 torchvision==0.19.1 "numpy<2" \
  timm==0.4.12 termcolor==1.1.0 yacs==0.1.8 pyyaml scipy opencv-python-headless==4.10.0.84
# (fused window_process CUDA kernel skipped: CPU only, optional flag)

# 4. pretrained checkpoint
if [ ! -s swin_tiny_patch4_window7_224.pth ]; then
  curl -fL --retry 5 -o swin_tiny_patch4_window7_224.pth \
    https://github.com/SwinTransformer/storage/releases/download/v1.0.0/swin_tiny_patch4_window7_224.pth
fi
mkdir -p /work/checkpoints && cp -f swin_tiny_patch4_window7_224.pth /work/checkpoints/

# 5. tiny ImageFolder dataset for smoke testing (2 classes x 8 images per split)
/work/venv/bin/python - <<'PY'
import os, numpy as np
from PIL import Image
rng = np.random.default_rng(0)
for split in ("train", "val"):
    for c in ("class0", "class1"):
        d = f"/work/data/tiny/{split}/{c}"; os.makedirs(d, exist_ok=True)
        for i in range(8):
            Image.fromarray(rng.integers(0, 255, (256, 256, 3), dtype=np.uint8)).save(f"{d}/img{i}.jpg")
PY
echo "setup done"
