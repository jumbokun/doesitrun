set -e
source /work/env.sh
cd /work/T2I-Adapter
OUT=$(mktemp -d /tmp/oracle_out.XXXX)
cat > $OUT/run.py <<'PY'
import sys, torch
from PIL import Image, ImageDraw
from diffusers import StableDiffusionXLAdapterPipeline, T2IAdapter, EulerAncestralDiscreteScheduler, AutoencoderKL
out = sys.argv[1]
# synthetic line-art control image: white lines on black
img = Image.new("RGB", (512, 512), "black")
d = ImageDraw.Draw(img)
d.ellipse((140, 140, 380, 380), outline="white", width=4)
d.line((100, 450, 256, 100, 412, 450), fill="white", width=4)
d.rectangle((60, 60, 450, 450), outline="white", width=3)
img.save(out + "/cond.png")
adapter = T2IAdapter.from_pretrained("TencentARC/t2i-adapter-lineart-sdxl-1.0", torch_dtype=torch.bfloat16)
mid = "stabilityai/stable-diffusion-xl-base-1.0"
sch = EulerAncestralDiscreteScheduler.from_pretrained(mid, subfolder="scheduler")
vae = AutoencoderKL.from_pretrained("madebyollin/sdxl-vae-fp16-fix", torch_dtype=torch.bfloat16)
pipe = StableDiffusionXLAdapterPipeline.from_pretrained(mid, vae=vae, adapter=adapter, scheduler=sch, torch_dtype=torch.bfloat16, variant="fp16")
pipe.to("cpu")
r = pipe(prompt="Ice dragon roar, 4k photo", negative_prompt="anime, cartoon, text, deformed, ugly",
         image=img, height=512, width=512, num_inference_steps=8, adapter_conditioning_scale=0.8,
         guidance_scale=7.5, generator=torch.Generator("cpu").manual_seed(0)).images[0]
r.save(out + "/out_lin.png")
print("SAVED")
PY
timeout 6000 python $OUT/run.py $OUT
python - "$OUT/out_lin.png" <<'PY'
import sys, os
from PIL import Image
p = sys.argv[1]
im = Image.open(p); assert im.size == (512, 512), im.size
assert os.path.getsize(p) > 20000
ex = im.convert("L").getextrema(); assert ex[1] - ex[0] > 40, ex
print("ok", im.size, ex)
PY
echo "ORACLE PASS"
