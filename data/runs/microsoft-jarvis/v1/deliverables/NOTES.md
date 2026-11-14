# JARVIS / TaskBench generate_graph.py

- README setup uses `conda create -n taskbench python=3.8`; conda isn't in the image, so I used `uv venv --python 3.8 /work/venv` and then `uv pip install -r taskbench/requirements.txt`. All the pins installed on 3.8 with no changes.
- I didn't patch any code. `generate_graph.py` only needs `click` (plus `json` from the standard library).
- Doc issue: the README example `--tool_desc tool_desc.json --data_dir data_multimedia` points at a file that doesn't exist in `taskbench/`. `--tool_desc` has to be the full path, e.g. `data_huggingface/tool_desc.json`, and when it's given, `--data_dir` is ignored.
- Gotcha: the output path is `tool_file.replace("tools","graph")`. `tool_desc.json` doesn't contain "tools", so the script **overwrites the input file** with the graph. That's why you should run it on a copy of the data directory.
- Verified: running on a copy of `data_huggingface/tool_desc.json` gave 23 nodes and 225 links. Every link's type is in the source's output-type and the target's input-type, and the result matches the bundled `graph_desc.json` (23/225).
