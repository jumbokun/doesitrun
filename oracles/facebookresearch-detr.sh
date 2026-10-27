set -e
source /work/env.sh
cd /work/detr
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 120 curl -sfL -o $OUT/cats.jpg http://images.cocodataset.org/val2017/000000039769.jpg
cat > $OUT/run.py <<'PY'
import sys, torch, json
from PIL import Image
import torchvision.transforms as T
out = sys.argv[1]
model, post = torch.hub.load('/work/detr', 'detr_resnet50', source='local', pretrained=True, return_postprocessor=True)
model.eval()
img = Image.open(out + '/cats.jpg').convert('RGB')
tf = T.Compose([T.Resize(800), T.ToTensor(), T.Normalize([0.485,0.456,0.406],[0.229,0.224,0.225])])
x = tf(img).unsqueeze(0)
with torch.no_grad():
    o = model(x)
assert o['pred_logits'].shape == (1,100,92), o['pred_logits'].shape
assert o['pred_boxes'].shape == (1,100,4)
r = post(o, torch.tensor([[img.height, img.width]]))[0]
keep = r['scores'] > 0.9
labels = r['labels'][keep].tolist()
print('labels', labels, 'scores', r['scores'][keep].tolist())
json.dump({'labels': labels}, open(out + '/res.json', 'w'))
PY
timeout 1500 python $OUT/run.py $OUT
python - $OUT <<'PY'
import json, sys
l = json.load(open(sys.argv[1] + '/res.json'))['labels']
assert l.count(17) >= 2, l   # COCO id 17 = cat
assert 75 in l, l            # remote
PY
echo ORACLE PASS
