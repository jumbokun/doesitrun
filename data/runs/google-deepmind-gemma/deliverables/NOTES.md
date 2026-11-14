# Notes

Tested against gemma commit 9e1f741.

- README path: install JAX for CPU, then `pip install gemma`. I installed from the clone with `uv pip install "jax[cpu]"` and then `uv pip install -e /work/gemma`, using a Python 3.12 venv at /work/venv.
- **What broke:** importing the tokenizer (`gm.text.Gemma3Tokenizer`, which ChatSampler uses) failed with
  `google.protobuf.runtime_version.VersionError: gencode 7.36.1 runtime 6.33.6`.
  The latest sentencepiece (0.2.3) ships protobuf-7 generated code, but tensorflow 2.21 holds protobuf below 7.
  **Fix:** pin `sentencepiece<0.2.2` (0.2.1 gets installed).
- The checkpoint load (`load_params(GEMMA3_270M_IT)`) works without credentials. It does log harmless warnings about missing GCP credentials. The params are read from gs://gemma-data every time; the tokenizer gets cached.
- env.sh activates the venv and sets `JAX_PLATFORMS=cpu`.
- Check: `ChatSampler(multi_turn=True).chat('What is the capital of France?')` returned "The capital of France is Paris." The follow-up turn also returned text.
