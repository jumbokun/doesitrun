set -e
source /work/env.sh
cd /work/chalice
timeout 1500 bash /work/run.sh
out=$(mktemp -d /tmp/oracle.XXXXXX)
(cd $out && timeout 120 chalice new-project demoapp)
test -s $out/demoapp/app.py
grep -q "@app.route" $out/demoapp/app.py
test -f $out/demoapp/.chalice/config.json
code=$(curl -s -o $out/resp.json -w '%{http_code}' --max-time 30 http://127.0.0.1:8000/)
[ "$code" = 200 ]
python3 -I -c "import json,sys; assert json.load(open(sys.argv[1]))=={'hello':'world'}" $out/resp.json
echo "ORACLE PASS"
