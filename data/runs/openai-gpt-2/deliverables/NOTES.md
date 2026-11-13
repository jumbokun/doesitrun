# gpt-2 setup notes

**What broke when I followed the README/DEVELOPERS.md:**
- `pip3 install tensorflow==1.12.0` didn't work. TF 1.12 only ships wheels up to cp36, and the oldest Python that uv can install is 3.8 (the system Python is 3.12). TF 1.x has no wheels for Python 3.8 or newer.
- The pins in `requirements.txt` (regex==2017.4.5, requests==2.21.0, tqdm==4.31.1) are too old for modern Python.
- In TF2, `tensorflow.contrib` (used for `HParams`) no longer exists.
- The interactive script loops on `input()`, so a prompt piped in on stdin ended with an `EOFError` traceback.

**What I changed (all done by /work/setup.sh):**
- Python 3.11 venv at /work/venv (uv), with `tensorflow-cpu==2.15.1`, `numpy<2`, `fire`, and unpinned regex/requests/tqdm.
- In the 4 `src/*.py` files, `import tensorflow as tf` became `import tensorflow.compat.v1 as tf; tf.disable_v2_behavior()`.
- `src/model.py`: the `tf.contrib.training.HParams` import is replaced by a small inline `HParams` class that has `override_from_dict`.
- `src/interactive_conditional_samples.py`: it now exits cleanly (code 0) on EOF from stdin.
- The model download is the documented `python download_model.py 124M`, and it worked unchanged.
- env.sh activates the venv, sets PYTHONIOENCODING=UTF-8 and cds into /work/gpt-2.
- Note: with the default `nsamples=0`, `generate_unconditional_samples.py` runs forever (upstream behaviour). Pass `--nsamples 1` to stop after one sample.
