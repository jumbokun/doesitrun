# Data Formulator setup notes

Path followed: README "Option 2: Install via pip" using the preview version the README names
(`pip install --pre data_formulator==0.8.0b1`, same version as repo HEAD `pyproject.toml`), in a
uv-created Python 3.12 venv at /work/venv. The PyPI wheel already contains the built frontend
(`data_formulator/dist`), so no Node/yarn build is needed. The repo is cloned to /work/data-formulator
for reference only.

What worked / what I changed:
- Install and `python -m data_formulator --port 5567` worked as documented. No code patches.
- I created a venv (the README recommends one but doesn't give the commands).
- run.sh passes `--dev` so the server doesn't try to open a browser on a headless box, then polls `/`
  and `/api/app-config` until both answer.
- I did not use `uv sync` from the repo: `pyproject.toml` sets a Microsoft-internal package index
  (packagefeedproxy.microsoft.io) as the default, and that would also need a frontend build.
- Not in the README: every `/api/tables/*` call needs an `X-Workspace-Id: <any id>` header. Without it
  the server returns "No active workspace. X-Workspace-Id header is required." The workspace is
  created the first time an id is used.

Example:
  curl -H 'X-Workspace-Id: ws1' -F file=@t.csv -F table_name=t localhost:5567/api/tables/create-table
