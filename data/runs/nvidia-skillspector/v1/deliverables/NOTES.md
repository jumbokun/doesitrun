# SkillSpector setup notes
Followed README "From source" path: `uv venv .venv && source .venv/bin/activate && make install` (uv sync) on system Python 3.12.3.
Nothing broke. `--no-llm` scans work without API keys. Malicious fixture: 7 issues, score 100 CRITICAL;
safe fixture: 0 issues. Note: `skillspector scan` exits 1 on the malicious fixture — this is the documented
exit code for risk_score > 50, not a failure; the report is still written.
No changes made. env.sh activates /work/SkillSpector/.venv.
