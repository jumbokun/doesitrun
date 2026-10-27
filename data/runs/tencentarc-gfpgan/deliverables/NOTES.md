# GFPGAN setup notes
README path (`pip install basicsr facexlib -r requirements.txt; python setup.py develop`) does not work as written on this image (Python 3.12, no pip in system python, latest torch/torchvision):
- basicsr 1.4.2 imports `torchvision.transforms.functional_tensor`, removed in torchvision >= 0.17; old basicsr/facexlib also have build/compat problems on Python 3.12 and NumPy 2.
- Changes: uv venv with Python 3.10; CPU torch 2.0.1 / torchvision 0.15.2 from the PyTorch CPU index; `numpy<2`, `opencv-python<4.11`; packages installed with `--no-build-isolation` (basicsr's setup.py imports torch); `uv pip install -e .` instead of `python setup.py develop`.
- System packages libgl1, libglib2.0-0 (for OpenCV) and wget.
- Weights (GFPGANv1.3, facexlib detection/parsing, RealESRGAN_x2plus) downloaded in setup.sh so inference needs no network.
- On CPU, inference_gfpgan.py skips the RealESRGAN background upsampler by itself (prints a warning), so `--bg_upsampler None` is not needed.
Checked: `python inference_gfpgan.py -i inputs/whole_imgs -o results -v 1.3 -s 2` took about 1 min on CPU and wrote 3 restored images at 2x size.
