# PyTorch3D CPU setup notes

Followed INSTALL.md "Install from a local clone" (`pip install -e .`), using a uv venv instead of conda.

What broke / what I changed:
- INSTALL.md's conda example (python 3.9, pytorch 1.13, CUDA 11.6) contradicts its own supported list (PyTorch 2.1–2.4.1). Used system Python 3.12 + torch 2.4.1 / torchvision 0.19.1 CPU wheels from download.pytorch.org, with numpy<2.
- `pip install -e .` with build isolation can't see torch (setup.py imports torch); used `--no-build-isolation` and pre-installed setuptools/wheel/ninja.
- Build failed with `Python.h: No such file or directory`: installed `python3-dev` via apt.
- Set FORCE_CUDA=0 so the CPU-only extension is built (the image has CUDA toolkit but no GPU; CPU torch makes this the default anyway).
- No code patches needed. Verified: cow.obj loads and renders to a (1,256,256,4) RGBA image with textured pixels on CPU.
