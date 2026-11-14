# UI-TARS (ui-tars parser) setup notes
- The README's install step is `pip install ui-tars`, which pulls the package from PyPI, not this repo's code.
  The goal needed the repo's own source, so I installed `/work/UI-TARS/codes` (hatchling, no runtime deps) into a uv venv (Python 3.12) at /work/venv.
- Nothing else broke. The README usage snippet runs as written and prints the parsed dict plus
  `pyautogui.click(99.379, 197.802, button='left')`.
  For qwen25vl the coordinates go through smart_resize, so they are not exactly 192/216.
- env.sh activates /work/venv.
