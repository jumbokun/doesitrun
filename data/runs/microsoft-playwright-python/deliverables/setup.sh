#!/usr/bin/env bash
# Reproduce the playwright-python setup from scratch (run as root, non-interactive).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

REPO=/work/playwright-python
NODE_DIR=/opt/node
export PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright

# 1. Clone the repo
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/microsoft/playwright-python "$REPO"
fi
cd "$REPO"

# 2. Node.js (needed to build the driver from upstream microsoft/playwright)
NODE_VERSION=$(cat NODE_VERSION)
if [ ! -x "$NODE_DIR/bin/node" ] || [ "$("$NODE_DIR/bin/node" --version)" != "v$NODE_VERSION" ]; then
  mkdir -p /opt/dl
  curl -fsSL -o /opt/dl/node.tar.xz "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
  rm -rf "/opt/node-v$NODE_VERSION-linux-x64"
  tar -xJf /opt/dl/node.tar.xz -C /opt
  ln -sfn "/opt/node-v$NODE_VERSION-linux-x64" "$NODE_DIR"
fi
export PATH="$NODE_DIR/bin:$PATH"

# 3. Python venv + dev requirements (build etc.)
[ -x env/bin/python ] || uv venv -p python3 env
. env/bin/activate
uv pip install -r local-requirements.txt

# 4. Upstream checkout at DRIVER_VERSION, then build the wheel (builds the driver)
python scripts/upstream.py checkout
rm -rf dist
python -m build --wheel
uv pip install --reinstall dist/*.whl

# 5. Browsers + system deps
playwright install --with-deps chromium

# 6. Smoke test
cd /tmp
python - <<'PY'
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    pg = b.new_page()
    pg.set_content("<title>ok</title><p>hello</p>")
    assert pg.title() == "ok"
    pg.screenshot(path="/tmp/setup-smoke.png")
    b.close()
print("smoke test OK")
PY
