#!/bin/bash
# Reproduces the local ClusterFuzz server setup from scratch (run as root).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
REPO=/work/clusterfuzz
UV_PY_DIR=/opt/uv-python

# 1. Clone.
mkdir -p /work
if [ ! -d "$REPO/.git" ]; then
  git clone https://github.com/google/clusterfuzz "$REPO"
fi
cd "$REPO"

# 2. System packages (mirrors local/install_deps_linux.bash, minus docker,
#    with Java 21 instead of 17 since the datastore emulator needs Java 21+).
apt-get update
apt-get install -y lsb-release unzip xvfb blackbox curl ca-certificates gnupg \
    apt-transport-https liblzma-dev patchelf golang-go openjdk-21-jre-headless

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    -o /usr/share/keyrings/cloud.google.asc
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
# gcloud >=592 refuses to start the datastore emulator without Java 25, so
# pin the whole CLI (not just the emulator package) to 591.
apt-get install -y --allow-downgrades \
    google-cloud-cli=591.0.0-0 \
    google-cloud-cli-datastore-emulator=591.0.0-0 \
    google-cloud-cli-pubsub-emulator=591.0.0-0
apt-mark hold google-cloud-cli google-cloud-cli-datastore-emulator \
    google-cloud-cli-pubsub-emulator

# 3. Python 3.11 (docs require 3.11; Ubuntu 24.04 ships 3.12) via uv.
export UV_PYTHON_INSTALL_DIR=$UV_PY_DIR
uv python install 3.11
PY311=$(uv python find 3.11)
rm -f "$(dirname "$PY311")"/../lib/python3.11/EXTERNALLY-MANAGED
ln -sf "$PY311" /usr/local/bin/python3.11
python3.11 -m ensurepip
# pipenv 2022.8.5 (version pinned in Pipfile) needs pkg_resources.
python3.11 -m pip install --root-user-action=ignore "setuptools<81" pipenv==2022.8.5

# 4. Python deps (mirrors local/install_python_deps_linux.bash).
export PIPENV_VENV_IN_PROJECT=1 PIPENV_YES=1 PIPENV_NOSPIN=1 CI=1
rm -rf src/third_party
if [ -d .venv ]; then rm -rf .venv; fi
python3.11 -m pipenv --python python3.11
python3.11 -m pipenv sync --dev
set +u; source .venv/bin/activate; set -u
nodeenv -p --prebuilt
npm install --unsafe-perm -g bower polymer-bundler
bower --allow-root install
python butler.py bootstrap

# 5. Pre-build the Go GCS emulator so `go run` is fast at server start.
(cd local && go build -o /tmp/cf-gcs-prebuild emulators/gcs.go && rm -f /tmp/cf-gcs-prebuild)

echo "Setup complete."
