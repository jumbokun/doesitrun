# GPT-2 (124M) on CPU — notes

What broke following DEVELOPERS.md:
- `pip3 install tensorflow==1.12.0` is impossible on the system Python 3.12 (TF 1.x wheels go up to py3.7 at most), and uv's managed CPython only goes down to 3.8. I installed Miniforge and created a conda env with Python 3.6 at /opt/gpt2env.
- TensorFlow 1.12.0 installs, but sampling fails with `AttributeError: module 'tensorflow' has no attribute 'sort'`. `src/sample.py` (top_p) needs `tf.sort`, which first appeared in TF 1.13. I used tensorflow==1.15.5, the last 1.x release, which still has py3.6 wheels.
- `interactive_conditional_samples.py` loops forever and dies with an `EOFError` traceback (exit 1) once stdin runs out. I patched it to return cleanly on EOF. The samples print either way.

Unchanged: `requirements.txt` installs fine, and `download_model.py 124M` works as written.
Only 124M is downloaded; the goal didn't need the larger models.
env.sh puts /opt/gpt2env/bin first on PATH, sets PYTHONIOENCODING=UTF-8 and cd's into /work/gpt-2.
Note: `generate_unconditional_samples.py` defaults to nsamples=0, which means it runs forever. Pass `--nsamples N` to stop it.
