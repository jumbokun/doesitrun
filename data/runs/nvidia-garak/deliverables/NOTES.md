# garak setup notes
- README's from-source path uses conda (`conda create ... python>=3.11`), which isn't in the image. I used `uv venv --python 3.12` at /work/venv and ran `pip install -e .` in it (with uv pip). Nothing else changed.
- I installed torch from the PyTorch CPU wheel index first. The machine has no GPU, and the default wheels pull in several GB of CUDA libraries. The test probes don't need this; it just keeps the install small.
- No code patches were needed. `--list_probes` works, and the test.Repeat/test.Test/always.Pass scan finishes and writes `<prefix>.report.jsonl` with attempt entries.
