set -e
source /work/env.sh
cd /work/game-center-tools
O=$(mktemp -d /tmp/oracle.XXXX)
echo '[{"secondsInQueue":20,"skill":1},{"secondsInQueue":10,"skill":50},[{"skill":20},{"skill":30}]]' | timeout 120 python3 scripts/genrulesinput.py > $O/out.json
python3 - $O/out.json <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
assert len(d["requests"])==3, d.keys()
assert [p["properties"]["skill"] for p in d["players"]]==[1,50,20,30]
assert [r["secondsInQueue"] for r in d["requests"]]==[20,10,0]
assert d["requests"][0]["requestName"]=="r1"
P
echo ORACLE PASS
