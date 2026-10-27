# detectron2 CPU setup notes

Followed INSTALL.md ("python -m pip install -e detectron2" from a local clone) with CPU-only torch 2.x (Python 3.12 venv via uv).

What broke / what I changed:
1. **Build isolation**: setup.py imports torch, so `pip install -e` under PEP 517 build isolation can't see torch. Installed with `--no-build-isolation` after installing torch/torchvision (CPU wheels from download.pytorch.org/whl/cpu).
2. **Python.h missing**: the C++ extension build needs Python headers -> `apt install python3-dev` (plus ninja-build).
3. **OpenCV**: not installed by detectron2 ("optional") but required by the demo -> `opencv-python-headless`. Also installed libgl1/libglib2.0-0.
4. **CPU-only build**: CUDA 12.8 is in the image, so set `FORCE_CUDA=0` and an empty `CUDA_HOME` to keep the build CPU-only.
5. **demo.py import bug**: `from vision.fair.detectron2.demo.predictor import VisualizationDemo` (a Meta-internal path) -> `ModuleNotFoundError: vision`. Patched it to `from predictor import VisualizationDemo`.
6. **--output robustness**: when `--output` names a directory that doesn't exist yet, upstream treats it as a file name (it writes `<dir>.png`). Patched demo.py so a path that doesn't exist and has no extension is created as a directory.
7. setup.sh downloads the checkpoint ahead of time into the fvcore/iopath cache (~/.torch/iopath_cache) and fetches a sample COCO image to /work/sample/input.jpg.

Verified: the demo on a COCO val2017 image detected 15 instances and wrote a 640x480 annotated image (mean abs diff from the input is about 18.7).
