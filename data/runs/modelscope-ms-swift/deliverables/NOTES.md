# ms-swift CPU Quick Start notes

The README install path (`uv pip install -e . --torch-backend=auto`) and the CLI worked with no code changes. These are the CPU-specific adjustments:

- **torch is not in requirements**: `requirements/framework.txt` doesn't list torch, so I installed it explicitly with `uv pip install torch torchvision --torch-backend=cpu`. I also used `--torch-backend=cpu` for the editable install so no CUDA wheels are pulled. The result is torch 2.14.1+cpu, transformers 5.19.0, peft 0.20.0, in a Python 3.12 uv venv at /work/venv.
- **Quick Start scaled down for CPU**, as the task asked: Qwen/Qwen2.5-0.5B-Instruct, only `swift/self-cognition#40`, `--torch_dtype float32`, `--max_steps 5`, `--max_length 512`, `--dataloader_num_workers 0`, and `CUDA_VISIBLE_DEVICES=""`.
- **Inference**: the README shows interactive `swift infer`. For batch use I passed `--val_dataset /work/test.jsonl --result_path /work/infer_result.jsonl`, which is a documented argument but not shown in the Quick Start.
- **Paths**: the checkpoint is symlinked at /work/checkpoint, and env.sh activates the venv and sets `CUDA_VISIBLE_DEVICES=""`.
