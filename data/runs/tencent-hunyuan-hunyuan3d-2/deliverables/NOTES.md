# Hunyuan3D-2 (mini-turbo shape gen, CPU) — notes

README path: install PyTorch, `pip install -r requirements.txt`, `pip install -e .`. Unpinned deps broke it.

What broke / what I changed:
1. **CPU torch** — installed torch/torchvision from the PyTorch CPU wheel index (README only says "install from the official site").
2. **transformers 5.x** (picked up unpinned) renamed Dinov2 internals, so loading the conditioner checkpoint failed with
   hundreds of missing/unexpected keys. Pinned `transformers>=4.48,<5` (4.57.6).
3. That pulled `huggingface_hub<1`, and the latest diffusers (0.42) needs hub>=1 (`resolve_revision` ImportError). Pinned `diffusers<0.36` (0.35.2).
4. **Code bug**: `Hunyuan3DDiTPipeline.enable_flashvdm()` reloads the turbo VAE without passing a dtype, so it uses
   ShapeVAE's default fp16. With a float32 pipeline on CPU you get `mat1 and mat2 must have the same dtype (Float vs Half)`.
   Patched `hy3dgen/shapegen/pipelines.py` to pass `dtype=self.dtype` (setup.sh does this with sed).
5. Installed libgl1/libglib2.0-0 (opencv/pymeshlab need them), and pre-downloaded the HF weights (`hunyuan3d-dit-v2-mini-turbo`,
   `hunyuan3d-vae-v2-mini-turbo`) into `HF_HOME=/work/hf_cache` plus rembg's default model into `U2NET_HOME=/work/u2net`.

I skipped the texture/CUDA extensions, as instructed.
Result: 5 steps at octree resolution 380 took about 200 s on 4 CPUs. The exported GLB has about 340k vertices and 680k faces, with a bbox of about [-1,1].
Test script: /work/scripts/test_shape.py
