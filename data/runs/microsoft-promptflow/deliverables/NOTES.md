# Notes
- Followed the README path (`pip install promptflow promptflow-tools`, i.e. the example's requirements.txt) into a uv venv on Python 3.12; it installed promptflow 1.18.5 / promptflow-tools 1.6.1 from PyPI.
- `pf flow test` and `pf run create --data data.jsonl` both ran fine with no API key: the example's content_safety_check / llm_result nodes are dummy Python nodes.
- The only change: setup uses `uv venv` instead of plain pip (Ubuntu 24.04 system Python is externally managed, PEP 668), and pins the versions so reruns are reproducible.
- Note: content_safety_check returns random.choice([True, False]), so each line's answer is either the default "I'm not familiar with your query: ..." or the canned "Prompt flow is a suite of development tools..." text. That is how the upstream example is written, so I left it as is.
