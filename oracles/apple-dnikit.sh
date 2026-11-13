set -e
source /work/env.sh
cd /work/dnikit
OUT=$(mktemp -d /tmp/oracle_dnikit.XXXXXX)
cat > $OUT/check.py <<'PY'
import sys, json
import numpy as np
from dnikit.base import pipeline, Batch
from dnikit.samples import StubProducer
from dnikit.introspectors import Duplicates
rs = np.random.RandomState(0)
n = 2000
data = {"a": np.concatenate((rs.normal(10, .01, (200, 10)), rs.normal(100, 50, (n-200, 10)))),
        "c": np.concatenate((rs.normal(10, .01, (1000, 10)), rs.normal(100, 50, (n-1000, 10))))}
class Idx:
    pass
from dnikit.base import PipelineStage
from dataclasses import dataclass
@dataclass(frozen=True)
class AddId(PipelineStage):
    def _get_batch_processor(self):
        c = [0]
        def f(batch):
            b = Batch.Builder(base=batch)
            b.metadata[Batch.StdKeys.IDENTIFIER] = list(range(c[0], c[0]+batch.batch_size))
            c[0] += batch.batch_size
            return b.make_batch()
        return f
prod = pipeline(StubProducer(data), AddId())
d = Duplicates.introspect(prod, threshold=Duplicates.ThresholdStrategy.Percentile(98))
na, nc = len(d.results["a"]), len(d.results["c"])
print("clusters", na, nc)
assert na > 0 and nc > 0 and na < nc, (na, nc)
cand = d.results["c"][0]
assert cand.size >= 2 and len(cand.indices) == cand.size
json.dump({"a": na, "c": nc}, open(sys.argv[1] + "/result.json", "w"))
PY
timeout 900 python $OUT/check.py $OUT
test -s $OUT/result.json
timeout 900 python -m pytest -q -p no:cacheprovider -o addopts="" src/dnikit/tests/test_duplicates.py 2>&1 | tail -5 | tee $OUT/pytest.txt
grep -q "passed" $OUT/pytest.txt
! grep -q "failed" $OUT/pytest.txt
echo "ORACLE PASS"
