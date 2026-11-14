#!/usr/bin/env bash
# Reproduces the pysc2 setup: clone, patch, venv, SC2 4.10 Linux package, mini_games maps.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
SC2_DIR="${HOME}/StarCraftII"
SC2_URL=https://blzdistsc2-a.akamaihd.net/Linux/SC2.4.10.zip
SC2_SIZE=4115224017
MINI_URL=https://github.com/deepmind/pysc2/releases/download/v1.2/mini_games.zip

apt-get update -qq
apt-get install -y -qq unzip >/dev/null

cd /work
[ -d pysc2/.git ] || git clone https://github.com/google-deepmind/pysc2 /work/pysc2
cd /work/pysc2
git checkout -q 0df53d38c153972f1e368572ba65b1442a0fd41f
# HEAD forwards run_config.start()'s extra_ports kwarg to subprocess.Popen -> TypeError.
python3 - <<'PY'
p = 'pysc2/lib/sc_process.py'
s = open(p).read()
old = '    """Launch the process and return the process object."""\n    try:'
new = ('    """Launch the process and return the process object."""\n'
       '    kwargs.pop("extra_ports", None)  # Consumed by run_config, not Popen.\n    try:')
if new not in s:
    assert old in s
    open(p, 'w').write(s.replace(old, new))
PY

cd /work
[ -x venv/bin/python ] || uv venv -q -p 3.11 /work/venv
uv pip install -q -p /work/venv/bin/python --upgrade --reinstall-package pysc2 ./pysc2 "protobuf==3.20.3"

# StarCraft II Linux package (password = EULA acceptance, per Blizzard's README).
mkdir -p /work/dl
if [ ! -x "${SC2_DIR}/Versions/Base75689/SC2_x64" ]; then
  if [ "$(stat -c %s /work/dl/SC2.4.10.zip 2>/dev/null || echo 0)" != "$SC2_SIZE" ]; then
    curl -fsSL --retry 5 -C - -o /work/dl/SC2.4.10.zip "$SC2_URL" || \
      curl -fsSL --retry 5 -o /work/dl/SC2.4.10.zip "$SC2_URL"
  fi
  (cd "$HOME" && unzip -q -o -P iagreetotheeula /work/dl/SC2.4.10.zip)
fi
curl -fsSL --retry 5 -o /work/dl/mini_games.zip "$MINI_URL"
mkdir -p "${SC2_DIR}/Maps"
(cd "${SC2_DIR}/Maps" && unzip -q -o /work/dl/mini_games.zip)
rm -f /work/dl/SC2.4.10.zip
echo "setup done"
