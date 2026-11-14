# Data Formulator setup notes

Installed from the cloned repo (v0.8.0b1, the same version as the PyPI pre-release) following DEVELOPMENT.md's "Build for Production" steps:
`yarn install && yarn build` (writes to py-src/data_formulator/dist), then `uv pip install -e .` into /work/venv (Python 3.12).
Server: `python -m data_formulator --port 5567`. run.sh starts it in the background and waits until `/` and `/api/app-config` both answer.

What broke or was missing:
- Node.js and yarn aren't in the image, and the README doesn't mention them; DEVELOPMENT.md says only "Node.js", with no version. The Dockerfile's node:20 image is too old for this repo:
  vite 7 needs node >=20.19 and eslint-visitor-keys needs >=22.13, so the installs failed with 20.18 and 22.12. I used the official Node v22.21.1 tarball in /work/node and installed yarn 1.22.22 with npm.
- The README's `pip install data_formulator` installs the stable 0.7.0, not this repo's code. I built the frontend and installed from source instead.
- Every /api/tables/* call returns INTERNAL_ERROR unless the request has an `X-Workspace-Id` header (the frontend generates one; this isn't documented for API clients).
  I patched `get_active_workspace_id()` in workspace_factory.py so it falls back to `$DF_DEFAULT_WORKSPACE_ID`, which env.sh sets to `default`. Requests that send the header behave exactly as before.
- env.sh sets DATA_FORMULATOR_HOME=/work/df_home. run.sh sets BROWSER=true so the auto-open-browser step does nothing on a headless machine.

Verified: `/` serves index.html, `/api/app-config` returns OK, and a CSV uploaded via create-table is returned with the right rows and counts by list-tables, get-table and sample-table, both with and without the header.
