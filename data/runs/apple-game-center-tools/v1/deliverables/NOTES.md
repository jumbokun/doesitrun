# Notes
- README has no install instructions; the script imports `requests` (not used by genrulesinput itself but imported). Created a uv venv at /work/venv and installed `requests`.
- README invokes `genrulesinput.py` as if on PATH; we run `python3 scripts/genrulesinput.py` from the repo (env.sh activates venv and cd's into the repo).
- No code changes needed; output verified: 3 requests, 4 players, skills [1,50,20,30].
