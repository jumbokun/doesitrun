# playwright-python setup notes

The README only gives usage examples. It never says how to install the package from a
source checkout. A checkout has no Playwright driver in it: `setup.py` builds the driver
from a clone of microsoft/playwright (`.upstream/`, at the commit in `DRIVER_VERSION`)
using `npm ci` / `npm run build`. That means you need Node.js/npm, which the base image
doesn't have. The steps come from AGENTS.md:

1. Installed Node.js v26.13.1 (from `NODE_VERSION`) from nodejs.org into /opt/node.
2. `uv venv env` + `uv pip install -r local-requirements.txt` (provides `build`).
3. `python scripts/upstream.py checkout` (clones microsoft/playwright into .upstream/).
4. `python -m build --wheel` builds the driver and the wheel; then installed the wheel into the venv.
5. `playwright install --with-deps chromium`, with `PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright`
   so the browsers are in a fixed location (env.sh exports this too).

No code patches or pins were needed. I ran the README sync example with Chromium only
(headless by default). It wrote example-chromium.png. A set_content/file:// page also
loads and gives the right title and text.
