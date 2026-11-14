# pysc2 setup notes

Setup: Python 3.11 venv (uv) at /work/venv, pysc2 installed from the git clone, StarCraft II
Linux 4.10 package (Blizzard s2client-proto, password `iagreetotheeula` = EULA acceptance)
unzipped to ~/StarCraftII (the default path; env.sh also exports SC2PATH explicitly),
mini_games.zip (v1.2 release) unzipped into ~/StarCraftII/Maps.

What broke / what I changed:
- **Code bug at master HEAD (0df53d3)**: `sc_process._launch` now forwards all kwargs to
  `subprocess.Popen`, but `SC2Env` calls `run_config.start(extra_ports=...)`, so every launch
  died with `TypeError: Popen.__init__() got an unexpected keyword argument 'extra_ports'`.
  Patched: pop `extra_ports` before calling Popen (one line in pysc2/lib/sc_process.py).
- **protobuf**: unpinned install pulls protobuf 7.x; the s2clientprotocol generated `_pb2`
  modules fail to import ("Descriptors cannot be created directly"). Pinned protobuf==3.20.3.
- **Python version**: used 3.11 (highest version in setup.py classifiers) rather than system 3.12.
- **unzip** is not in the base image; installed via apt to extract the (encrypted) SC2 zip.
- The SC2 4.10 package already contains Maps/mini_games; the README's mini_games.zip was
  extracted over it anyway (needs `unzip -o` to run non-interactively).

Verified: random agent (100 steps) and scripted CollectMineralShards agent (full 241-step
episode) run headless; driving SC2Env from Python with the scripted agent gives reward 85–95.
