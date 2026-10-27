# MDM text-to-motion — what broke and what I changed

Verified command (from `/work/motion-diffusion-model`, after `source /work/env.sh`):

```
python -m sample.generate \
  --model_path save/humanml_enc_512_50steps/model000750000.pt \
  --text_prompt "the person walked forward and is picking up his toolbox." \
  --device 0 --output_dir <fresh dir>
```
~105 s on the RTX 5060; writes `results.npy`, `results.txt`, 18 `sample##_rep##.mp4`
and 2 `samples_##_to_##.mp4`.

## What broke following the README

1. **`environment.yml` is unusable on this GPU.** It pins python 3.7, `pytorch=1.7.1`
   and `cudatoolkit=11.0`; there is no such build for sm_120 (Blackwell), and conda
   isn't in the image anyway. Replaced by a `uv` venv on python 3.10 with
   `torch==2.11.0+cu128` (pinned set in `requirements.txt`). No source change was
   needed for the new torch — only two deprecation warnings from `diffusion/nn.py`.
2. **`unzip` is missing from the image**, so every `prepare/*.sh` script downloaded its
   zip, failed silently at `unzip`, and then deleted the zip in its "Cleaning" step.
   `setup.sh` installs `unzip` (and `ffmpeg`, per the README) first.
3. **`prepare/download_glove.sh` / `download_t2m_evaluators.sh` use `gdown --fuzzy`,
   which current gdown (6.x) no longer accepts.** Pinned `gdown==5.2.0`.
4. **`spacy==3.7.5` is uninstallable-by-default now**: modern resolvers give it
   `typer-slim`, which has no `click` dependency, so `import spacy` dies with
   `ModuleNotFoundError: No module named 'click'`. Pinned `typer==0.9.4`, `click==8.1.8`,
   `weasel==0.4.1`. `python -m spacy download` also needs `pip` present in the venv.
5. **`ModuleNotFoundError: joblib`** — `utils/sampler_util.py` imports it but
   `environment.yml`'s pip section doesn't list it. Added.
6. **`ModuleNotFoundError: chumpy`** when `smplx` unpickles
   `body_models/smpl/SMPL_NEUTRAL.pkl`: its arrays are chumpy objects, and chumpy is
   dead (`from numpy import bool, int, float, ...`, removed in numpy>=1.24; its sdist
   also doesn't build under PEP 517 isolation). Instead of patching site-packages I
   rewrite the pickle once with `tools/strip_chumpy_smpl.py`, which unpickles through a
   stub chumpy module and dumps plain numpy arrays. Nothing needs chumpy at runtime.
7. **The README's promised `sample##_rep##.mp4` files are never written.**
   `sample/generate.py` keeps the per-sample `VideoClip` objects and only renders the
   combined grids. `patches/0001-write-per-sample-mp4.patch` (5 lines) sets each clip's
   duration and writes it to the path the code already computed.

## Other notes

* Checkpoint: `humanml-encoder-512-50steps` (README: "Runs 20X faster with comparable
  performance"), unzipped to `save/humanml_enc_512_50steps/`. Its `args.json` drives
  `trans_enc` / 50 diffusion steps / CLIP text encoder automatically.
* Data: the README's "easy way" (clone HumanML3D, unzip `texts.zip`, copy to
  `dataset/HumanML3D`). `--text_prompt` runs the dataset in `text_only` mode, which only
  needs `Mean.npy`, `Std.npy`, `test.txt` and `texts/`, so no motion-capture data is
  required. `glove/` and the T2M evaluators are downloaded anyway (README lists them as
  text-to-motion dependencies; only `eval.eval_humanml` uses them).
* CLIP ViT-B/32 is pre-fetched into `~/.cache/clip` at setup time.
* Defaults produce 6 samples x 3 repetitions (`--num_samples` default is 6 in this
  commit), ~1.4 GB VRAM. No OOM retries were needed.
* Everything is pinned to repo commit `ef8edce` and the version list in
  `requirements.txt`. `setup.sh` is idempotent and honours `MDM_ROOT` (default
  `/work/motion-diffusion-model`); it was re-run from scratch into a second root and
  the generate command verified there too.
