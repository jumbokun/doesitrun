# GroundingDINO on RTX 5060 Laptop (sm_120) — what broke, what changed

Target: README install with the CUDA extension compiled, Swin-T OGC weights, and
`demo/inference_on_a_image.py` running on `.asset/cat_dog.jpeg` on the GPU.

Environment built by `setup.sh`: venv at `/work/venv` (Python 3.12), repo at
`/work/GroundingDINO` pinned to commit `856dde2`, weights in `weights/`,
HF cache in `/work/hf-cache`. Source `/work/env.sh` to use it.

## What broke following the README

1. **`pip install -e .` fails immediately.** Modern pip builds in an isolated env where
   `torch` is absent; `setup.py` imports torch at build time and its `install_torch()`
   fallback (`python -m pip install torch`) also fails inside that env.
   → Installed deps first and built with `pip install --no-build-isolation -e .`.
2. **No sm_120 kernels.** `requirements.txt` says just `torch`; the default PyPI wheel has
   no Blackwell support. → Pinned `torch==2.8.0+cu128` / `torchvision==0.23.0+cu128` from
   the PyTorch cu128 index and built with `TORCH_CUDA_ARCH_LIST=12.0`, `CUDA_HOME=/usr/local/cuda`.
3. **`fatal error: Python.h: No such file or directory`.** → `apt-get install python3-dev`.
4. **Extension would not compile against torch 2.8:**
   `no suitable conversion from "const at::DeprecatedTypeProperties" to "c10::ScalarType"`
   at `ms_deform_attn_cuda.cu:65,135`. `AT_DISPATCH_FLOATING_TYPES` no longer takes
   `Tensor::type()`. → Patched both call sites to `value.scalar_type()`. (The rest of the
   deprecated API in that file — `.type().is_cuda()`, `.data<T>()`, `THC/THCAtomics.cuh` —
   still compiles with torch 2.8.)
5. **`import groundingdino._C` alone raised `ImportError: libc10.so: cannot open shared
   object file`** (it only works if `torch` was imported first; the README's `_C` warning
   looks the same from the outside). → Two fixes: `groundingdino/__init__.py` now does
   `import torch`, and `patchelf --set-rpath <torch>/lib` is applied to the built
   `_C.cpython-312-x86_64-linux-gnu.so`.
6. **`AttributeError: 'BertModel' object has no attribute 'get_extended_attention_mask'`**
   at model build time — unpinned `transformers` resolves to 5.x, which removed that method
   that `bertwarper.py` relies on. → Pinned `transformers==4.46.3` (pulls
   `tokenizers==0.20.3`, `huggingface_hub==0.36.2`).
7. **`import cv2` (dep of `groundingdino.util.inference`) failed on `libxcb.so.1`.**
   → `apt-get install libgl1 libglib2.0-0 libxcb1`; kept the documented `opencv-python`.

Also pre-fetched `bert-base-uncased` (the config's `text_encoder_type`) into `HF_HOME`
so the demo does not depend on a Hugging Face download at run time.

## Verified

`setup.sh` was re-run from an empty `/work` (repo, venv, caches and weights removed), then:

```
source /work/env.sh && cd /work/GroundingDINO
python -c "import groundingdino._C"            # OK
python demo/inference_on_a_image.py -c groundingdino/config/GroundingDINO_SwinT_OGC.py \
  -p weights/groundingdino_swint_ogc.pth -i .asset/cat_dog.jpeg -o logs/final -t "cat . dog ."
# -> logs/final/pred.jpg (1200x901)
```

The CUDA kernel is really used: `MultiScaleDeformableAttnFunction.apply(...)` on CUDA tensors
returns a result, and `predict()` on the demo image gives `['cat', 'dog']` with logits
`0.82 / 0.57` and plausible boxes.
