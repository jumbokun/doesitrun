# PaddleFormers README quickstart on CPU

The README only documents GPU installs (CUDA ≥ 13 / cu126 indexes + `paddleformers[paddlefleet]`).
Option 3 (plain `pip install paddleformers`) is described as "tokenizer only", and that turned out to be accurate:
the tokenizer snippet works, but the generation snippet fails on CPU.

What broke, and what I changed (repo pinned at b52811b3; patch embedded in setup.sh):

1. **No CPU install instructions.** I installed CPU `paddlepaddle==3.3.1` from PyPI, then `pip install -e .`,
   in a uv venv (Python 3.12).
2. **`import pip` at import time.** `paddleformers/utils/import_utils.py` imports pip, and a uv venv has none,
   so every `AutoTokenizer` import failed. Fix: `uv venv --seed`.
3. **Qwen3 needs paddlefleet.** `qwen3/modeling.py` always imports `gpt_provider`, which raises without
   paddlefleet, and `Qwen3ForCausalLM` is now Fleet-only. paddlefleet depends on `paddlepaddle-gpu` and the
   CUDA-only `paddlefleet_ops`, so it can't run here. Patch: import the provider only if paddlefleet is
   available. Otherwise, alias `Qwen3ForCausalLM`/`Qwen3ForCausalLMPipe` to the existing pure-Paddle
   `*Deprecated` classes.
4. **`fused_rms_norm_ext` has no CPU kernel.** Also, `detect_device()` returns "gpu" on a CPU-only machine.
   Patch in `nn/norm.py`: use the unfused RMSNorm path when the tensor is on CPU.
5. **No bfloat16 matmul on CPU** in Paddle 3.3.1 (or the 3.5 nightly). Patch in `model_utils.from_pretrained`:
   on CPU, load bf16/fp16 as float32 and log a warning. This lets the README's `dtype="bfloat16"` call run unchanged.

Result: the tokenizer gives `[105492, 104773]`. Generation produces a coherent Chinese introduction to large
models, and "中华人民共和国的首都是" continues with 北京. A 256-token generation takes about 40 s on 4 CPUs.
