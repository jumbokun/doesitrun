set -e
source /work/env.sh
OUT=$(mktemp -d /tmp/oracle_out.XXXXXX)
cd "$OUT"   # outputs go to --work-dir; no need to run from the source tree
# README.md:201-210 "Method 2. Evaluate a Local Model": --datasets gsm8k arc --limit 5
# --work-dir: evalscope/arguments.py:94
timeout 3300 evalscope eval --model Qwen/Qwen2.5-0.5B-Instruct --datasets gsm8k arc --limit 5 --work-dir "$OUT/wd" 2>&1 | tail -n 40
python - "$OUT/wd" <<'P'
import sys, glob, json, os
out = sys.argv[1]
def report(name):
    # reports/<model_name>/<benchmark>.json  (evalscope/api/evaluator/cache.py:303-319)
    fs = glob.glob(os.path.join(out, '**', 'reports', '**', name + '.json'), recursive=True)
    assert fs, "no %s report json found" % name
    d = json.load(open(fs[0], encoding='utf-8'))
    ms = d.get('metrics') or []
    assert ms, ("no metrics in report", fs[0])
    m = ms[0]
    assert isinstance(m.get('score'), (int, float)) and 0.0 <= m['score'] <= 1.0, m
    print(name, "report", fs[0], "score", m['score'], "num", m.get('num'))
    return m
def reviews(name):
    # reviews/<model_name>/<benchmark>_<subset>.jsonl  (evalscope/api/evaluator/cache.py:235)
    fs = glob.glob(os.path.join(out, '**', 'reviews', '**', name + '_*.jsonl'), recursive=True)
    assert fs, "no %s review jsonl found" % name
    rows = [json.loads(l) for f in fs for l in open(f, encoding='utf-8') if l.strip()]
    for r in rows:
        txt = ''
        for msg in r.get('messages') or []:
            if msg.get('role') == 'assistant':
                c = msg.get('content')
                txt += c if isinstance(c, str) else json.dumps(c, ensure_ascii=False)
        assert txt.strip(), ("empty model answer in review row", str(r)[:400])
    return rows
g = report('gsm8k'); assert g.get('num') == 5, g          # gsm8k has one subset 'main' (gsm8k_adapter.py:67)
a = report('arc');   assert (a.get('num') or 0) >= 5, a  # arc has ARC-Easy + ARC-Challenge (arc_adapter.py:48)
assert len(reviews('gsm8k')) >= 5
assert len(reviews('arc')) >= 5
P
echo ORACLE PASS
