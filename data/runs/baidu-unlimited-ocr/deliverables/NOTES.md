# Unlimited-OCR-2 on CPU (Transformers path)

Following the README's Transformers instructions (Python 3.10, torch 2.13.0, transformers 4.52.1, ...) with CPU torch:

1. **CPU torch**: installed torch 2.13.0 / torchvision from the PyTorch CPU wheel index (no GPU; README targets an A800).
2. **triton missing**: `AutoModel.from_pretrained(..., trust_remote_code=True)` fails in transformers' `check_imports`
   because `sparse_gather_e2e_triton.py` imports `triton` at top level and triton isn't in the README's pip list
   (CPU torch doesn't pull it in). Installed `triton==3.8.0`; its kernels are only used when tensors are CUDA.
3. **Remote code assumes CUDA + bf16** (`modeling_unlimitedocr.py`), patched in the HF cache snapshot:
   - `images_seq_mask[...].unsqueeze(-1).cuda()` -> `.to(inputs_embeds.device)` (2 places).
   - The preprocessed image tensors are hardcoded to `torch.bfloat16`; with a float32 model, the SAM conv failed with
     "Input type (BFloat16) and bias type (float)". `_uocr_generate` now casts the images to the model's dtype.
4. The model is pinned to revision `90a9c06e…`, and `refs/main` is written so that `HF_HUB_OFFLINE=1` (set in env.sh) keeps
   using the patched local snapshot instead of fetching the remote code again.

With these changes, `model.infer(tokenizer, image_file=..., output_path=..., save_results=True)` with fp32 on CPU returns
the correct text for a simple 3-line image (~2 min on 4 cores) and writes result.md, result_raw.md, and the box image.
