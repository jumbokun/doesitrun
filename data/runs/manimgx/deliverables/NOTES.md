# ManimGX setup notes

## What broke following the README

Almost nothing. The README's documented path is `pip install manimgx` with
"Python 3.13+", and the only real obstacle was that requirement:

- **Python version.** The sandbox image ships Python 3.12.3, but `manimgx`
  publishes no wheels for 3.12 (`requires-python >= 3.13`), so installing with
  the system interpreter fails. `setup.sh` has `uv` fetch a CPython 3.13 and
  creates the venv at `/work/venv` around it.

That was the whole fix. In particular, nothing was needed for the
"No GPU, CPU only" constraint: the Linux wheel bundles Mesa's **lavapipe**
(`manimgx/lavapipe/libvulkan_lvp.so`) and falls back to CPU Vulkan on its own,
exactly as the README's "On the shoulders of giants" section claims. The render
succeeded on a machine with no `nvidia-smi` and no Vulkan driver installed.

## What I changed

- Installed into a dedicated venv at `/work/venv` (Python 3.13.17) instead of a
  system-wide `pip install`, which Ubuntu 24.04 blocks anyway (PEP 668).
- Pinned `manimgx==0.1.1`, the version the cloned checkout declares in
  `pyproject.toml`, so the installed wheel matches this README.
- Installed the published wheel rather than building the repo from source. The
  wheel contains the prebuilt Rust/wgpu extension; building the checkout would
  need a Rust toolchain and maturin for no benefit here.

## Things deliberately not done

- **No apt packages.** `ldd` on `_engine.abi3.so` and the bundled lavapipe
  resolves only to glibc, libstdc++, libgcc and a vendored `libdrm`, all already
  present. No system FFmpeg, x264, LaTeX or Vulkan driver is required -- all are
  bundled in the wheel.
- **No model/checkpoint downloads.** ManimGX is a renderer, not an ML project.
  Verified that nothing is fetched at render time: the scene renders fine with an
  empty `~/.cache` and no `manimgx` cache directory is created.
- The repo's `AGENTS.md` describes contributor workflows (just recipes, Rust
  builds, pre-commit); irrelevant to merely running the README example, so it was
  ignored.

## Verified

Clean room: deleted `/work/venv`, `/work/manimgx`, `~/.cache/uv` and
`~/.local/share/uv`, then ran `bash /work/setup.sh` -> completed in ~98 s
including its own render smoke test.

Then, in a stripped environment (`env -i`, default PATH) after
`source /work/env.sh`, `python` -> `/work/venv/bin/python` (3.13.17) and
`manimgx` -> `/work/venv/bin/manimgx`:

```
$ manimgx render scene.py
Hello3D.mp4  6.00 s, 1920x1080 at 60 fps, 0.4 MB (rendered in 29.0 s)
```

`mvhd` box confirms 6.017 s, H.264 (`avcC`), 1920x1080 at 60 fps, 368 KB.
