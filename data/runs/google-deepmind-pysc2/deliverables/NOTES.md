# pysc2 setup notes
- Python: used uv venv with Python 3.11 (setup.py classifiers stop at 3.11; image has 3.12).
- `pip install` pulls protobuf 7.x, which fails importing s2clientprotocol's old generated `_pb2` files
  ("Descriptors cannot be created directly"). Pinned `protobuf<3.21`; also pinned `numpy<2` for safety.
- Upstream HEAD (0df53d3) bug: `sc_process._launch` forwards all kwargs to `subprocess.Popen`, including
  `extra_ports` from `SC2Env` -> `TypeError: Popen.__init__() got an unexpected keyword argument 'extra_ports'`.
  Patched `_launch` to drop `extra_ports`.
- SC2 Linux 4.10 zip from Blizzard (archive password `iagreetotheeula` as given by the Blizzard docs, i.e. EULA acceptance);
  needed `unzip` apt package (not in image). Extracted to ~/StarCraftII (default path; env.sh still exports SC2PATH).
- mini_games.zip extracted to ~/StarCraftII/Maps/ worked as documented.
- Verified: random agent 100 steps OK; scripted CollectMineralShards agent headless scores 84 shards.
