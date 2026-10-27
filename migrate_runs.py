"""One-off: move batch 1-2 records (local runs/, gitignored) into committed data/runs/.

Adds what newer runs record themselves: hardware track, goal/check, and the replay failure class
computed from the local setup logs with the same classify_replay() the harness now uses.
Usage: python migrate_runs.py repos.json repos_b2.json
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import run_probe  # noqa: E402

for repos_file in sys.argv[1:]:
    for cfg in json.loads((ROOT / repos_file).read_text(encoding="utf-8")):
        rundir = run_probe.RUNS / cfg["slug"]
        path = rundir / "result.json"
        if not path.exists():
            continue
        res = json.loads(path.read_text(encoding="utf-8"))
        res.setdefault("track", "gpu-rtx5060")
        res.setdefault("goal", cfg["goal"])
        res.setdefault("check", cfg["check"])
        for key in ("replay", "replay_supplementary", "replay_after_repair"):
            r = res.get(key)
            if not r or "class" in r or "oracle" not in r:
                continue
            log = rundir / f"{key}_setup.log"
            text = log.read_text(encoding="utf-8", errors="replace") if log.exists() else ""
            r["class"] = run_probe.classify_replay(text, r["oracle"].get("pass"))
        path.write_text(json.dumps(res, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")
        run_probe.export_run(cfg["slug"])
        print(cfg["slug"], {k: res[k].get("class") for k in ("replay", "replay_supplementary", "replay_after_repair")
                            if res.get(k)})
