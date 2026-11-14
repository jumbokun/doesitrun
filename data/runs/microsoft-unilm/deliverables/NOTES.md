# unilm/e5 MTEB eval (e5-small-v2) on CPU

**What broke:** `pip install -r requirements.txt` was fine (in a uv venv with Python 3.12, using CPU torch wheels). The eval script assumes a GPU, though, so the run failed with
`AssertionError: Torch not compiled with CUDA enabled` (from `self.encoder.cuda()`). It also hard-codes fp16 loading,
`torch.cuda.amp.autocast()`, `batch_size = 64 * gpu_count` (this is 0 on CPU), and `move_to_cuda()`.

**Changes (`/work/cpu_patch.py`, applied by setup.sh, idempotent, keeps the CRLF line endings):**
- `mteb_except_retrieval_eval.py`: load in fp32 and skip `.cuda()` when there is no CUDA, use a batch size of at least 64, and turn autocast off on CPU.
- `utils.py`: `move_to_cuda` does nothing when there is no CUDA.

**Other:** I used a venv (`/work/venv`) and the PyTorch CPU wheel index. Versions are pinned to the resolved set I tested
(`requirements.lock.txt`, embedded in setup.sh), because requirements.txt is almost entirely unpinned. That set includes torch 2.15 cpu, transformers 5.23, datasets 5.2, and mteb 1.0.2.

**Result:** STS12 test cos_sim Spearman = 0.7621, which matches the published e5-small-v2 score. Each run takes about 1 minute on 4 CPUs.
