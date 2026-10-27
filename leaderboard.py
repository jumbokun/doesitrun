"""Build the reproducibility leaderboard from probe runs.

Repo score (0-100, higher = easier to get running), objective inputs only:
    0                                   if the agent could not pass the hidden oracle
    100 - min(50, agent_minutes)        effort: 1 point per agent minute
        - min(40, 10 * files_patched)   repo code that had to change (git diff, whitespace ignored)
Replay on a fresh container is reported next to the score, not in it: it grades the installer we
produced, not the repo's authors. Its failures are classified from the replay log.
Company/team scores are means over attributed repos, shown with n; n < 3 is flagged as too few.

Usage: python leaderboard.py repos.json [repos_b2.json ...]   -> data/leaderboard.json, LEADERBOARD.md
"""
import json
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import attribute  # noqa: E402

DATA = ROOT / "data"
ATTR_CACHE = DATA / "attribution.json"


def classify_replay(rundir, key):
    r = json.loads((rundir / "result.json").read_text(encoding="utf-8")).get(key)
    if not r:
        return "not run"
    if r.get("oracle", {}).get("pass"):
        return "pass"
    log_path = rundir / f"{key}_setup.log"
    log = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
    if re.search(r"network timeout|operation timed out|Read timed out|UV_HTTP_TIMEOUT", log):
        return "fail: download timeout"
    if re.search(r"File not found: /work/|No such file or directory: '?/work/", log):
        return "fail: installer not self-contained"
    return "fail: other"


def repo_score(res):
    if not res["oracle"]["pass"]:
        return 0, "agent could not reproduce"
    minutes = res["agent"]["secs"] / 60
    files = (res.get("repo_diff") or {}).get("files_changed", 0)
    score = 100 - min(50, minutes) - min(40, 10 * files)
    return round(score, 1), f"{minutes:.0f} min, {files} repo files patched"


def main(repo_files):
    DATA.mkdir(exist_ok=True)
    cache = json.loads(ATTR_CACHE.read_text(encoding="utf-8")) if ATTR_CACHE.exists() else {}
    rows = []
    for rf in repo_files:
        for cfg in json.loads((ROOT / rf).read_text(encoding="utf-8")):
            rundir = ROOT / "runs" / cfg["slug"]
            if not (rundir / "result.json").exists():
                continue
            res = json.loads((rundir / "result.json").read_text(encoding="utf-8"))
            if cfg["repo"] not in cache:
                cache[cfg["repo"]] = attribute.attribute(cfg["repo"])
            a = cache[cfg["repo"]]
            score, why = repo_score(res)
            diff = res.get("repo_diff") or {}
            rows.append({
                "repo": cfg["repo"], "batch": rf, "score": score, "why": why,
                "agent_minutes": round(res["agent"]["secs"] / 60, 1),
                "files_patched": diff.get("files_changed"), "lines_patched": diff.get("lines_changed"),
                "replay": classify_replay(rundir, "replay"),
                "replay_supplementary": classify_replay(rundir, "replay_supplementary"),
                "company": a["company"], "team": a["team"], "attribution_confidence": a["confidence"],
                "attribution_evidence": a["evidence"],
            })
    ATTR_CACHE.write_text(json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8")
    rows.sort(key=lambda r: -r["score"])

    groups = {}
    for r in rows:
        groups.setdefault(r["company"], {}).setdefault(r["team"], []).append(r["score"])
    companies = []
    for company, teams in groups.items():
        all_scores = [s for ss in teams.values() for s in ss]
        companies.append({"company": company, "n": len(all_scores), "mean": round(statistics.mean(all_scores), 1),
                          "teams": [{"team": t, "n": len(s), "mean": round(statistics.mean(s), 1)}
                                    for t, s in sorted(teams.items(), key=lambda kv: -statistics.mean(kv[1]))]})
    companies.sort(key=lambda c: -c["mean"])
    (DATA / "leaderboard.json").write_text(json.dumps({"repos": rows, "companies": companies}, indent=2,
                                                      ensure_ascii=False), encoding="utf-8")

    md = ["# Reproducibility leaderboard (v0)", "",
          "How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent "
          "(Claude Code, one `docker exec` tool, RTX 5060 8 GB, CUDA 12.8) tries each repo; a hidden, "
          "pre-registered oracle decides success. Scoring and caveats: see `leaderboard.py` docstring "
          "and WORKLOG.md.", "",
          f"**n = {len(rows)} repos. One run each. Too few per company for company claims; "
          "this table shows the structure, not a verdict.**", "",
          "## Repos (higher = easier)", "",
          "| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |",
          "|---|---|---|---|---|---|---|"]
    for i, r in enumerate(rows, 1):
        replay = r["replay"] + (f" → supplementary: {r['replay_supplementary']}"
                                if r["replay"] != "pass" and r["replay_supplementary"] != "not run" else "")
        md.append(f"| {i} | [{r['repo']}](https://github.com/{r['repo']}) | {r['score']} | "
                  f"{r['agent_minutes']:.0f} min | {r['files_patched']} ({r['lines_patched']} lines) | {replay} | "
                  f"{r['company']} / {r['team']} ({r['attribution_confidence']}) |")
    md += ["", "## Companies (mean repo score)", "", "| company | n | mean | teams |", "|---|---|---|---|"]
    for c in companies:
        flag = " ⚠ n<3" if c["n"] < 3 else ""
        teams = "; ".join(f"{t['team']} {t['mean']} (n={t['n']})" for t in c["teams"])
        md.append(f"| {c['company']}{flag} | {c['n']} | {c['mean']} | {teams} |")
    (ROOT / "LEADERBOARD.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print("\n".join(md))


if __name__ == "__main__":
    main(sys.argv[1:])
