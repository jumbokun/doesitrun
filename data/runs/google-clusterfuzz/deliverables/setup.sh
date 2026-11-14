#!/bin/bash
# Reproduces the local ClusterFuzz server setup from scratch (run as root, non-interactive).
# Mirrors local/install_deps.bash + install_python_deps_linux.bash, minus docker/devcontainer bits.
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# 1. Clone.
if [ ! -d /work/clusterfuzz/.git ]; then
  git clone --depth 1 https://github.com/google/clusterfuzz /work/clusterfuzz
fi
cd /work/clusterfuzz

# 2. System packages (subset of local/install_deps_linux.bash; docker-ce is not needed for run_server).
apt-get update
apt-get install -y lsb-release sudo curl unzip xvfb liblzma-dev patchelf golang-go \
    apt-transport-https ca-certificates gnupg openjdk-17-jdk-headless openjdk-25-jre-headless

# Google Cloud CLI + emulators (same apt repo the repo script uses).
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg -o /usr/share/keyrings/cloud.google.asc
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli google-cloud-cli-datastore-emulator google-cloud-cli-pubsub-emulator
# Current gcloud refuses to start the datastore emulator without Java 25+.
update-alternatives --set java /usr/lib/jvm/java-25-openjdk-amd64/bin/java

# 3. Python 3.11 venv (repo requires 3.11; image ships 3.12) with pipenv-pinned deps.
uv python install 3.11
[ -x /work/venv/bin/python ] || uv venv --seed -p 3.11 /work/venv
source /work/venv/bin/activate
# pipenv 2022.8.5 imports pkg_resources, which setuptools>=70/81 dropped.
pip install "setuptools<70" pipenv==2022.8.5
export PIPENV_VERBOSITY=-1
rm -rf src/third_party
pipenv sync --dev          # installs into the active /work/venv

# 4. Node/bower front-end deps + butler bootstrap (as in install_python_deps_linux.bash).
[ -x /work/venv/bin/node ] || nodeenv -p --prebuilt
source /work/venv/bin/activate
npm install --unsafe-perm -g bower polymer-bundler
bower --allow-root install
python butler.py bootstrap

# 5. Local-only patch: /login is disabled (HTTP 400) on the local dev server; let its GET render.
python - <<'PY'
p = 'src/appengine/handlers/login.py'
s = open(p).read()
old = '  @handler.get(handler.HTML)\n  @handler.unsupported_on_local_server\n  def get(self):\n    """Handle a get request."""\n    dest'
new = '  @handler.get(handler.HTML)\n  def get(self):\n    """Handle a get request."""\n    dest'
if old in s:
  open(p, 'w').write(s.replace(old, new, 1))
PY

echo "Setup complete. Run: source /work/env.sh && /work/run.sh"
