set -e
source /work/env.sh
cd /work/dnikit
OUT=$(mktemp -d /tmp/oracle_dnikit.XXXXXX)
cat > "$OUT/check.py" <<'PY'
import sys, json
from dataclasses import dataclass
import numpy as np
from dnikit.base import pipeline, Batch, PipelineStage
from dnikit.samples import StubProducer
from dnikit.introspectors import Duplicates, DimensionReduction, Familiarity

rs = np.random.RandomState(0)

# --- Duplicates (docs/introspectors/data_introspection/duplicates.rst), planted near-duplicates
# like src/dnikit/tests/test_duplicates.py:56-86 (more duplicates in "c" -> more clusters)
n = 2000
data = {"a": np.concatenate((rs.normal(10, .01, (200, 10)), rs.normal(100, 50, (n - 200, 10)))),
        "c": np.concatenate((rs.normal(10, .01, (1000, 10)), rs.normal(100, 50, (n - 1000, 10))))}
@dataclass(frozen=True)
class AddId(PipelineStage):          # same as AddIndexIdentifier in test_duplicates.py:27-50
    def _get_batch_processor(self):
        c = [0]
        def f(batch):
            b = Batch.Builder(base=batch)
            b.metadata[Batch.StdKeys.IDENTIFIER] = list(range(c[0], c[0] + batch.batch_size))
            c[0] += batch.batch_size
            return b.make_batch()
        return f
d = Duplicates.introspect(pipeline(StubProducer(data), AddId()),
                          threshold=Duplicates.ThresholdStrategy.Percentile(98))
na, nc = len(d.results["a"]), len(d.results["c"])
print("duplicate clusters", na, nc)
assert 0 < na < nc, (na, nc)
cand = d.results["c"][0]
assert cand.size >= 2 and len(cand.indices) == cand.size      # _duplicates.py:162-195

# --- DimensionReduction PCA (dimension_reduction.rst; tests/test_dimension_reduction.py:61-72)
src = StubProducer({"x": rs.randn(300, 40)})
pca = DimensionReduction.introspect(src, strategies=DimensionReduction.Strategy.PCA(8))
shapes = [b.fields["x"].shape for b in pipeline(src, pca)(batch_size=100)]
print("pca shapes", shapes)
assert shapes and all(s[1] == 8 for s in shapes) and sum(s[0] for s in shapes) == 300

# --- Familiarity (familiarity.rst:38-133): fit on in-distribution data, then score; in-distribution
# samples must score clearly higher than far-away samples.
fam = Familiarity.introspect(StubProducer({"x": rs.randn(1000, 5)}))
def scores(arr):
    out = []
    for b in pipeline(StubProducer({"x": arr}), fam)(batch_size=50):
        out += [r.score for r in b.metadata[fam.meta_key]["x"]]
    return np.array(out)
s_in, s_out = scores(rs.randn(100, 5)), scores(rs.randn(100, 5) + 8.0)
print("familiarity mean in/out", s_in.mean(), s_out.mean())
assert len(s_in) == 100 and np.isfinite(s_in).all()
assert s_in.mean() > s_out.mean() + 5, (s_in.mean(), s_out.mean())

json.dump({"a": na, "c": nc}, open(sys.argv[1] + "/result.json", "w"))
print("DNIKIT_OK")
PY
timeout 900 python "$OUT/check.py" "$OUT" | tee "$OUT/check.txt"
grep -q DNIKIT_OK "$OUT/check.txt"
test -s "$OUT/result.json"
# Repo unit tests for the introspectors exercised above; pytest.ini addopts (--mypy/--flake8/--cov) are
# dev-only plugins, so they are cleared. The exit status is checked directly (no pipe).
if ! timeout 900 python -m pytest -q -p no:cacheprovider -o addopts="" \
     src/dnikit/tests/test_duplicates.py "src/dnikit/tests/test_dimension_reduction.py::test_pca" \
     "src/dnikit/tests/test_dimension_reduction.py::test_pca_single" > "$OUT/pytest.txt" 2>&1; then
  tail -30 "$OUT/pytest.txt"; echo "unit tests failed"; exit 1
fi
tail -3 "$OUT/pytest.txt"
grep -q "passed" "$OUT/pytest.txt"
echo "ORACLE PASS"
