# Sonnet setup notes
- README install (`pip install tensorflow tensorflow-probability dm-sonnet`) works on Python 3.12
  with current TF 2.21 / TFP 0.25 / Keras 3; README snippets (snt.Sequential MLP, snt.Module + snt.once) run unchanged.
- README doesn't mention `tensorflow-datasets`, needed by examples/simple_mnist.py.
- tensorflow-datasets 4.9.10 fails at import with `No module named 'importlib_resources'`
  (undeclared dependency) -> installed `importlib_resources`.
- Used a uv venv at /work/venv, installed Sonnet from the clone, pinned versions; setup.sh pre-downloads MNIST.
- Result: simple_mnist.py runs 5 epochs on CPU in ~50s, final test acc ~98%.
