# Sa2VA demo on CPU with ByteDance/Sa2VA-1B

## What the README says vs. what happened
- `bash setup_env.sh sa2va legacy` / `uv sync --extra=legacy` worked as written. Sa2VA-1B is
  InternVL2.5-based, so it needs the **legacy** extra. setup.sh runs the documented manual
  `uv sync --extra=legacy` in projects/sa2va, so the venv lives in `projects/sa2va/.venv` and not in `/tmp`.
  uv fetches Python 3.11, and CUDA torch 2.6 is installed but runs on CPU. flash-attn builds python-only.
- `demo.py` failed on CPU in several ways. Each one is fixed in `projects/sa2va/demo/demo.py`,
  and the patch is embedded in setup.sh:
  1. The model's remote code turns on FlashAttention2 whenever `flash_attn` can be imported, so on CPU
     you get "Flash Attention 2 is not available on CPU". Fix: pass `use_flash_attn=False` to `from_pretrained`.
  2. The remote code hard-codes `.cuda()` calls. Fix: on CPU, make `Tensor.cuda` a no-op.
  3. `torch_dtype="auto"` leaves about 860M params in fp32, while the code feeds bf16 inputs, so there is
     a dtype mismatch. Fix: `model.to(torch.bfloat16)`.
  4. demo.py always passes `processor=` to `predict_forward`, and the InternVL-based Sa2VA-1B rejects that
     argument (TypeError). Fix: only pass it when a processor exists (Qwen models).
  5. SAM2 hard-codes `torch.device("cuda")` in its inference state, and uses `autocast("cuda")`, which is
     disabled on CPU and then causes a float/bf16 conv mismatch. Fix: redirect both to CPU at runtime.
  6. `predict_forward` runs the SAM2 part with autograd on, which kept about 5 GB of activations per call.
     With 4 frames this hit the 12 GB memory limit and the process was OOM-killed. Fix: wrap the call in
     `torch.inference_mode()`. Peak memory is now about 7 GB for 4 frames.
- The model download is not a scripted README step, so setup.sh does it. The model is pinned to revision
  82faf06 and stored in HF_HOME=/work/hf_home. It is also symlinked at /work/models/Sa2VA-1B.

## Run
    source /work/env.sh   # activates venv, sets HF_HOME, cd /work/Sa2VA
    PYTHONPATH=. python projects/sa2va/demo/demo.py /work/frames --model_path ByteDance/Sa2VA-1B \
        --work-dir /work/out --text '<image>Please segment the man.'
Output: `Sure, [SEG].<|im_end|>`. Green mask overlays are written to /work/out (about 1 minute for 4 frames).
