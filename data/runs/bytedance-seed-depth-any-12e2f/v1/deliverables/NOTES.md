# Depth-Anything-3 on CPU — notes

README path: `pip install xformers torch>=2 torchvision; pip install -e .` — this doesn't work on a CPU-only box.

What broke / what I changed:
1. **xformers** is a hard dependency in pyproject.toml, but it is CUDA-only, and the code only imports it inside a guarded try/except. I left it out with a uv override (`xformers; sys_platform == 'never'`). gsplat was skipped as well (optional).
2. **CPU torch**: installed torch/torchvision from the PyTorch CPU wheel index into a uv venv (Python 3.12) at /work/venv.
3. **Undeclared deps**: the code imports `addict` and `sklearn`, but pyproject doesn't list them. Fixed with `uv pip install addict scikit-learn`.
4. **CLI defaults to `--device cuda`**, so the run fails with "Torch not compiled with CUDA enabled". I patched `services/inference_service.py` (via /work/patch_cpu.py) to fall back to CPU when CUDA isn't available. Passing `--device cpu` works too.
5. Installed libgl1/libglib2.0-0 etc. for opencv/open3d (preventive).
6. DA3-SMALL weights are pre-downloaded into the HF cache by setup.sh.

Result: `da3 auto assets/examples/SOH --export-format mini_npz-glb --export-dir X --model-dir depth-anything/DA3-SMALL` takes about 10 s on CPU. It writes `X/exports/mini_npz/results.npz` (depth: (2,280,504)) and `X/scene.glb` (~2 MB).
