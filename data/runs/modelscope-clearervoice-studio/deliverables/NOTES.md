# ClearVoice FRCRN_SE_16K on CPU

The README path (`git clone`, `cd clearvoice`, `pip install --editable .`, then call the Python API) worked as written.
The FRCRN_SE_16K checkpoint downloaded on its own from HuggingFace into `clearvoice/checkpoints/`, and running on CPU
turned `samples/input.wav` (16 kHz, 38363 samples) into a non-silent 16 kHz wav of the same length.

Things I did that the README doesn't mention (for convenience/reproducibility, not to fix anything broken):
- Made a uv venv with Python 3.12 at /work/venv (the README doesn't say to use a venv).
- Installed CPU-only torch/torchaudio/torchvision from the PyTorch CPU index, pinned to the versions that worked
  (2.14.1 / 2.11.0 / 0.29.1), so the default CUDA wheels aren't pulled on a machine with no GPU.
- Installed ffmpeg via apt (the README marks it optional; it isn't needed for wav input).
- setup.sh runs the demo once so the checkpoint is already downloaded.
