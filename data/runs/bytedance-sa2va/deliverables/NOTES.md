# Sa2VA-1B demo on CPU — notes

Path followed: README "Quick Start" (`pip install projects/sa2va/demo/requirements.txt`, then
`python projects/sa2va/demo/demo.py FOLDER --model_path ... --work-dir OUT --text ...`).
The uv/`setup_env.sh` path needs `flash-attn==2.7.3` and CUDA torch, so it isn't usable on a CPU-only box.

## What broke and what I changed
- **flash_attn / CUDA torch**: dropped `flash_attn` from the demo requirements and installed CPU wheels of
  `torch==2.3.1` / `torchvision==0.18.1` in a Python 3.11 uv venv (`/work/venv`).
- **libGL.so.1 missing**: mmengine pulls in `opencv-python` (non-headless), so I installed `libgl1 libglib2.0-0t64` with apt.
- **transformers remote-code check**: loading `ByteDance/Sa2VA-1B` from the hub fails with "requires flash_attn",
  even though the model only uses it optionally. demo.py now removes `flash_attn` from `get_imports` when it isn't installed.
- **`predict_forward() got an unexpected keyword argument 'processor'`**: the Sa2VA-1B remote code is older
  than demo.py. demo.py now only passes `processor` when it isn't None.
- **Hardcoded `.cuda()`** in the remote code: on CPU, demo.py makes `Tensor.cuda`/`Module.cuda` do nothing.
  It also sets the SAM2 `init_state` device and storage_device to cpu (they were hardcoded to cuda).
- **bf16 on CPU is about 160x slower than fp32** on this CPU (no AVX512-bf16): on CPU, demo.py loads the model in fp32
  (`low_cpu_mem_usage=True` keeps the load peak low) and forces `preparing_for_generation(torch_dtype=float32)`.
- **OOM (12 GB cgroup)**: `predict_forward` isn't run under no_grad, so the SAM2 activations kept autograd state.
  demo.py now wraps the call in `torch.inference_mode()`.
- The model only predicts masks for the first 5 frames; the visualization loop is capped at `len(pred_masks)` so it
  doesn't hit an IndexError when the folder has more frames.
- Weights are downloaded into the default HF cache at a pinned revision. `env.sh` sets `HF_HUB_OFFLINE=1`.

On CPU, 5 frames take about 3 minutes. Output: `Sure, the segmentation result is [SEG].`, plus one overlay image per frame.
All demo.py changes are under `if not torch.cuda.is_available()` / flash_attn-missing guards (the patch is in setup.sh).
