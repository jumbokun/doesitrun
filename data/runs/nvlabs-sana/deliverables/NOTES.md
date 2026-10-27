# Sana diffusers SanaPipeline on CPU

- The README gives only the Python snippet plus "Upgrade your `diffusers>=0.32.0`"; it has no install
  step for this path, so I installed into a uv venv (/work/venv, Python 3.12): CPU torch from the
  PyTorch CPU index, diffusers (0.42.0), transformers, accelerate, sentencepiece, protobuf.
- The snippet targets CUDA (`pipe.to("cuda")`, `torch.Generator(device="cuda")`). On CPU I used "cpu" for both,
  plus the 600M 512px model, 512x512, and 8 steps. The repo code is unchanged.
- The model is pre-downloaded into HF_HOME=/work/hf_cache (env.sh sets it). No token needed.
- Verified: produced a 512x512 non-blank PNG (pixel std about 70). bf16 on a 4-core CPU is slow:
  about 34 s per step, and the whole run took about 10.5 min (most of the rest is VAE decode).
- Warnings that do no harm: `torch_dtype` is deprecated in favor of `dtype`, and AutoencoderDC fp32 casting.
