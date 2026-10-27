# fairseq (RoBERTa base, CPU) setup notes

README path: `pip install --editable ./`, using the system Python 3.12. That doesn't work as written:
- **Python version:** fairseq pins hydra-core 1.0.x and omegaconf<2.1. Those versions don't work on Python 3.11+ (mutable dataclass default errors). I used Python 3.10 in a uv venv (`/work/venv`).
- **Torch:** I preinstalled CPU-only torch/torchaudio 2.5.1 from the PyTorch CPU index. This keeps CUDA wheels out of a CPU-only box and stays under 2.6, where `torch.load` defaults to `weights_only`.
- **numpy:** I pinned `numpy<2` so it matches the older stack.
- **requests:** `requests` is required but not declared. The GPT-2 BPE (`file_utils.cached_path`) imports it to download encoder.json/vocab.bpe. Without it, `from_pretrained` fails with ModuleNotFoundError.
- **BPE cache:** setup.sh runs a smoke test once. That pre-caches the BPE files in `~/.cache/torch/pytorch_fairseq`.
- **Location:** the model is extracted to `/work/models/roberta.base`.

Verified: fill_mask top 3 = Paris/Lyon/Nice; encode('Hello world!') = [0,31414,232,328,2]; features shape (1,5,768).
