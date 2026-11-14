#!/bin/bash
set -euxo pipefail
cd /work
[ -d JARVIS/.git ] || git clone https://github.com/microsoft/JARVIS JARVIS
cd JARVIS/taskbench
# Patch: output path used .replace("tools","graph") which, for tool_desc.json, overwrote the input file.
python3 - <<'PY'
p = "generate_graph.py"
s = open(p).read()
old = 'open(tool_file.replace("tools", "graph"), \'w\')'
if old in s:
    s = s.replace(old, "open(graph_file_for(tool_file), 'w')")
    s = s.replace("import click\n", '''import click
import os

def graph_file_for(tool_file):
    d, b = os.path.split(tool_file)
    if "tool_desc" in b:
        b = b.replace("tool_desc", "graph_desc")
    elif "tools" in b:
        b = b.replace("tools", "graph")
    else:
        b = "graph_desc.json"
    return os.path.join(d, b)
''', 1)
    open(p, "w").write(s)
PY
uv python install 3.8
uv venv --python 3.8 --allow-existing /work/venv
VIRTUAL_ENV=/work/venv uv pip install -r requirements.txt
