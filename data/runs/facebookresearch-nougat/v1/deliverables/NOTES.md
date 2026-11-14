# nougat on CPU — notes

README path: `pip install nougat-ocr` / `pip install git+...`, then `nougat file.pdf -o out`.

What broke:
- An unpinned install pulls **pypdfium2 5.x**, which removed `PdfDocument.render`. Rasterizing fails
  (`'PdfDocument' object has no attribute 'render'` -> "Image not found"), and no text is produced.
- An unpinned install also pulls a recent CUDA torch (multi-GB, not needed on CPU) and numpy 2.x / lightning 2.6,
  which are untested with the old timm==0.5.4 / transformers<=4.38.2 stack.

What I changed (setup.sh):
- Python 3.10 venv made with uv at /work/venv (setup.py classifiers only go up to 3.10; the system has 3.12).
- CPU-only torch 2.2.2 / torchvision 0.17.2 from the PyTorch CPU index.
- Constraints: transformers==4.38.2, timm==0.5.4, albumentations==1.3.1, pypdfium2==4.30.0, numpy<2,
  lightning==2.2.5, setuptools<81. The repo is installed editable from /work/nougat.
- The 0.1.0-small checkpoint is pre-downloaded to ~/.cache/torch/hub/nougat-0.1.0-small, and the nltk `words` corpus is pre-fetched.
- No code patches.

Test: a one-page fpdf2 text PDF run with `nougat some.pdf -o outdir --no-skipping -p 1` took about 2 minutes on CPU and gave the exact text.
