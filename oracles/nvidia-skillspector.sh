set -e
source /work/env.sh
cd /work/SkillSpector
O=$(mktemp -d /tmp/oracle.XXXXXX)
timeout 900 skillspector scan tests/fixtures/malicious_skill --no-llm --format json --output $O/mal.json
timeout 900 skillspector scan tests/fixtures/safe_skill --no-llm --format json --output $O/safe.json
python3 -I - $O <<'PY'
import json,sys,os
o=sys.argv[1]
m=json.load(open(o+"/mal.json")); s=json.load(open(o+"/safe.json"))
assert os.path.getsize(o+"/mal.json")>500
def count(d):
    f=d.get("findings")
    if f is None:
        for v in d.values():
            if isinstance(v,dict) and isinstance(v.get("findings"),list): f=v["findings"]
    assert isinstance(f,list), list(d)
    return len(f)
cm,cs=count(m),count(s)
print(cm,cs)
assert cm>=1 and cm>cs
PY
# markdown output as second format
timeout 900 skillspector scan tests/fixtures/malicious_skill --no-llm --format markdown --output $O/mal.md
test $(wc -c < $O/mal.md) -gt 300
echo "ORACLE PASS"
