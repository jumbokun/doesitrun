set -e
source /work/env.sh
cd /work/data-formulator
timeout 1500 bash /work/run.sh
B=http://127.0.0.1:${PORT:-5567}
O=$(mktemp -d /tmp/oracle.XXXXXX)
# All /api/tables/* routes resolve the workspace from the X-Workspace-Id header, which the frontend
# always sends; the backend creates the workspace lazily on first use
# (py-src/data_formulator/workspace_factory.py:120-147). A single-user localhost request needs no login
# (py-src/data_formulator/auth/identity.py:165-180).
WS="X-Workspace-Id: oracle-ws-$$"
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
curl -sf -H "$WS" -F "file=@$O/sales.csv" -F table_name=oracle_sales "$B/api/tables/create-table" -o "$O/create.json"
curl -sf -H "$WS" "$B/api/tables/list-tables" -o "$O/list.json"
curl -sf -H "$WS" "$B/api/tables/get-table?table_name=oracle_sales&page_size=10" -o "$O/get.json"
curl -sf -H "$WS" -H 'Content-Type: application/json' -d '{"table":"oracle_sales","size":100,"method":"head"}' "$B/api/tables/sample-table" -o "$O/sample.json"
python3 - "$O" <<'PY'
import sys,json
o=sys.argv[1]
L=lambda n:json.load(open(f"{o}/{n}.json"))
cfg=L("cfg"); assert isinstance(cfg, dict) and cfg, cfg
# Envelope {"status":"success","data":...} (py-src/data_formulator/error_handler.py:205-213).
# create-table -> {"table_name","row_count","columns"} (routes/tables.py:782-860)
c=L("create"); assert c["status"]=="success" and c["data"]["row_count"]==60, c
assert set(c["data"]["columns"])>={"region","units"}, c
assert "oracle_sales" in json.dumps(L("list")), "not listed"
# get-table -> {"table_name","columns","rows","total_rows",...} (routes/tables.py:661-705)
g=L("get")["data"]; assert g["total_rows"]==60 and len(g["rows"])==10, (g.get("total_rows"), len(g.get("rows",[])))
gs=json.dumps(g["rows"]); assert "item" in gs and "north" in gs, gs[:300]
# sample-table -> {"rows","total_row_count"} (routes/tables.py:605-659)
s=L("sample")["data"]; assert s["total_row_count"]==60 and len(s["rows"])==60, s["total_row_count"]
assert {r["region"] for r in s["rows"]}=={"north","south","east","west"}
assert abs(sum(r["units"] for r in s["rows"])-sum(i*3+1 for i in range(60)))<1e-6
print("checks ok")
PY
echo "ORACLE PASS"
