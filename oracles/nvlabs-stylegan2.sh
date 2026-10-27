set -e
source /work/env.sh
cd /work/stylegan2
OUT=$(mktemp -d /tmp/oracle-out.XXXXXX)
timeout 5400 python run_generator.py generate-images --network=gdrive:networks/stylegan2-ffhq-config-f.pkl --seeds=66,230 --truncation-psi=1.0 --result-dir="$OUT"
python - "$OUT" <<'P'
import sys,glob
from PIL import Image
import numpy as np
for s in ("0066","0230"):
    f=glob.glob(sys.argv[1]+"/**/seed%s.png"%s,recursive=True)
    assert f, "missing seed"+s
    im=Image.open(f[0]).convert("RGB")
    assert im.size==(1024,1024), im.size
    a=np.asarray(im)
    assert a.std()>20, "image looks blank"
    print(f[0],im.size,a.std())
P
echo ORACLE PASS
