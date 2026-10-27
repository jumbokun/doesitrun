set -e
source /work/env.sh
cd /work/sonnet
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
# README API snippets
timeout 600 python - <<'PY'
import tensorflow as tf, sonnet as snt
print(snt.__version__)
mlp = snt.Sequential([snt.Linear(1024), tf.nn.relu, snt.Linear(10)])
out = mlp(tf.random.normal([8, 784]))
assert out.shape == (8, 10)
assert len(mlp.trainable_variables) == 4
class MyLinear(snt.Module):
  def __init__(self, output_size, name=None):
    super().__init__(name=name)
    self.output_size = output_size
  @snt.once
  def _initialize(self, x):
    self.w = tf.Variable(tf.random.normal([x.shape[1], self.output_size]), name="w")
    self.b = tf.Variable(tf.zeros([self.output_size]), name="b")
  def __call__(self, x):
    self._initialize(x)
    return tf.matmul(x, self.w) + self.b
m = MyLinear(32)
assert m(tf.ones([4, 16])).shape == (4, 32)
assert "MyLinear(output_size=32)" in repr(m)
assert len(m.variables) == 2
print("README API OK")
PY
# Official training example
timeout 3000 python examples/simple_mnist.py > $OUT/log.txt 2>&1 || { tail -30 $OUT/log.txt; exit 1; }
cat $OUT/log.txt | grep '^\[Epoch'
test "$(grep -c '^\[Epoch' $OUT/log.txt)" -eq 5
python - "$OUT/log.txt" <<'PY'
import re,sys
accs=[float(x) for x in re.findall(r'test acc: ([\d.]+)%', open(sys.argv[1]).read())]
assert len(accs)==5 and accs[-1] > 90, accs
print("final acc", accs[-1])
PY
echo "ORACLE PASS"
