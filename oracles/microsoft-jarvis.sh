set -e
source /work/env.sh
cd /work/JARVIS
OUT=$(mktemp -d /tmp/oracle_graph_XXXXXX)
for d in data_huggingface data_multimedia; do
  mkdir -p $OUT/$d
  cp taskbench/$d/tool_desc.json $OUT/$d/tool_desc.json
  cp $OUT/$d/tool_desc.json $OUT/$d/orig.json
  (cd taskbench && timeout 300 python generate_graph.py --tool_desc $OUT/$d/tool_desc.json --dependency_type resource --data_dir $OUT/$d)
done
python - "$OUT" <<'P'
import json,sys,os
out=sys.argv[1]
for d in ["data_huggingface","data_multimedia"]:
    orig=json.load(open(f"{out}/{d}/orig.json"))["nodes"]
    g=None
    for f in ["tool_desc.json","tool_desc.json".replace("tools","graph")]:
        g=json.load(open(f"{out}/{d}/{f}"))
    assert "links" in g, f"{d}: no links in output"
    assert len(g["nodes"])==len(orig)>5, d
    ids={n["id"]:n for n in g["nodes"]}
    assert len(g["links"])>10, d
    for l in g["links"]:
        s,t=ids[l["source"]],ids[l["target"]]
        assert l["source"]!=l["target"]
        assert l["type"] in s["output-type"] and l["type"] in t["input-type"], l
    exp=sum(1 for a in orig for b in orig if a is not b and set(a["output-type"])&set(b["input-type"]))
    assert len(g["links"])==exp,(d,len(g["links"]),exp)
    print(d,len(g["nodes"]),"nodes",len(g["links"]),"links")
P
echo "ORACLE PASS"
