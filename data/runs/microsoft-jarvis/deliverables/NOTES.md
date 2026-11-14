# TaskBench setup notes
- README uses conda (`conda create -n taskbench python=3.8`); conda isn't in the image, so I used `uv python install 3.8` plus a uv venv at /work/venv, then installed requirements.txt as-is. All pins installed without changes.
- Bug in `generate_graph.py`: it writes the output to `tool_file.replace("tools", "graph")`. Since the bundled files are called `tool_desc.json`, that replace changes nothing, so the script overwrote its own input. I patched it to write `graph_desc.json` next to the input. The graphs it now generates for huggingface, multimedia (resource) and dailylifeapis (temporal) match the bundled graph_desc.json files exactly.
- visualize_graph.py calls plt.show(), so env.sh sets MPLBACKEND=Agg to keep it headless. It writes <dir>/graph_desc.pdf.
