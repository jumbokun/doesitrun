"""Backfill result.json["repo_diff"] for runs made before run_probe measured it.

Starts each kept agent container one at a time (memory budget), measures tracked-file edits in the
repo clone with the same repo_diff() the harness now uses, stops it again.
Usage: python backfill_repo_diff.py <repos-file> [<repos-file> ...]
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_probe  # noqa: E402

for repos_file in sys.argv[1:]:
    for cfg in json.loads((ROOT / repos_file).read_text(encoding="utf-8")):
        path = ROOT / "runs" / cfg["slug"] / "result.json"
        if not path.exists():
            continue
        res = json.loads(path.read_text(encoding="utf-8"))
        if "repo_diff" in res:
            continue
        name = f"rr-{cfg['slug']}"
        if run_probe.sh(["docker", "start", name]).returncode:
            print(cfg["slug"], "container missing; skipped")
            continue
        res["repo_diff"] = run_probe.repo_diff(name, cfg["dir"])
        res["repo_diff"]["backfilled"] = True
        run_probe.sh(["docker", "stop", name])
        path.write_text(json.dumps(res, indent=2, ensure_ascii=False), encoding="utf-8")
        d = res["repo_diff"]
        print(cfg["slug"], d.get("files_changed"), "files /", d.get("lines_changed"), "lines",
              [f["path"] for f in d.get("files", [])][:6], d.get("error", ""))
