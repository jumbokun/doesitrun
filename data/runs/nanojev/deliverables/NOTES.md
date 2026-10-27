# NanoJev on this box — what broke, what changed

Target: README "Quick start" → CUDA inference → `scripts/serve_decisions.py` on
`127.0.0.1:8765`, answering `POST /api/evaluate`.

## What broke following the README literally

1. **`python -m pip install -r requirements-toy.txt huggingface_hub`.**
   On Ubuntu 24.04 there is no `python` on `PATH`, and the system `python3` is
   PEP-668 externally managed, so installing into it is refused. Fixed by
   creating a venv (`uv venv --python 3.12 /work/venv`) and installing the
   **unchanged** pins from `requirements-toy.txt` (torch 2.14.0,
   transformers 5.17.0, safetensors 0.8.0, numpy 2.5.3) plus `huggingface_hub`
   into it. `env.sh` activates that venv, which is what makes `python` exist.

2. **Flat imports across `scripts/`.** `serve_decisions.py` does
   `from predict_toy_decisions import ...`, which in turn loads
   `train_toy_decisions.py` by path for the `DecisionModel` class. That only
   resolves when `scripts/` is on `sys.path` — true when you launch
   `python scripts/serve_decisions.py`, false for anything else. `env.sh`
   exports `PYTHONPATH=/work/NanoJev/scripts` so the scripts also work from an
   arbitrary cwd.

3. **triton's JIT shim needs `Python.h`.** Any entry point that does *not* pass
   `--disable-native-triton` (e.g. the one-shot
   `scripts/predict_toy_decisions.py` CLI) makes torch compile
   `triton/backends/nvidia/driver.c` with gcc, which fails with
   `fatal error: Python.h: No such file or directory` on the base image.
   `setup.sh` installs `python3-dev`. The README's documented server command
   does pass `--disable-native-triton` and was never affected.

4. **Startup looks like a hang.** The server prints its ready line only after
   loading the 0.6B backbone in fp32 onto the GPU — ~75–90 s here, with no
   output before that. `run.sh` therefore polls `/api/health` (up to 900 s)
   instead of assuming a fixed delay, and fails fast if the process dies.

## What did *not* need changing

No repository file was patched. The hardware path works as documented:
`requirements-toy.txt`'s `torch==2.14.0` resolves to the default `+cu130`
wheel, which ships `sm_120` kernels and bf16 support, so the RTX 5060 Laptop
(Blackwell) runs the checkpoint as-is — fp32 weights with bf16 autocast,
~2.4 GB VRAM resident out of 8 GB. `--disable-native-triton` works because
`torch._native.triton_utils.deregister_op_overrides` exists in torch 2.14.

The repo also ships a ViZDoom/replay stack (`requirements-vizdoom.txt`,
`web/dev/*`, demo capture scripts). None of it is needed for the inference
service, so it is not installed.

## Layout

- `/work/setup.sh` — apt bits, clone, venv + pinned deps, GPU sanity check,
  `snapshot_download` of `C-Tianyu/NanoJev` and `C-Tianyu/NanoJev-Data` at
  revision `unified-games-v1` (Quick start verbatim, with retries because the
  anonymous Hub endpoint rate-limits), then a checkpoint-completeness check.
  Idempotent; no credentials anywhere.
- `/work/env.sh` — activates `/work/venv`, sets `PYTHONPATH`, forces the
  HF offline flags the predictor sets for itself anyway.
- `/work/run.sh` — kills a stale server, starts the README command under
  `nohup` logging to `/work/server.log`, blocks until `/api/health` answers.
- Checkpoint: `/work/NanoJev/checkpoints/NanoJev-unified` (2.3 GB).
  Dataset: `/work/NanoJev/data/NanoJev-unified` (0.93 GB).

## Verified here

Cold run (caches cleared, repo and venv deleted): `setup.sh` 11 min →
`source env.sh` → `run.sh` 85 s → `GET /api/health` `200 {"ready":true,...}`
→ `POST /api/evaluate` `200` with a `boolean` answer
(`p_true`/`probabilities`/`value`), also exercised `choice` and `score`
questions. GPU memory 894 MiB → 3271 MiB after load, `"device": "cuda:0"`,
`"forward_autocast": "bfloat16"`, `"autoregressive_decode_steps": 0` in the
response.
