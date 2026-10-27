# DiffSynth-Studio SD1.5 on CPU

README path (`pip install -e .` + run example) basically works; what had to change for CPU-only:

- **Python env**: created a uv venv (Python 3.12) at /work/venv; README just says `pip install -e .`.
- **CPU torch**: installed torch/torchvision from the PyTorch CPU wheel index first, to avoid the
  multi-GB CUDA wheels pulled by default (not needed, no GPU).
- **Example is CUDA-hardcoded**: `rand_device="cuda"`, and `from_pretrained` defaults `device` to
  `get_device_type()`. setup.sh generates `/work/sd15_cpu.py` from the example with
  `rand_device="cpu"`, `device="cpu"`, 20 steps, prompt 'a photo of an astronaut riding a horse on mars',
  output `/work/image.jpg`. Repo source itself is unpatched.
- **Model pre-download**: setup.sh pre-fetches the 4 needed SD1.5 components from ModelScope
  (no auth) into `DiffSynth-Studio/models/...`, the relative path the pipeline uses; env.sh `cd`s
  into the repo so it's found.

Run: `source /work/env.sh && python /work/sd15_cpu.py` -> 512x512 image in ~3.5 min on 4 CPUs.
