# Depth-Anything-3 on CPU — notes

Followed README Installation (`pip install xformers torch>=2 torchvision`, `pip install -e .`) inside a
uv venv (Python 3.12). Skipped the optional gsplat / app extras (not needed for `da3 auto` to mini_npz-glb).

What broke / what changed:
- Torch: installed from the PyTorch CPU wheel index (download.pytorch.org/whl/cpu) to avoid the CUDA
  build on this CPU-only machine; xformers installs but its CUDA kernels are unused (the model falls
  back to a plain MLP FFN / SDPA, with just a warning).
- `addict` is imported by `depth_anything_3/model/da3.py` but isn't listed in pyproject -> installed it manually.
- `import cv2` failed with `libGL.so.1` missing -> apt install libgl1 libglib2.0-0 (libgomp1 for open3d).
- Pre-downloaded depth-anything/DA3-SMALL into the HF cache in setup.sh (it's public, no token needed).

Output layout: `scene.glb` goes at the root of the export dir and `results.npz` goes under
`<export-dir>/exports/mini_npz/` (that's where upstream writes it). depth/conf are (2,280,504),
extrinsics (2,3,4), intrinsics (2,3,3); the GLB point cloud has about 129k points.
