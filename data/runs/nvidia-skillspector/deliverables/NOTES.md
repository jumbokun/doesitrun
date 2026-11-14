# SkillSpector setup notes
Followed README "From source" path exactly: `uv venv .venv && source .venv/bin/activate && make install` (runs `uv sync`) with system Python 3.12.3. Nothing broke.
- `skillspector scan tests/fixtures/malicious_skill --no-llm --format json|markdown` -> 7 issues, score 100 CRITICAL; safe_skill -> 0 issues, SAFE.
- Note: scan exits with code 1 when the skill is high risk (intentional gating, see src/skillspector/cli.py); the report is still written. Safe skill exits 0.
No changes were needed. env.sh activates the venv.
