set -e
source /work/env.sh
cd /work/data-formulator
timeout 1500 bash /work/run.sh
B=http://127.0.0.1:${PORT:-5567}
O=$(mktemp -d /tmp/oracle.XXXXXX)
python3 - "$O/sales.csv" <<'PY'
import sys
rows=["region,product,units,price"]
for i in range(60):
    rows.append(f"{['north','south','east','west'][i%4]},item{i%7},{i*3+1},{10+i*0.5}")
open(sys.argv[1],"w").write("\n".join(rows)+"\n")
PY
curl -sf "$B/" -o "$O/index.html"
grep -qi "<html" "$O/index.html"
curl -sf "$B/api/app-config" -o "$O/cfg.json"
curl -sf -F "file=@$O/sales.csv" -F table_name=oracle_sales "$B/api/tables/create-table" -o "$O/create.json"
curl -sf "$B/api/tables/list-tables" -o "$O/list.json"
curl -sf "$B/api/tables/get-table?table_name=oracle_sales&page_size=10" -o "$O/get.json"
curl -sf -H 'Content-Type: application/json' -d '{"table":"oracle_sales","size":100,"method":"head"}' "$B/api/tables/sample-table" -o "$O/sample.json"
python3 - "$O" <<'PY'
import sys,json
o=sys.argv[1]
L=lambda n:json.load(open(f"{o}/{n}.json"))
c=L("create"); assert c["status"]=="success" and c["data"]["row_count"]==60, c
assert set(c["data"]["columns"])>={"region","units"}, c
assert "oracle_sales" in json.dumps(L("list")), "not listed"
g=json.dumps(L("get")); assert "item" in g and "north" in g, g[:300]
s=L("sample")["data"]; assert s["total_row_count"]==60 and len(s["rows"])==60, s["total_row_count"]
assert {r["region"] for r in s["rows"]}=={"north","south","east","west"}
assert abs(sum(r["units"] for r in s["rows"])-sum(i*3+1 for i in range(60)))<1e-6
print("checks ok")
PY
echo "ORACLE PASS"
