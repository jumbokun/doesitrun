# MDM text-to-motion — what broke and what I changed

Verified command (from `/work/motion-diffusion-model`, after `source /work/env.sh`):

```
python -m sample.generate \
  --model_path save/humanml_enc_512_50steps/model000750000.pt \
  --text_prompt "the person walked forward and is picking up his toolbox." \
  --device 0 --output_dir <fresh dir>
```

~2 min on the RTX 5060 (6 samples x 3 repetitions, ~1.4 GB VRAM); writes
`results.npy`, `results.txt`, 18 `sample##_rep##.mp4` and 2 `samples_##_to_##.mp4`.

Deliverables: `setup.sh` (self-contained — it writes its own requirements file,
SMPL-pickle converter and `generate.py` edit via heredocs into `$MDM_ROOT/.setup/`)
and `env.sh`. `setup.sh` honours `MDM_ROOT` (default `/work/motion-diffusion-model`),
is idempotent, and retries every download.

## What broke following the README

1. **`environment.yml` is unusable on this GPU.** It pins python 3.7, `pytorch=1.7.1`
   and `cudatoolkit=11.0`; there is no such build for sm_120 (Blackwell), and conda
   isn't in the image anyway. Replaced by a `uv` venv on python 3.10 with
   `torch==2.11.0+cu128` (full pin list written by `setup.sh`). No source change was
   needed for the new torch — only two deprecation warnings from `diffusion/nn.py`.
2. **`unzip` is missing from the image**, so every `prepare/*.sh` script downloaded its
   zip, failed silently at `unzip`, and then deleted the zip in its "Cleaning" step.
   `setup.sh` installs `unzip` (and `ffmpeg`, per the README) first.
3. **Those prepare scripts also exit 0 when their download failed**, so `setup.sh`
   retries them on *missing output files* rather than on exit status.
4. **`prepare/download_glove.sh` / `download_t2m_evaluators.sh` use `gdown --fuzzy`,
   which current gdown (6.x) no longer accepts.** Pinned `gdown==5.2.0`.
5. **`spacy==3.7.5` is uninstallable-by-default now**: modern resolvers give it
   `typer-slim`, which has no `click` dependency, so `import spacy` dies with
   `ModuleNotFoundError: No module named 'click'`. Pinned `typer==0.9.4`, `click==8.1.8`,
   `weasel==0.4.1`. `python -m spacy download` also needs `pip` present in the venv.
6. **`ModuleNotFoundError: joblib`** — `utils/sampler_util.py` imports it but
   `environment.yml`'s pip section doesn't list it. Added.
7. **`ModuleNotFoundError: chumpy`** when `smplx` unpickles
   `body_models/smpl/SMPL_NEUTRAL.pkl`: its arrays are chumpy objects, and chumpy is
   dead (`from numpy import bool, int, float, ...`, removed in numpy>=1.24; its sdist
   also doesn't build under PEP 517 isolation). Instead of patching site-packages I
   rewrite the pickle once with the generated `.setup/strip_chumpy_smpl.py`, which
   unpickles through a stub chumpy module and dumps plain numpy arrays. Nothing needs
   chumpy at runtime.
8. **The README's promised `sample##_rep##.mp4` files are never written.**
   `sample/generate.py` keeps the per-sample `VideoClip` objects and only renders the
   combined grids. `.setup/write_per_sample_mp4.py` adds 5 lines that set each clip's
   duration and write it to the path the code already computes. This is the only
   change to repository code (5 insertions, 0 deletions, 1 file).

## Other notes

* Checkpoint: `humanml-encoder-512-50steps` (README: "Runs 20X faster with comparable
  performance"), unzipped to `save/humanml_enc_512_50steps/`. Its `args.json` drives
  `trans_enc` / 50 diffusion steps / CLIP text encoder automatically. Google Drive is
  the only source upstream offers, so the download resumes (`gdown --continue`), is
  validated with `unzip -t`, and is retried.
* Data: the README's "easy way" (clone HumanML3D, unzip `texts.zip`, copy to
  `dataset/HumanML3D`). `--text_prompt` runs the dataset in `text_only` mode, which only
  needs `Mean.npy`, `Std.npy`, `test.txt` and `texts/`, so no motion-capture data is
  required.
* `glove/` and the T2M evaluators (1.4 GB) are downloaded last and are non-fatal: the
  README lists them as text-to-motion dependencies, but only `eval.eval_humanml` uses
  them, so a flaky Drive response there cannot sink generation setup.
* CLIP ViT-B/32 is pre-fetched into `~/.cache/clip` at setup time.
* Repo pinned to commit `ef8edce`.

## Fix after the first replay failure

The first `setup.sh` sourced three sibling files from `/work` (`requirements.txt`,
`tools/strip_chumpy_smpl.py`, `patches/0001-*.patch`). The replay copies in only
`setup.sh`/`env.sh`, so it died with `File not found: /work/requirements.txt` before
any download. `setup.sh` now generates all three itself with heredocs, and was
re-tested from an isolated prefix (`/scratch/isolated/setup.sh`, `MDM_ROOT=/scratch/mdm`)
with nothing else from `/work` reachable: full setup in ~5.5 min, then the generate
command produced `results.npy` + 20 mp4s.
