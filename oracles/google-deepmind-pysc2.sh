set -e
source /work/env.sh
cd /work/pysc2
out=$(mktemp -d /tmp/oracle.XXXXXX)

# 1) README "Run an agent" CLI with the default random agent, headless (README.md:120-128;
#    --render/--max_episodes/--max_agent_steps/--save_replay flags: pysc2/bin/agent.py:32,50,52,76).
timeout 1200 python -m pysc2.bin.agent --map CollectMineralShards --norender \
  --max_episodes 1 --max_agent_steps 100 --nosave_replay > $out/cli.txt 2>&1 || { tail -30 $out/cli.txt; exit 1; }
grep -qi "Traceback" $out/cli.txt && { tail -30 $out/cli.txt; exit 1; }
# run_loop prints "Took X seconds for N steps" in its finally block (pysc2/env/run_loop.py:49-50)
grep -Eq "Took [0-9.]+ seconds for [0-9]+ steps" $out/cli.txt || { tail -30 $out/cli.txt; exit 1; }

# 2) README's scripted-agent example on the same map (README.md:130-132), headless CLI.
timeout 1200 python -m pysc2.bin.agent --map CollectMineralShards \
  --agent pysc2.agents.scripted_agent.CollectMineralShards --norender \
  --max_episodes 1 --max_agent_steps 100 --nosave_replay > $out/cli2.txt 2>&1 || { tail -30 $out/cli2.txt; exit 1; }
grep -qi "Traceback" $out/cli2.txt && { tail -30 $out/cli2.txt; exit 1; }

# 3) Same scripted agent through the Python API with inspectable observations and reward.
#    BaseAgent.step accumulates obs.reward (pysc2/agents/base_agent.py); each mineral shard is +1,
#    and scripted_agent.CollectMineralShards walks the marines to the nearest shard, so 300 agent
#    steps (2400 game loops at step_mul 8) must collect at least one shard on a working install.
cat > $out/check.py <<'P'
import numpy as np
from absl import app
from pysc2.env import sc2_env, run_loop
from pysc2.lib import actions
from pysc2.agents import scripted_agent

def main(_):
  aif = sc2_env.AgentInterfaceFormat(
      feature_dimensions=sc2_env.Dimensions(screen=64, minimap=64))
  with sc2_env.SC2Env(map_name="CollectMineralShards",
      players=[sc2_env.Agent(sc2_env.Race.terran)],
      agent_interface_format=aif, step_mul=8, game_steps_per_episode=0,
      visualize=False) as env:
    ts = env.reset()[0]
    scr = ts.observation["feature_screen"]
    assert scr.shape[1:] == (64, 64), scr.shape
    for _ in range(20):
      ts = env.step([actions.FunctionCall(actions.FUNCTIONS.no_op.id, [])])[0]
    assert ts.observation["game_loop"][0] >= 160, ts.observation["game_loop"]
    assert np.asarray(ts.observation["feature_screen"]).any()
    print("OBS_OK", scr.shape, ts.observation["game_loop"][0])

    agent = scripted_agent.CollectMineralShards()
    run_loop.run_loop([agent], env, max_frames=300, max_episodes=1)
    print("SCRIPTED_REWARD", agent.reward, "steps", agent.steps)
    assert agent.steps >= 250, agent.steps
    assert agent.reward > 0, agent.reward
    print("REWARD_OK")
app.run(main)
P
timeout 900 python $out/check.py > $out/check.txt 2>&1 || { tail -30 $out/check.txt; exit 1; }
tail -5 $out/check.txt
grep -q OBS_OK $out/check.txt
grep -q REWARD_OK $out/check.txt
echo ORACLE PASS
