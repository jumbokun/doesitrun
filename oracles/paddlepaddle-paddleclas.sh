set -e
source /work/env.sh
cd /work/PaddleClas
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 1500 paddleclas --model_name=ResNet50 --infer_imgs="docs/images/inference_deployment/whl_demo.jpg" > $O/cli.txt 2>&1 || { cat $O/cli.txt; exit 1; }
cat $O/cli.txt
grep -q "class_ids: \[8, 7" $O/cli.txt
grep -q "hen" $O/cli.txt
grep -q "Predict complete" $O/cli.txt
timeout 1500 python - <<'P'
from paddleclas import PaddleClas
r = next(PaddleClas(model_name='ResNet50').predict('docs/images/inference_deployment/whl_demo.jpg'))
print(r)
assert r[0]['class_ids'][0] == 8 and r[0]['label_names'][0] == 'hen' and r[0]['scores'][0] > 0.9
P
echo ORACLE PASS
