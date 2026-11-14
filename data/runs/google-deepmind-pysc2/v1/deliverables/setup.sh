#!/usr/bin/env bash
# Reproduces the pysc2 setup from scratch (run as root on a fresh Ubuntu 24.04 image).
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
WORK=/work
SC2_PARENT="${HOME}"            # pysc2 default: ~/StarCraftII
SC2_ZIP_URL=http://blzdistsc2-a.akamaihd.net/Linux/SC2.4.10.zip
MINI_GAMES_URL=https://github.com/deepmind/pysc2/releases/download/v1.2/mini_games.zip
DL="${WORK}/.downloads"

# System packages: unzip is needed for the (EULA-password-protected) Blizzard zip.
apt-get update -qq
apt-get install -y -qq unzip ca-certificates

# Clone (pinned to the commit this was tested with).
mkdir -p "$WORK"
if [ ! -d "$WORK/pysc2/.git" ]; then
  git clone https://github.com/google-deepmind/pysc2 "$WORK/pysc2"
fi
cd "$WORK/pysc2"
git checkout -q 0df53d38c153972f1e368572ba65b1442a0fd41f
# Bug in HEAD commit: sc2_env passes extra_ports through to subprocess.Popen.
if ! grep -q 'kwargs.pop("extra_ports"' pysc2/lib/sc_process.py; then
  python3 - <<'PY'
p = "pysc2/lib/sc_process.py"
s = open(p).read()
old = '''    """Launch the process and return the process object."""
    try:'''
new = '''    """Launch the process and return the process object."""
    kwargs.pop("extra_ports", None)  # Used by sc2_env, not a Popen argument.
    try:'''
assert old in s
open(p, "w").write(s.replace(old, new))
PY
fi

# Python env (setup.py supports up to 3.11). protobuf must be <=3.20 for the
# pre-generated s2clientprotocol _pb2 modules.
cd "$WORK"
[ -x .venv/bin/python ] || uv venv -p 3.11 .venv
uv pip install -p .venv/bin/python -e ./pysc2 "protobuf<=3.20.3"

# StarCraft II Linux headless build + mini_games maps.
mkdir -p "$DL"
if [ ! -x "${SC2_PARENT}/StarCraftII/Versions/Base75689/SC2_x64" ]; then
  curl -fSL --retry 5 -C - -o "$DL/SC2.4.10.zip" "$SC2_ZIP_URL"
  # "iagreetotheeula" is Blizzard's public EULA-acceptance password (s2client-proto README).
  unzip -q -o -P iagreetotheeula "$DL/SC2.4.10.zip" -d "$SC2_PARENT"
  rm -f "$DL/SC2.4.10.zip"
fi
curl -fSL --retry 5 -o "$DL/mini_games.zip" "$MINI_GAMES_URL"
mkdir -p "${SC2_PARENT}/StarCraftII/Maps"
unzip -q -o "$DL/mini_games.zip" -d "${SC2_PARENT}/StarCraftII/Maps"
test -f "${SC2_PARENT}/StarCraftII/Maps/mini_games/CollectMineralShards.SC2Map"
echo "setup complete"
