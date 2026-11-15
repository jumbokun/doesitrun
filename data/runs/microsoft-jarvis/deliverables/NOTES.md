# TaskBench setup notes

- **No conda in the image.** The README runs `conda create -n taskbench python=3.8`. I used uv to make a CPython 3.8 venv (`/work/venv`) instead. After that, `pip install -r requirements.txt` worked with no changes to the pins.
- **generate_graph.py overwrote its own input.** It picks the output path with `tool_file.replace("tools", "graph")`. `tool_desc.json` doesn't contain the string "tools", so the graph was written over the input tool_desc.json and no graph_desc.json was ever made. I patched it (setup.sh applies the patch) so it writes `graph_desc.json` next to the input. It still writes to the old upstream path too, so existing behaviour is kept. That rewrite is harmless because the graph's nodes keep every field the input file had.
- **README example path was wrong.** The README shows `--tool_desc tool_desc.json --data_dir data_multimedia`, but the script ignored `--data_dir` whenever `--tool_desc` was given. Now, if the `--tool_desc` path doesn't exist, it is looked up inside `--data_dir`.
- **Headless plotting.** env.sh sets `MPLBACKEND=Agg` so that `plt.show()` in visualize_graph.py doesn't need a display.
- **Checked:** the regenerated graph_desc.json for huggingface (23 nodes/225 links), multimedia (40/449) and dailylifeapis (temporal, 40/1560) is identical to the bundled files. visualize_graph.py writes graph_desc.pdf.
