# SkillOpt-Sleep mock experiment

Followed the docs (`pip install -e .`, then
`python -m skillopt_sleep.experiments.run_experiment --persona researcher --assert-improves`).
It worked as written on Python 3.12 with CPU only. No code changes or pins were needed.

The only thing I added: an isolated venv at /work/venv (made with `uv venv`, packages installed with `uv pip`),
because Ubuntu 24.04's system Python is externally managed (PEP 668) and refuses a bare `pip install`.
The README doesn't mention a venv. `env.sh` activates it.

Result: baseline held-out 0.3333 → 1.0 (lift +0.6667), gate blocks the harmful edit, and the run ends with a PASS line.
`--json` works too. In this run the trace has a baseline night plus one accepted night (`nights_run: 1`).
