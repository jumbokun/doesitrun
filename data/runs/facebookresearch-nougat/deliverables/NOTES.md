# nougat on CPU — notes

Followed README: `pip install` from the repository (commit 5a92920) into a uv venv with Python 3.12.

What broke:
- With the latest pypdfium2 (5.x), `nougat` printed `'PdfDocument' object has no attribute 'render'` and wrote no .mmd file. nougat's `rasterize.py` calls `PdfDocument.render()`, which was removed in pypdfium2 5. setup.py only says `pypdfium2` with no upper bound. pypdfium2 3.x fails differently (`Invalid input type 'PosixPath'`).

What I changed:
- Pinned `pypdfium2==4.30.0`. That fixed it.
- Installed CPU-only torch/torchvision from the PyTorch CPU index before installing nougat, so the CUDA wheels don't get pulled. This is about size, not correctness.
- setup.sh pre-downloads the 0.1.0-small checkpoint to ~/.cache/torch/hub/nougat-0.1.0-small. The CLI would also download it on first run.
- env.sh activates /work/venv and sets NO_ALBUMENTATIONS_UPDATE=1, which only turns off a warning.

Result: `nougat t.pdf -o out --no-skipping -p 1` writes out/t.mmd with the correct text. It takes about 7 s per page on CPU.
