set -e
source /work/env.sh
cd /work/gym
mkdir -p /tmp/oracle_out && cat > /tmp/oracle_out/t.py <<'P'
import gym, numpy as np
print("gym", gym.__version__)
env = gym.make("CartPole-v1")
observation, info = env.reset(seed=42)
assert np.asarray(observation).shape == (4,), observation
eps = 0; steps = 0
for _ in range(1000):
    action = env.action_space.sample()
    observation, reward, terminated, truncated, info = env.step(action)
    steps += 1
    assert np.asarray(observation).shape == (4,)
    if terminated or truncated:
        eps += 1
        observation, info = env.reset()
env.close()
print("steps", steps, "episodes", eps)
assert steps == 1000 and eps >= 5
open("/tmp/oracle_out/result.txt", "w").write("ok %d\n" % eps)
P
timeout 600 python /tmp/oracle_out/t.py
grep -q '^ok' /tmp/oracle_out/result.txt
echo "ORACLE PASS"
