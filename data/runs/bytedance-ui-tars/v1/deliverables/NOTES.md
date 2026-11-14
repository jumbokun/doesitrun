# UI-TARS (ui-tars parser) setup notes

- Followed the README path: installed `ui-tars` from the repo's `codes/` dir (same package as PyPI 0.1.4) into a uv venv at /work/.venv (Python 3.12). The package has no runtime dependencies.
- The README usage snippet ran as written. It prints the parsed dict (start_box normalised to [0.0518, 0.1832, ...]) and `pyautogui.click(99.379, 197.802, button='left')`.
- The only thing missing: `codes/tests/inference_test.py` imports PIL and matplotlib, which are uv dev-dependencies only. I installed pillow and matplotlib so the repo's unittest suite passes. The parser itself doesn't need them.
- env.sh activates /work/.venv.
