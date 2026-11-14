# fairseq setup notes (CPU)

What broke following the README (`pip install --editable ./`):
- On the system Python 3.12 with a current pip, the install fails: `omegaconf<2.1` (which `hydra-core<1.1` needs) has invalid metadata that pip>=24.1 refuses ("use pip<24.1"), so the resolver has no solution. hydra-core 1.0.x also doesn't work on Python 3.11+.
- After installing, `from_pretrained('transformer.wmt19...')` fails with `ModuleNotFoundError: requests`, because fairseq's download code imports `requests` but doesn't list it as a dependency.

What I changed (see setup.sh):
- Made a uv venv with Python 3.10 at /work/venv, with `pip<24.1` and `setuptools<70`.
- Installed CPU-only torch/torchaudio 2.4.1 from the PyTorch CPU index, plus `numpy<2` and cython, before the editable install. The editable install uses `--no-build-isolation` so it builds against that torch/numpy.
- Installed `fastBPE sacremoses subword_nmt` (from examples/translation/README.md) and `requests`.
- Downloaded and extracted roberta.base to /work/models/roberta.base. setup.sh also pre-fetches the wmt19 model and roberta's GPT-2 BPE files into ~/.cache/torch/pytorch_fairseq.
- I didn't patch any code.

Verified: 'Hello world!' -> 'Hallo Welt!', 'Machine learning is great!' -> 'Maschinelles Lernen ist großartig!'. fill_mask top-1 is ' Paris'. encode('Hello world!') = [0, 31414, 232, 328, 2]. extract_features shape is (1, 5, 768).
