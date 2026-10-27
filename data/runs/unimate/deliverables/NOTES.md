# UniMate — getting README path "2b. Animate your own rigged asset" to run

Target command (works, from `/work/UniMate` after `source /work/env.sh`):

```bash
python -m unimate.inference.sample --exp_dir outputs/unimate_uniml3d_f60_v3 \
    --asset assets/examples/unitree_go2 --prompt "An object trots forward." --output_dir <dir>
```

Writes `<dir>/motions/unitree_go2-an_object_trots_forward-rep_0-0.npy` (60 x 18 x 12
float32), an FK mp4 + T-pose png under `<dir>/animations/`, `manifest.json` and
`captions.json`. ~25 s of sampling on the RTX 5060, ~1 GB VRAM. The 88 GB UniML3D
dataset is not downloaded and not needed: a `rig_preprocess` asset directory carries
its own `cond.npy`, and the checkpoint ships `dataset_stats.npy`.

## What broke

1. **The pinned PyTorch cannot run on this GPU.** `requirements.txt` pins
   `torch==2.5.1+cu124` / `torchvision==0.20.1+cu124`. Those wheels are built for
   `sm_50...sm_90`; the RTX 5060 Laptop is Blackwell `sm_120`. Verified: any CUDA op
   fails with `CUDA error: no kernel image is available for execution on the device`.
   **Change:** same Python (3.10) and every other pin kept, but PyTorch installed from
   the cu128 index as `torch==2.8.0+cu128` / `torchvision==0.23.0+cu128`. No code change
   was needed — the model, flow sampler and `torch_geometric`/`torchdiffeq` pins all run
   unmodified on 2.8.
2. **No conda in the image.** The documented setup is
   `conda create -n unimate python=3.10`. **Change:** `uv venv --python 3.10 /work/venv`.
   The `setuptools<81` + `--no-build-isolation` requirement from `requirements.txt` still
   applies and is honoured — it is what lets the `Motion` git dependency (legacy
   `setup.py` importing `pkg_resources`) build.
3. **The text encoder download is undocumented.** The README's step 1 fetches only the
   checkpoint, but `config.json` sets `model.text_encoder_version = google/flan-t5-base`,
   which `transformers` pulls from the Hub on first run. **Change:** `setup.sh`
   pre-downloads it into `HF_HOME=/work/hf_cache` (also exported by `env.sh`), so
   inference needs no network. Re-verified with `HF_HUB_OFFLINE=1`.

## What I left out on purpose

* `bpy==4.0.0` and the `clip` git dependency are not installed. `bpy` is only used by
  the mesh-driving / rendering / export stages (`scripts/run_animate_motion.sh`, which
  the task excludes), and `clip` only by `CLIPConditioner`, which is imported lazily and
  unused for this checkpoint (`text_encoder_type: t5`). Everything the inference path
  imports is installed at the pinned versions.
* `ffmpeg`/`libgl1` are apt-installed as a safety net only; the mp4 writer actually used
  is the one bundled in the `imageio-ffmpeg` wheel.

## Files

* `/work/setup.sh` — clone, apt, venv, deps, checkpoint + flan-t5-base download. Run as
  root on a fresh container; recreates `/work/venv` from scratch each time.
* `/work/env.sh` — `source` it: activates `/work/venv` and exports `HF_HOME`.
