# mlx-lm on Linux CPU

What broke following the README (`pip install mlx-lm` then `mlx_lm.generate ...`):

1. **The README doesn't mention that mlx is needed on Linux.** In pyproject, the `mlx` dependency only applies on macOS
   (`platform_system == 'Darwin'`). On Linux you have to install an extra, so I installed
   `-e /work/mlx-lm[cpu]`, which pulls in `mlx[cpu]` (0.32.4).
2. **Generation was unusably slow on CPU.** The default model stores scales and activations in bf16. MLX's
   CPU quantized matmul for bf16 runs about 40x slower than for fp32: about 140 s per token, so 64 tokens would take hours.
   This is the same in mlx 0.28 through 0.32.4. I added a small change to `mlx_lm/utils.py` (`load_model`): when the
   default device is the CPU, it calls `model.set_dtype(mx.float32)`. You can turn it off with `MLX_LM_CPU_FLOAT32=0`.
   After the change it runs at about 3 s per token. The CLI run takes about 3 minutes and prints
   "Mt. Everest is approximately 8,848 meters (29,029 feet) tall."

Setup: uv venv (Python 3.12) at /work/venv, HF cache at /work/hf_cache (downloaded in advance by setup.sh).
`env.sh` turns on the venv and sets HF_HOME.
