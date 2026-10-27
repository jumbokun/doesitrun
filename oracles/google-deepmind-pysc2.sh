set -e
source /work/env.sh
cd /work/pysc2
out=$(mktemp -d /tmp/oracle.XXXXXX)
# README CLI demo, headless
timeout 1200 python -m pysc2.bin.agent --map CollectMineralShards --norender --max_episodes 1 --max_agent_steps 100 --nosave_replay > $out/cli.txt 2>&1 || { tail -30 $out/cli.txt; exit 1; }
grep -qi "Traceback" $out/cli.txt && { tail -30 $out/cli.txt; exit 1; }
# direct env check with inspectable observations
cat > $out/check.py <<'P'
import numpy as np
from absl import app
from pysc2.env import sc2_env
from pysc2.lib import actions
def main(_):
  with sc2_env.SC2Env(map_name="CollectMineralShards",
      players=[sc2_env.Agent(sc2_env.Race.terran)],
      agent_interface_format=sc2_env.AgentInterfaceFormat(
          feature_dimensions=sc2_env.Dimensions(screen=64, minimap=64)),
      step_mul=8, game_steps_per_episode=0, visualize=False) as env:
    ts = env.reset()[0]
    scr = ts.observation["feature_screen"]
    assert scr.shape[1:] == (64, 64), scr.shape
    for _ in range(20):
      ts = env.step([actions.FunctionCall(actions.FUNCTIONS.no_op.id, [])])[0]
    assert ts.observation["game_loop"][0] >= 160, ts.observation["game_loop"]
    assert np.asarray(ts.observation["feature_screen"]).any()
    print("OBS_OK", scr.shape, ts.observation["game_loop"][0])
app.run(main)
P
timeout 600 python $out/check.py 2>&1 | tee $out/check.txt | tail -5
grep -q OBS_OK $out/check.txt
echo ORACLE PASS
