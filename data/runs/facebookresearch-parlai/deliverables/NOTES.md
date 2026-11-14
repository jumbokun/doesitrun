# ParlAI CPU setup notes

Followed README "Developer Installation" (venv + `setup.py develop`). What broke / what I changed:

- **Python version**: README says `python3.8`; image only has 3.12, on which the pinned requirements
  (torch==2.0.0, pandas==1.4.0, scipy==1.10.0, ...) don't install. Used a uv-managed Python 3.10 venv.
- **setup.py strips `==` pins**, so `setup.py develop` alone would pull latest everything; installed
  `requirements.txt` (pins) first, with CPU torch wheels (`--extra-index-url https://download.pytorch.org/whl/cpu`).
- **pyyaml==5.4** fails to build with Cython 3 → installed `cython<3` then pyyaml with `--no-build-isolation`.
- **pyzmq==18.1.0** has no cp310 wheel and fails to compile → bumped to 25.1.2 (not used by the examples).
- **pkg_resources missing**: README's `pip install --upgrade setuptools` gives setuptools 8x, which removed
  `pkg_resources` (imported by `parlai/core/opt.py`) → pinned `setuptools<70`.
- **scikit-learn missing**: commented out in requirements.txt but imported by `parlai/core/torch_classifier_agent.py`
  at CLI startup → installed scikit-learn==1.3.2.
- No code patches. Both README examples then work (SQuAD display, ir_baseline on PersonaChat: hits@1 .195, f1 .3056).
