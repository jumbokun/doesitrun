# SkillSpector setup notes
Followed README "From source": `uv venv .venv && source .venv/bin/activate && make install` (runs `uv sync`) with system Python 3.12.3.
Nothing broke. `skillspector scan ... --no-llm` works without API keys for JSON and Markdown.
Malicious fixture: 7 issues, CRITICAL, exit code 1 (documented: findings at/above threshold). Safe fixture: 0 issues, exit 0.
No changes needed; env.sh just activates the venv.
