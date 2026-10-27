# T2I-Adapter SDXL diffusers quick start on CPU

What broke following the README:
- `pip install git+https://github.com/huggingface/diffusers.git@t2iadapterxl` installs a stale 2023 branch that
  fails to import with current huggingface_hub (`cannot import name 'hf_cache_home'`). T2I-Adapter SDXL support
  has long been merged upstream, so I used released `diffusers==0.35.2` (with transformers 4.57.1, accelerate 1.10.1).
- `pip install controlnet_aux==0.0.7` drags in the latest CUDA torch (~GBs) and opencv, which needs `libxcb1`/`libgl1`
  (not in the base image). I installed CPU torch 2.8.0 from the PyTorch CPU index, held it with a constraints file,
  and apt-installed libgl1 libglib2.0-0 libxcb1.
- No GPU: dropped `.to("cuda")` and `enable_xformers_memory_efficient_attention()`; used bfloat16 (fp32 also works)
  instead of float16; 512x512, 8 steps (~35 s of sampling on 4 cores).
- README typo `varient="fp16"` (silently ignored) -> `variant="fp16"`.

Setup: `/work/setup.sh` creates `/work/venv` (uv, Python 3.12) and pre-downloads all weights into
`HF_HOME=/work/hf_cache` (fp16-variant and fp32 SDXL weights, VAE fix, adapter, lineart annotator).
`source /work/env.sh` activates. Test script: `/work/test/quickstart_cpu.py` (synthetic line-art control image)
-> `/work/out_lin.png`.
