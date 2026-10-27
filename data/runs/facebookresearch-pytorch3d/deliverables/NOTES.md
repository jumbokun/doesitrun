# PyTorch3D CPU setup notes

Followed INSTALL.md "Install from a local clone" (`pip install -e .`).

What broke / what I changed:
- The documented runtime setup uses conda (`python=3.9`, `pytorch=1.13.0`, `pytorch-cuda=11.6`), which isn't in the image and contradicts the supported range listed just above it (PyTorch 2.1–2.4.1). I used a `uv` venv on the system Python 3.12 instead, with CPU wheels of torch 2.4.1 and torchvision 0.19.1 from download.pytorch.org/whl/cpu, plus `iopath`.
- The build failed with `Python.h: No such file or directory`. Fix: `apt-get install python3-dev`.
- `pip install -e .` with build isolation can't see torch, so I installed with `--no-build-isolation` (plus setuptools, wheel, ninja).
- The image has the CUDA toolkit, so I set `PYTORCH3D_FORCE_NO_CUDA=1` to make sure only the CPU extension is built.
- Pinned `numpy<2` as a precaution for torch 2.4.1. I didn't test whether it's actually needed.

Verified: `load_objs_as_meshes(cow.obj)` rendered with FoVPerspectiveCameras + MeshRasterizer + SoftPhongShader + PointLights on CPU gives a (1,512,512,4) RGBA image with about 32k textured foreground pixels. Test script: /work/test/render.py.
