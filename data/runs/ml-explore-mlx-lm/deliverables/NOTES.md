# mlx-lm on Linux CPU — notes

README path: `pip install mlx-lm`, then `mlx_lm.generate --prompt ...`.

What broke:
1. On Linux, `mlx` is only a dependency on macOS (`platform_system == 'Darwin'`), so a plain
   install has no MLX at all. The README doesn't mention the `[cpu]` extra; I installed
   `-e /work/mlx-lm[cpu]` (pulls mlx + mlx-cpu 0.32.4) into a uv venv (Python 3.12).
2. Generation is far too slow to use: one forward pass of the 3B 4-bit model took ~490 s.
   The cause is MLX's CPU quantized matmul with bf16/fp16 activations, which is 10–50x slower
   than fp32 on this x86 CPU (I tested mlx 0.29–0.32 and got the same result).
   Fix (code patch in `mlx_lm/utils.py:load`): when the default device is CPU, call
   `model.set_dtype(mx.float32)`. The scales and activations become fp32, while the packed 4-bit
   weights stay as they are. Set `MLX_LM_CPU_FLOAT32=0` to turn this off.
   After the fix, the CLI run takes about 2 min (~0.5 tok/s) and peak memory is ~2 GB.

Other details:
- setup.sh pins commit 56230fa02, applies the patch inline, and predownloads the model into
  `HF_HOME=/work/hf_cache`.
- env.sh activates `/work/.venv` and sets HF_HOME.
