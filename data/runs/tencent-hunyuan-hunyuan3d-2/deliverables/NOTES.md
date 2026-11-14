# Hunyuan3D-2 – CPU setup notes

Setup: uv venv (Python 3.12) at /work/venv, CPU PyTorch wheels, `pip install -r requirements.txt`, `pip install -e .`.
Weights (`tencent/Hunyuan3D-2mini`, subfolder `hunyuan3d-dit-v2-mini-turbo`) are pre-downloaded to HF_HOME=/work/hf_cache.

What broke:
1. requirements.txt is unpinned, so it pulls transformers 5.x. Its Dinov2 module layout was changed
   (q_proj/gate_proj... instead of attention.attention.query / mlp.weights_in), and
   `conditioner.load_state_dict` fails with missing/unexpected keys. Fix: pin `transformers>=4.48,<5`.
2. Pinning transformers<5 downgrades huggingface_hub to 0.x. The latest diffusers (0.43) then fails to import
   (`resolve_revision` missing). Fix: pin `diffusers<0.36` (0.35.2 got installed).
3. README gives no CPU torch install. I used the CPU wheel index (download.pytorch.org/whl/cpu).
   I also installed libgl1/libglib2.0-0 for opencv.

Result: 5-step mini-turbo on CPU (4 cores), octree_resolution=128: about 13 min, giving a 40k-vertex / 80k-face GLB.
Diffusion takes about 60 s/step; volume decoding dominates the runtime. The default octree_resolution=256 decode takes about 50 min on CPU.
No code changes were needed.
