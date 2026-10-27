set -e
source /work/env.sh
cd /work/Sana
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cat > $OUT/t.py <<'PY'
import sys, torch
from diffusers import SanaPipeline
out = sys.argv[1]
pipe = SanaPipeline.from_pretrained("Efficient-Large-Model/Sana_600M_512px_diffusers", torch_dtype=torch.bfloat16)
pipe.to("cpu")
img = pipe(prompt='a cyberpunk cat with a neon sign that says "Sana"', height=512, width=512,
           guidance_scale=4.5, num_inference_steps=8,
           generator=torch.Generator(device="cpu").manual_seed(42)).images[0]
img.save(out + "/sana.png")
PY
timeout 6000 python $OUT/t.py $OUT
python - "$OUT/sana.png" <<'PY'
import sys, os
from PIL import Image
p = sys.argv[1]
assert os.path.getsize(p) > 20000, "too small"
im = Image.open(p); assert im.size == (512, 512), im.size
ex = im.convert("L").getextrema(); assert ex[1] - ex[0] > 50, "image looks blank"
PY
echo ORACLE PASS
