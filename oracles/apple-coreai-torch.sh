set -e
source /work/env.sh
cd /work/coreai-torch
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/t.py <<'PY'
import asyncio, sys, numpy as np, torch, torch.nn as nn
from pathlib import Path
from coreai.runtime import NDArray
from coreai_torch import TorchConverter, get_decomp_table
out = Path(sys.argv[1])
torch.manual_seed(1)
class M(nn.Module):
    def __init__(s):
        super().__init__(); s.a=nn.Linear(10,20); s.r=nn.ReLU(); s.b=nn.Linear(20,5)
    def forward(s,x): return s.b(s.r(s.a(x)))
m = M().eval()
x = (torch.randn(3, 10),)
ep = torch.export.export(m, args=x).run_decompositions(get_decomp_table())
prog = TorchConverter().add_exported_program(ep, input_names=["x"], output_names=["out"]).to_coreai()
async def run():
    asset = prog.save_asset(out / "m.aimodel")
    assert (out / "m.aimodel").exists()
    async with asset.executable() as mm:
        f = mm.load_function("main")
        o = await f({"x": NDArray(x[0])})
        return o["out"].numpy()
got = asyncio.run(run())
with torch.no_grad(): ref = m(x[0]).numpy()
print("shapes", got.shape, ref.shape)
assert got.shape == (3, 5)
assert np.allclose(got, ref, atol=1e-4), np.abs(got-ref).max()
assert np.abs(got).sum() > 0
print("MATCH")
PY
timeout 1200 python $OUT/t.py $OUT | tee $OUT/log.txt
grep -q '^MATCH' $OUT/log.txt
echo "ORACLE PASS"
