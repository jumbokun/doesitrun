#!/usr/bin/env bash
# Reproduce the pysc2 setup from scratch (run as root, non-interactive).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /work

apt-get update -qq
apt-get install -y -qq unzip ca-certificates

[ -d /work/pysc2/.git ] || git clone https://github.com/google-deepmind/pysc2 /work/pysc2

# Fix: upstream HEAD passes run_config.start(extra_ports=...) kwargs straight to subprocess.Popen.
python3 - <<'PY'
p = '/work/pysc2/pysc2/lib/sc_process.py'
s = open(p).read()
old = '''    """Launch the process and return the process object."""
    try:'''
new = '''    """Launch the process and return the process object."""
    kwargs.pop("extra_ports", None)  # Not a Popen argument.
    try:'''
if 'kwargs.pop("extra_ports"' not in s:
    assert old in s
    open(p, 'w').write(s.replace(old, new))
PY

# Python 3.11 (setup.py lists up to 3.11); old generated protos need protobuf<3.21.
[ -x /work/venv/bin/python ] || uv venv -p 3.11 /work/venv
uv pip install -p /work/venv/bin/python -e /work/pysc2 "protobuf<3.21" "numpy<2"

# StarCraft II Linux package 4.10 (EULA archive password per Blizzard s2client-proto docs) + mini games.
mkdir -p /work/dl
if [ ! -x "$HOME/StarCraftII/Versions/Base75689/SC2_x64" ]; then
  [ -s /work/dl/SC2.4.10.zip ] || curl -fL --retry 5 -o /work/dl/SC2.4.10.zip https://blzdistsc2-a.akamaihd.net/Linux/SC2.4.10.zip
  (cd "$HOME" && unzip -q -o -P iagreetotheeula /work/dl/SC2.4.10.zip)
fi
[ -s /work/dl/mini_games.zip ] || curl -fL --retry 5 -o /work/dl/mini_games.zip https://github.com/deepmind/pysc2/releases/download/v1.2/mini_games.zip
mkdir -p "$HOME/StarCraftII/Maps"
unzip -q -o /work/dl/mini_games.zip -d "$HOME/StarCraftII/Maps/"
rm -f /work/dl/SC2.4.10.zip
echo "setup done"
