# HY-World-2.0 WorldMirror 2.0 on CPU – notes

The README assumes CUDA 12.8 + a GPU. Following it on a CPU-only machine fails in several places:

1. **Python env**: README uses conda (py 3.11.15). Used `uv venv -p 3.11` at /work/venv.
2. **torch**: `requirements.txt` pins torch 2.7.1 (default CUDA wheels). Installed the
   `+cpu` builds of torch 2.7.1 / torchvision 0.22.1 from the PyTorch CPU index.
3. **cupy==13.6.0**: CUDA-only and not used by worldrecon. Dropped it from requirements.
4. **gsplat**: both the bundled `gsplat_maskgaussian` and `pip install git+...gsplat` build CUDA
   extensions and fail without CUDA_HOME/nvcc. The PyPI `gsplat` wheel is pure Python (JIT) and
   imports fine on CPU. The CLI only imports it; rendering isn't used by default.
5. **flash-attn**: needs CUDA. `attention.py` hard-imports flash_attn v3 or v2. Patched it so the
   import is optional and attention falls back to `F.scaled_dot_product_attention` when flash-attn
   isn't present or the tensors are not on CUDA.
6. **libGL.so.1 missing**: opencv-python needs `libgl1` and `libglib2.0-0t64` from apt.
7. Not strictly required: the weights (HF `tencent/HY-World-2.0`, `HY-WorldMirror-2.0/*`) and
   `skyseg.onnx` are downloaded during setup. The pipeline downloads `skyseg.onnx` into the
   *current directory*, so env.sh `cd`s into the repo.

Result: on 4 CPU cores, the Desk example at `--target_size 518` takes about 75 s and writes
depth/, normal/, camera_params.json, points.ply and gaussians.ply. The log line
"Loaded 1545/1593 keys" is expected: the 48 missing keys are RoPE `periods` buffers, which are
computed rather than loaded. When stdin is not a TTY/EOF, the CLI's interactive prompt exits
right away.
