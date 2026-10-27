# harness2 setup notes
The README install path worked as written: `uv venv --python 3.12 .venv`, activate,
`uv pip install -e '.[render]'`, then `harness2-demo --output <dir> --k 2`.
The demo finished with exit 0, reported "Local demo: 2 tasks completed; 0 failed.", and wrote demo.json
with execution_count=28. No changes were needed.
