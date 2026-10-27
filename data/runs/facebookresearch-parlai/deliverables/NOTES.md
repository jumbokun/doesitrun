# ParlAI setup notes (CPU)
README developer install: `python3.8 -m venv venv; pip install -U pip setuptools wheel; python setup.py develop`.
What broke / what I changed:
- No python3.8 on Ubuntu 24.04 -> used `uv venv -p 3.8` (uv-managed CPython 3.8).
- Installed requirements.txt explicitly (setup.py develop alone is the documented path), with the PyTorch CPU index so torch==2.0.0+cpu is used (no CUDA wheels).
- Unpinned `litellm` pulls `tokenizers` 0.21, which has no py3.8 wheel and whose sdist fails to build -> constrained `tokenizers<0.21`.
- `scikit-learn` is commented out in requirements.txt but imported by `parlai.core.torch_classifier_agent`, so the `parlai` CLI crashed on startup -> installed scikit-learn==1.3.2.
No code patches. `parlai display_data -t squad -n 5` and `parlai eval_model -m repeat_label -t integration_tests -dt valid -ne 10` both work.
