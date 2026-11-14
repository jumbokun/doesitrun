# PaddleFormers README quickstart on CPU

Setup: `uv venv --seed` (Python 3.12) at /work/.paddleformers-work, CPU `paddlepaddle==3.3.1` from
the Paddle CPU index, then `pip install -e .` (no `[paddlefleet]` extra) at commit f7fa77f02e. Qwen3-0.6B-Base
gets pre-downloaded to the HF cache. The source changes are in /work/patches/cpu_no_paddlefleet.patch.

What broke, and what I did about it:
1. The README only documents CUDA installs (Docker or the cu126/129/130 indexes). Paddle isn't in requirements.txt.
   -> I installed `paddlepaddle` from https://www.paddlepaddle.org.cn/packages/stable/cpu/.
2. `[paddlefleet]` pins `paddlefleet==0.4.0.post20260909+08dd2e727b0`, and that version isn't on any index.
   paddlefleet is also GPU-only. -> I skipped the extra.
3. `paddleformers.utils.import_utils` does `import pip`, and a uv venv ships without pip, so
   `import AutoTokenizer` fails. -> I create the venv with `--seed` and also install pip.
4. qwen2/qwen3 `modeling.py` import `gpt_provider` unconditionally, and `gpt_provider` raises without paddlefleet.
   The default `Qwen3ForCausalLM` is also built on paddlefleet. -> I patched the import to be optional, and
   `Qwen3ForCausalLM`/`...Pipe` (plus the Qwen2 ones) now point to the existing non-fleet `*Deprecated` classes
   when paddlefleet is missing.
5. RMSNorm calls the `fused_rms_norm_ext` kernel, which doesn't exist on CPU. -> The plain path is now used
   on CPU (`paddleformers/nn/norm.py`).
6. CPU Paddle has no bfloat16 matmul, so the README's `dtype="bfloat16"` fails. -> On CPU,
   `from_pretrained` now falls back to float32 and logs a warning (`model_utils.py`).

Result: the tokenizer gives [105492, 104773]. Generating 256 tokens on 4 CPU cores takes about 25 s and
returns coherent Chinese text. As in the README, `generate` returns only the new tokens.
