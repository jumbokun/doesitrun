# GroundingDINO setup notes

Following the README (`export CUDA_HOME`, `pip install -e .`, wget weights) on Ubuntu 24.04 / CUDA 12.8 / RTX 5060 (sm_120) did not work as written:

- **Python env**: Ubuntu 24.04 system pip is externally-managed, so I used a uv venv (`/work/venv`, Python 3.12).
- **GPU compat**: Blackwell sm_120 needs a CUDA 12.8 torch build → `torch==2.7.1 torchvision==0.22.1` from the cu128 index; built with `TORCH_CUDA_ARCH_LIST=12.0`, `FORCE_CUDA=1`.
- **Build isolation**: `pip install -e .` builds in an isolated env with no torch/CUDA wheel → install with `--no-build-isolation` after torch.
- **Missing headers**: `Python.h` not found → `apt install python3-dev`.
- **Code patch (CUDA ext)**: `ms_deform_attn_cuda.cu` uses `AT_DISPATCH_FLOATING_TYPES(value.type(), ...)`, which no longer compiles with torch ≥2.6 → changed to `value.scalar_type()`.
- **Code patch (import)**: `from groundingdino import _C` failed with `libc10.so: cannot open shared object file` unless torch was imported first → added `import torch` to `groundingdino/__init__.py`.
- **Dependency pin**: `transformers==4.44.2` (GroundingDINO's BERT wrapper breaks with newer transformers releases), `numpy<2.3`.
- **System packages**: `libgl1 libglib2.0-0` for opencv.
- **Download**: no `wget` in the image → `curl` for the weights; I also pre-cache `bert-base-uncased` from HF.

Verified: `import groundingdino._C` works, and `demo/inference_on_a_image.py ... -t "cat . dog ."` runs on the GPU and writes pred.jpg (it finds a cat at 0.82 and a dog at 0.57).
