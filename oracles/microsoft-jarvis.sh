set -e
source /work/env.sh
cd /work/JARVIS/taskbench
OUT=$(mktemp -d /tmp/oracle_graph_XXXXXX)

# 1) Resource-dependency graphs (taskbench/README.md:227-236; generate_graph.py:4-20).
#    Output path is tool_file.replace("tools","graph") (generate_graph.py:19), i.e. the input file
#    itself for tool_desc.json, so every run works on a copy under $OUT. A fix that writes the
#    graph to graph_desc.json next to the input (the file visualize_graph.py reads) is accepted too.
for d in data_huggingface data_multimedia; do
  mkdir -p $OUT/$d
  cp $d/tool_desc.json $OUT/$d/tool_desc.json
  cp $d/tool_desc.json $OUT/$d/orig.json
  timeout 300 python generate_graph.py --tool_desc $OUT/$d/tool_desc.json --dependency_type resource --data_dir $OUT/$d
done

# 2) Temporal-dependency graph for the API-style library (README.md:227 "For API with request
#    parameters, we use the temporal dependency graph"; generate_graph.py:22-43).
d=data_dailylifeapis
mkdir -p $OUT/$d
cp $d/tool_desc.json $OUT/$d/tool_desc.json
cp $d/tool_desc.json $OUT/$d/orig.json
timeout 300 python generate_graph.py --tool_desc $OUT/$d/tool_desc.json --dependency_type temporal --data_dir $OUT/$d

python - "$OUT" <<'P'
import json, os, sys
out = sys.argv[1]
def graph(d):
    p = f"{out}/{d}/graph_desc.json"
    return json.load(open(p if os.path.exists(p) else f"{out}/{d}/tool_desc.json"))
for d in ["data_huggingface", "data_multimedia"]:
    orig = json.load(open(f"{out}/{d}/orig.json"))["nodes"]
    g = graph(d)
    assert "links" in g, f"{d}: no links in output"
    assert len(g["nodes"]) == len(orig) > 5, d
    ids = {n["id"]: n for n in g["nodes"]}
    for l in g["links"]:
        s, t = ids[l["source"]], ids[l["target"]]
        assert l["source"] != l["target"]
        assert l["type"] in s["output-type"] and l["type"] in t["input-type"], l
    # generate_graph.py:13-17: one link per ordered pair (i != j) with overlapping types
    exp = sum(1 for a in orig for b in orig if a is not b and set(a["output-type"]) & set(b["input-type"]))
    assert len(g["links"]) == exp > 10, (d, len(g["links"]), exp)
    print(d, len(g["nodes"]), "nodes", len(g["links"]), "links")
d = "data_dailylifeapis"
orig = json.load(open(f"{out}/{d}/orig.json"))["nodes"]
g = graph(d)
n = len(orig)
assert len(g["nodes"]) == n > 5 and all("parameters" in x for x in g["nodes"]), d
# generate_graph.py:36-40: complete directed graph, type "complete"
assert len(g["links"]) == n * (n - 1), (len(g["links"]), n)
assert all(l["type"] == "complete" and l["source"] != l["target"] for l in g["links"])
print(d, n, "nodes", len(g["links"]), "links")
P

# 3) Visualize a generated graph (README.md:236 "check the tool graph through the visualization
#    tool visualize_graph.py"; visualize_graph.py:9-34 reads <data_dir>/graph_desc.json and saves
#    graph_desc.pdf next to it). Exercises networkx/matplotlib/scipy from requirements.txt.
V=$OUT/vis
mkdir -p $V
G=$OUT/data_huggingface/graph_desc.json; [ -f $G ] || G=$OUT/data_huggingface/tool_desc.json
cp $G $V/graph_desc.json
MPLBACKEND=Agg timeout 600 python visualize_graph.py --data_dir $V
test -s $V/graph_desc.pdf
head -c 4 $V/graph_desc.pdf | grep -q '%PDF'
[ "$(stat -c %s $V/graph_desc.pdf)" -gt 2000 ]
echo "ORACLE PASS"
