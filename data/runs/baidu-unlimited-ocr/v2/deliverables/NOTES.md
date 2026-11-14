# Unlimited-OCR-2: Transformers single-page inference on CPU

The README path (`pip install torch==2.13.0 ...` then `.eval().cuda()` in bf16) assumes a GPU. To get it running on a CPU-only box in float32 I had to make these changes:

1. **CPU torch**: a plain `pip install torch==2.13.0` pulls the CUDA 13 build and the nvidia-* wheels. I installed `torch==2.13.0+cpu` / torchvision from `https://download.pytorch.org/whl/cpu` instead. Python 3.10 is in a uv venv at `/work/.venv`; all the other pins are as the README gives them.
2. **triton missing**: the remote code imports `sparse_gather_triton.py`, and transformers' `check_imports` refuses to load the model without `triton`. The README doesn't list it. I installed `triton==3.7.1`. Its kernels are only used when `q.is_cuda`, so the CPU run never calls them.
3. **Patches to the remote code** (`/work/patches/patch_model.py`, applied to the HF snapshot):
   - `modeling_unlimitedocr.py`: the pixel tensors were hard-cast to bf16, which breaks a float32 model (`Input type BFloat16 and bias type float`). They are now cast to the model's dtype.
   - `modeling_unlimitedocr.py`: two hard-coded `.cuda()` calls on `images_seq_mask` now use `.to(inputs_embeds.device)`.
   - `deepencoder.py`: SAM global attention built a full 4096x4096 rel-pos bias per head and was OOM-killed on a 16 GB machine, next to ~12.5 GB of float32 weights. It now computes attention in query chunks of 512 rows, which gives the same result.
   - The cached `transformers_modules` copy is deleted after patching, because transformers never refreshes it for a given commit hash.
4. **Model pinned**: I pinned `baidu/Unlimited-OCR-2` to revision `0480966938…` (refs/main points there), and `env.sh` sets `HF_HUB_OFFLINE=1`. This stops a newer upstream revision from replacing the patched code.
5. I cloned the repo with `GIT_LFS_SKIP_SMUDGE=1`, since its large PDFs aren't needed. The clone also reports an LFS pointer mismatch on `Unlimited-OCR.pdf`, which doesn't matter here.

Result: the README's single-page `model.infer(...)` in float32 on CPU returns the correct text. It takes about 2.5–3.5 min per page on 4 cores and peaks at about 12.7 GB RSS.
