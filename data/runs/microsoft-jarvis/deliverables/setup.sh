#!/usr/bin/env bash
# Reproduce the TaskBench environment (CPU only).
set -euo pipefail
cd /work
[ -d JARVIS/.git ] || git clone https://github.com/microsoft/JARVIS /work/JARVIS
# README uses conda python=3.8; we use uv-managed CPython 3.8 instead (no conda in image)
uv venv --allow-existing -p 3.8 /work/venv
VIRTUAL_ENV=/work/venv uv pip install -p /work/venv/bin/python -r /work/JARVIS/taskbench/requirements.txt
# Fix generate_graph.py writing its output over the input tool_desc.json
python3 - /work/JARVIS/taskbench/generate_graph.py <<'PYEOF'
import sys, re
p = sys.argv[1]
s = open(p).read()
if "def output_file(" in s:
    sys.exit(0)
s = s.replace("import json\nimport click\n", '''import json
import os
import click

def output_file(tool_file):
    # tool_desc.json -> graph_desc.json in the same directory (upstream only replaced "tools")
    dirname, basename = os.path.split(tool_file)
    if "tool_desc" in basename:
        basename = basename.replace("tool_desc", "graph_desc")
    elif "tools" in basename:
        basename = basename.replace("tools", "graph")
    else:
        basename = "graph_desc.json"
    return os.path.join(dirname, basename)

def save_graph(graph, tool_file):
    with open(output_file(tool_file), 'w') as f:
        json.dump(graph, f, indent=2)
    # keep upstream behaviour of also writing to tool_file.replace("tools", "graph")
    legacy_file = tool_file.replace("tools", "graph")
    if legacy_file != output_file(tool_file):
        with open(legacy_file, 'w') as f:
            json.dump(graph, f, indent=2)
''', 1)
old = '''    with open(tool_file.replace("tools", "graph"), 'w') as f:
        json.dump(graph, f, indent=2)'''
assert s.count(old) == 2
s = s.replace(old, "    save_graph(graph, tool_file)")
old2 = '''    if tool_desc:
        tool_file = tool_desc
'''
assert old2 in s
s = s.replace(old2, '''    if tool_desc:
        tool_file = tool_desc
        if data_dir and not os.path.exists(tool_file):
            tool_file = os.path.join(data_dir, tool_desc)
''')
open(p, 'w').write(s)
PYEOF
