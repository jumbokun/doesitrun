# detectron2 CPU setup notes

Documented path: `pip install -e detectron2` (INSTALL.md) after installing PyTorch.

What broke / what I changed:
- Python env: venv (system Python 3.12) with CPU wheels torch 2.5.1 / torchvision 0.20.1 from the PyTorch CPU index (pinned for reproducibility).
- `pip install -e .` needs `--no-build-isolation`, otherwise the build env can't see torch (setup.py imports torch).
- C++ extension build failed: `Python.h: No such file or directory` -> installed `python3-dev` (not mentioned in README).
- OpenCV is "optional" but needed for the demo -> installed `opencv-python-headless` (plus apt `libgl1 libglib2.0-0`).
- **Code bug**: `demo/demo.py` imports `from vision.fair.detectron2.demo.predictor import VisualizationDemo` (Meta-internal path) -> `ModuleNotFoundError: vision`. Patched to `from predictor import VisualizationDemo`.
- setup.sh pre-downloads the model checkpoint into the iopath cache (~/.torch/iopath_cache) and a COCO test image to /work/test/input.jpg.

Verified: demo on a COCO val2017 image detected 15 instances on CPU and wrote a same-size annotated image.
