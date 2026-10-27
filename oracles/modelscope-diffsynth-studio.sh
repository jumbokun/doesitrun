set -e
source /work/env.sh
cd /work/DiffSynth-Studio
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/run.py <<P
import torch
from diffsynth.core import ModelConfig
from diffsynth.pipelines.stable_diffusion import StableDiffusionPipeline
M="AI-ModelScope/stable-diffusion-v1-5"
pipe = StableDiffusionPipeline.from_pretrained(
    torch_dtype=torch.float32, device="cpu",
    model_configs=[
        ModelConfig(model_id=M, origin_file_pattern="text_encoder/model.safetensors"),
        ModelConfig(model_id=M, origin_file_pattern="unet/diffusion_pytorch_model.safetensors"),
        ModelConfig(model_id=M, origin_file_pattern="vae/diffusion_pytorch_model.safetensors"),
    ],
    tokenizer_config=ModelConfig(model_id=M, origin_file_pattern="tokenizer/"),
)
img = pipe(prompt="a photo of a red apple on a wooden table, high quality", negative_prompt="blurry",
    cfg_scale=7.5, height=512, width=512, seed=1, rand_device="cpu", num_inference_steps=15)
img.save("$OUT/out.png")
P
timeout 5400 python $OUT/run.py
python - <<P
from PIL import Image
import numpy as np
im=Image.open("$OUT/out.png").convert("RGB")
assert im.size==(512,512), im.size
a=np.asarray(im).astype(float)
assert a.std()>15, a.std()
print("ok",a.std())
P
echo "ORACLE PASS"
