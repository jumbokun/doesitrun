# NOTES
- README gives no install steps. `scripts/genrulesinput.py` does `import requests` (unused, but crashes with ModuleNotFoundError on stock Python). Created a uv venv at /work/.venv and installed `requests`.
- README runs `genrulesinput.py` as a bare command; env.sh adds `scripts/` to PATH (setup.sh chmods +x) so both that and `python3 scripts/genrulesinput.py` work.
- Minor doc issue: README link to genrulesinput.py actually points at README_genrulesinput.md.
- Verified: README example gives 3 requests, 4 players, skills [1,50,20,30], secondsInQueue [20,10,0].
