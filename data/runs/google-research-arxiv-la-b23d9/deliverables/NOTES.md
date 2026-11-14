# arxiv-latex-cleaner setup notes
- Everything worked; only small deviations from the README:
  - README says `pip install` / `python setup.py install`. Ubuntu 24.04's system Python is "externally managed" (PEP 668), and `setup.py install` is deprecated, so I created a uv venv (Python 3.12) at /work/venv and ran `uv pip install .` from the clone (pinned to commit 1bc61c1).
- No code patches. The goal command on a copy of test_data/tex produces tex_arXiv: comments are stripped, unused images, .aux files and not_included/ are removed, and images are resized (im_size 100, im2_included.jpg resized to 50 via the allowlist). The unit tests pass (104 tests, 1 skipped).
- The "Found unmatched \iffalse" warning comes from the sample file itself. The repo's tex_arXiv_true output was generated with extra options (commands_to_delete, if_exceptions, tikz, etc.), so it differs from what this simpler command produces.
