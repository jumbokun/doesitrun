"""Pre-register the maintained subset of data/candidates.json.

Rule (fixed before any exam or run of the new repos): a candidate is in the set if, when this script runs,
GitHub reports it not archived and its last push is within WINDOW_DAYS. Every registered company's
candidates are scanned, not only the ones probed so far, and the examiner then screens every repo in the
set (no per-company cap). The snapshot of pushed_at/archived is stored, so the set never drifts.
Usage: python active_set.py  -> data/active.json
"""
import datetime
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
WINDOW_DAYS = 92  # "the last 3 months"


def repo_state(repo):
    p = subprocess.run(["gh", "api", f"repos/{repo}", "--jq",
                        "{archived: .archived, pushed: .pushed_at, stars: .stargazers_count}"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if p.returncode:
        raise RuntimeError(f"{repo}: {p.stderr.strip()}")
    return json.loads(p.stdout)


def main():
    today = datetime.datetime.now(datetime.timezone.utc).date()
    cutoff = (today - datetime.timedelta(days=WINDOW_DAYS)).isoformat()
    cands = json.loads((ROOT / "data" / "candidates.json").read_text(encoding="utf-8"))["companies"]
    out = {"rule": __doc__.strip().splitlines()[2:6], "as_of": today.isoformat(), "pushed_since": cutoff,
           "companies": {}}
    for company, spec in cands.items():
        kept = []
        for c in spec["candidates"]:
            s = repo_state(c["repo"])
            if not s["archived"] and s["pushed"][:10] >= cutoff:
                kept.append({"slug": c["slug"], "repo": c["repo"], "stars": s["stars"], "pushed": s["pushed"]})
        out["companies"][company] = kept
        print(f"{company}: {len(kept)} of {len(spec['candidates'])} maintained", flush=True)
    print("total", sum(len(v) for v in out["companies"].values()))
    (ROOT / "data" / "active.json").write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8",
                                               newline="\n")


if __name__ == "__main__":
    main()
