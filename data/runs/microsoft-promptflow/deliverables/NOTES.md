# promptflow setup notes
- Followed README: `pip install promptflow promptflow-tools` (done with uv into a Python 3.12 venv at /work/.venv, pinned to promptflow 1.18.5 / promptflow-tools 1.6.1).
- `pf flow test` and `pf run create --flow ... --data .../data.jsonl` both completed with no API keys or connections.
- Nothing broke. The only change is that I used a venv, because Ubuntu 24.04's system Python is "externally managed" (PEP 668), so a bare `pip install` is refused.
- Note: the example's `content_safety_check` node uses `random.choice`, so the answer is either the fixed LLM text or the "I'm not familiar with your query" default. This is how the example is designed, and I did not patch it.
