# Swin-Transformer: Swin-T IN-1K eval on CPU

Result: `python -m torch.distributed.run --nproc_per_node 1 main.py --eval --cfg configs/swin/swin_tiny_patch4_window7_224.yaml --resume swin_tiny_patch4_window7_224.pth --data-path /work/data/tiny`
(run from /work/Swin-Transformer after `source /work/env.sh`) prints
`Accuracy of the network on the 16 test images: ...` (the weights load with "All keys matched"; the accuracy is meaningless on random images).

## What broke following get_started.md
- The documented env (conda, Python 3.7, torch 1.8.0 + cudatoolkit 10.2) doesn't fit here: no conda, no GPU. I used a uv venv with Python 3.10 and torch 2.4.1/torchvision 0.19.1 CPU wheels, `numpy<2`, and timm==0.4.12 / yacs / termcolor as documented.
- opencv-python==4.4.0.46 has no wheel for py3.10 and the eval path doesn't use it, so I installed opencv-python-headless 4.10 instead.
- I skipped the fused `kernels/window_process` CUDA extension (it's optional and CUDA-only).
- main.py is hardcoded for CUDA/NCCL (`model.cuda()`, `.cuda()` on tensors, `torch.cuda.set_device`, `backend='nccl'`, DDP `device_ids`, `torch.cuda.synchronize/max_memory_allocated`). I patched it to fall back to CPU and the `gloo` backend when CUDA isn't available, and to disable AMP autocast on CPU.
- utils.py: `torch.load(..., weights_only=False)` for forward compatibility with torch>=2.6, and GradScaler is enabled only when CUDA is available.
- Tiny dataset: the train loader uses `drop_last=True` with batch size 128, so fewer than 128 train images gives 0 steps, and timm's CosineLRScheduler fails `assert t_initial > 0`, even in --eval mode. I clamped the steps to max(1, ...).
- `torch.distributed.launch` (from the docs) still works but is deprecated; `torch.distributed.run` works too.

All code changes are an embedded patch applied by setup.sh (repo pinned at f82860b). setup.sh also downloads the checkpoint
to /work/Swin-Transformer/ and /work/checkpoints/, and generates /work/data/tiny/{train,val}/{class0,class1}, with 8 images per class per split.
