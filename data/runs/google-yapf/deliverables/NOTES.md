# YAPF setup notes
- README says `pip install yapf` / `pip install git+...`. On Ubuntu 24.04, bare `pip install` into the system
  Python is refused (PEP 668 "externally-managed-environment"), so I created a venv at /work/venv and ran
  `pip install /work/yapf` (the local clone) into it. No other problems: yapf 0.43.0 needs no extra deps on Python 3.12.
- env.sh puts /work/venv/bin on PATH.
- Verified: `yapf f.py`, `--diff` (exit 1 when changes), `-i`, `--style google`, idempotent second run (exit 0).
