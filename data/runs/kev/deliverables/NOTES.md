# Kev on an 8 GB RTX 5060 (sm_120)

Served checkpoint: **Kev-0.8B** (`jaredpalmer/kev-0.8b`), bf16, `--device cuda`, port 8009.

```
source /work/env.sh && /work/run.sh     # ready in ~65 s warm, exits 0
```

## What broke when following the README

Close to nothing — the documented path (`uv sync --extra serve`, then
`python -m kev.serve --run … --port 8009`) works on this GPU as written. Four
things needed a decision or a deviation:

1. **The quick start's model does not fit.** README's copy-paste line serves
   `jaredpalmer/kev-4b`. Kev-4B is ~8 GB of bf16 weights before serving
   buffers, and the Models table itself lists it as L40S/H100; on this 8 GB card
   (~1.1 GB already held by the display) it cannot load. Switched to Kev-0.8B,
   which the same table marks "any 4 GB GPU". Resident use measured at
   **5.06 GB total**, i.e. ~3.9 GB above the idle baseline.

2. **`--device auto` can hide a CPU fallback.** Per the README, `auto` probes
   CUDA and, if the probe fails or times out, warns and serves on CPU — which
   would look like a working server. `run.sh` passes `--device cuda`, which the
   README says fails closed instead.

3. **Blackwell support came down to the torch version.** sm_120 needs a cu128
   build. `uv.lock` resolves `torch==2.8.0`, whose PyPI wheel *is* cu128 and
   lists `sm_120` in `torch.cuda.get_arch_list()`, so no extra index or
   override was needed. `setup.sh` asserts this (allocation + bf16 matmul on
   device) right after `uv sync`, so a future lock bump that drops below
   torch 2.7 fails loudly at setup time rather than at first request.

4. **Cold `uv sync --extra serve` is slow, ~12 min** (an 888 MB torch wheel and
   a downloaded CPython 3.13). Not a failure, but worth knowing before judging
   `setup.sh` as hung.

## What I changed

- `setup.sh`: clone, `uv sync --extra serve`, the CUDA/sm_120 assertion, then
  pre-fetches both Hub repos — the adapter `jaredpalmer/kev-0.8b` and the base
  `Qwen/Qwen3.5-0.8B-Base` at revision `dc7cdfe2…`, the revision the
  checkpoint's own `training_config.json` pins — so the first server start does
  not wait on the Hub. All public; no token is used.
- `env.sh`: activates `/work/kev/.venv` (the `kev` package is installed
  editable, so cwd does not matter) and sets `HF_HOME=/work/hf-cache` so the
  weight cache is not tied to whichever `$HOME` is in effect.
- `run.sh`: `nohup` to `/work/server.log`, then polls a real
  `POST /v1/systemone` request rather than the TCP port, so it only returns
  once weights are loaded *and* the first CUDA-graph capture is done. It aborts
  early with a log tail if the server process dies, and is a no-op exit 0 if a
  server is already answering.

## Harmless noise in server.log

- `causal_conv1d` / `flash-linear-attention` not installed → transformers uses
  its reference implementations for the Gated DeltaNet layers. Correct, slower;
  neither is in the project's dependencies.
- "You are sending unauthenticated requests to the HF Hub" — expected, the
  repos are public.

## Measured result

README's example ticket returns a valid department choice with calibrated
probabilities (Kev-0.8B puts 0.456 on `shipping`, 0.280 `billing`, 0.265
`returns`; `escalate` 0.556; `frustration` 1.23/2). Warm latency 146–264 ms.
The TypeSafe SDK snippet from the README also runs unchanged against it.
