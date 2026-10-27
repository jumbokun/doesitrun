set -e
source /work/env.sh
cd /work/pyright
O=$(mktemp -d /tmp/oracle.XXXXXX)
mkdir -p $O/proj
cat > $O/proj/bad.py <<'P'
def f(x: int) -> str:
    return x

y: int = "hello"
f("a")
P
cat > $O/proj/good.py <<'P'
def g(x: int) -> int:
    return x + 1

print(g(2))
P
CLI=/work/pyright/packages/pyright/index.js
test -f $CLI
cd $O/proj
set +e
timeout 600 node $CLI --outputjson bad.py > $O/bad.json 2> $O/bad.err
rc1=$?
timeout 600 node $CLI good.py > $O/good.txt 2>&1
rc2=$?
timeout 600 node $CLI --version > $O/ver.txt 2>&1
set -e
echo "rc bad=$rc1 good=$rc2"; cat $O/good.txt $O/ver.txt
[ "$rc1" = 1 ] || { echo "bad rc"; exit 1; }
[ "$rc2" = 0 ] || { echo "good rc"; exit 1; }
python3 -I - $O/bad.json <<'P'
import json,sys
d=json.load(open(sys.argv[1]))
errs=[x for x in d["generalDiagnostics"] if x["severity"]=="error"]
print(len(errs), d["summary"])
assert d["summary"]["errorCount"]>=3 and len(errs)>=3
lines={x["range"]["start"]["line"] for x in errs}
assert {1,3,4}<=lines, lines
assert d["summary"]["filesAnalyzed"]==1
P
grep -q "0 errors" $O/good.txt
grep -qi "pyright" $O/ver.txt
echo "ORACLE PASS"
