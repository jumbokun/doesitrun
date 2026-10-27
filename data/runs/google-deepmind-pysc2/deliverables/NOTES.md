# pysc2 setup notes

Result: `python -m pysc2.bin.agent --map CollectMineralShards --norender --max_episodes 1 --max_agent_steps 200`
runs to completion (exit 0; prints "Took ~0.9 seconds for 200 steps" and writes a replay).

## What broke / what I changed
1. **protobuf too new**: `pip install` pulls protobuf 7.x, but the pre-generated `s2clientprotocol` `_pb2`
   modules fail to import ("Descriptors cannot be created directly"). Pinned `protobuf<=3.20.3`.
2. **Bug at repo HEAD (0df53d3)**: that commit forwards launch kwargs to `subprocess.Popen`, but
   `sc2_env` passes `extra_ports`, so every launch fails with
   `TypeError: Popen.__init__() got an unexpected keyword argument 'extra_ports'`.
   Patched `pysc2/lib/sc_process.py::_launch` to drop `extra_ports` before calling Popen.
3. **Python version**: used Python 3.11 via uv (setup.py lists up to 3.11; the image has 3.12). This was a precaution — I did not test 3.12.
4. **Undocumented system package**: `unzip` isn't in the image; it's needed for the Blizzard zip, which is
   encrypted with the EULA-acceptance password `iagreetotheeula` (documented in Blizzard's s2client-proto README, not in pysc2's).
5. Used SC2 4.10 (`SC2.4.10.zip`, newest Linux build), extracted to the default `~/StarCraftII`; it already
   ships a `Maps/mini_games` folder, and mini_games.zip from the v1.2 release is extracted over it as the README says.
   `env.sh` still exports `SC2PATH=$HOME/StarCraftII` to be explicit (that's the default location anyway).
