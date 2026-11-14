# Model-Optimizer CPU setup notes
- README source install is `pip install -e .[dev]`. That pulls the full dev/test stack (plus the `onnx` extra's cupy-cuda13x / onnxruntime-gpu, and deepspeed), and the default torch wheel is the CUDA build. None of that is needed for CPU PTQ, so I didn't use it.
- What I did instead: made a uv venv (Python 3.12), installed CPU-only torch from download.pytorch.org/whl/cpu first, then ran `pip install -e .` with transformers pinned to the range from the `hf` extra (>=5.5,<5.19) plus accelerate.
- I didn't need to patch any code. On CPU, `mtq.quantize(model, INT8_DEFAULT_CFG, forward_loop)` on a tiny random LlamaForCausalLM inserted 56 TensorQuantizers. All 28 enabled ones were calibrated (amax set), and the logits were finite with a max diff of about 1e-2 from the original.
- env.sh activates /work/venv and sets CUDA_VISIBLE_DEVICES="".
