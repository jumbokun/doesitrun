# unilm/e5 – mteb_except_retrieval_eval.py on CPU

Result: `python mteb_except_retrieval_eval.py --model-name-or-path intfloat/e5-small-v2 --task-types STS --dry-run --output-dir <dir>`
writes `<dir>/STS12.json`, cos_sim spearman = 0.762 (CPU, fp32, about 1 min).

## What broke / what I changed
- The README's `pip install -r requirements.txt` installs fine (Python 3.10 venv via uv). mteb==1.0.2 still works with
  current transformers 5.x / datasets 5.x, so no extra pins were needed. I froze the resolved versions in setup.sh so reruns get the same environment.
- I installed CPU-only torch from the PyTorch CPU wheel index so the CUDA build doesn't get pulled.
- The script assumes a GPU (`.cuda()`, fp16 weights, `torch.cuda.amp.autocast`). On CPU, `batch_size = 64 * gpu_count` is 0,
  so `range()` raises an error. I patched `mteb_except_retrieval_eval.py` to:
  - load fp32 on CPU (fp16 only when CUDA is available)
  - move the model and inputs to CUDA only if it is available
  - use `torch.autocast(device_type='cuda', enabled=use_cuda)`
  - use `max(gpu_count, 1)` for the batch size
  (The file uses CRLF line endings, and the patch keeps them.)
- setup.sh pre-downloads intfloat/e5-small-v2 and the mteb/sts12-sts dataset (at the pinned revision) into the HF cache.
- env.sh activates /work/venv, sets CUDA_VISIBLE_DEVICES="", and cd's into /work/unilm/e5.
