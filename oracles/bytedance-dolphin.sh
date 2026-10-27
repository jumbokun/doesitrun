set -e
source /work/env.sh
cd /work/Dolphin
M=./hf_model
[ -d "$M" ] || { echo "model dir missing"; exit 1; }
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
timeout 6000 python demo_page.py --model_path "$M" --save_dir "$OUT" --input_path ./demo/page_imgs/page_1.png
J="$OUT/output_json/page_1.json"
MD="$OUT/markdown/page_1.md"
[ -s "$J" ] || { echo "missing json"; exit 1; }
[ -s "$MD" ] || { echo "missing md"; exit 1; }
python - "$J" "$MD" <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert isinstance(d,(list,dict)) and len(d)>=2, "too few elements"
t=open(sys.argv[2],encoding="utf-8").read()
assert len(t.strip())>=100, "markdown too short"
print("elements:",len(d),"md chars:",len(t))
P
echo "ORACLE PASS"
