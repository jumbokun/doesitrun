"""Build the reproducibility leaderboard from committed run records (data/runs/<slug>/result.json).

Repo score (0-100, higher = easier to get running), objective inputs only:
    0                                   if the agent could not pass the hidden oracle
    100 - min(50, agent_minutes)        effort: 1 point per agent minute
        - min(40, 10 * files_patched)   repo code that had to change (git diff, whitespace ignored)
Replay on a fresh container is reported next to the score, not in it: it grades the installer we
produced, not the repo's authors. Scores from different hardware tracks are never mixed.
Company/team scores are means over attributed repos per track, shown with n; n < 3 is flagged.

Usage: python leaderboard.py   -> data/leaderboard.json, LEADERBOARD.md
"""
import json
import pathlib
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
import attribute  # noqa: E402

DATA = ROOT / "data"
ATTR_CACHE = DATA / "attribution.json"
TRACK_LABELS = {"cpu-gha": "CPU · GitHub-hosted runner (4 vCPU, 16 GB)",
                "gpu-rtx5060": "GPU · RTX 5060 Laptop 8 GB"}


def replay_class(res, key):
    r = res.get(key)
    if not r:
        return "not run"
    return r.get("class") or ("pass" if r.get("oracle", {}).get("pass") else "fail: other")


def repo_score(res):
    if not res["oracle"]["pass"] and res["agent"].get("timed_out"):
        # The oracle never had a finished install to judge, so no audit can unscore this: not reproduced
        # within the 90-minute budget.
        return 0, "agent hit the time limit before the demo ran"
    if not res["oracle"]["pass"] and (res.get("audit") or {}).get("verdict") == "oracle_defect":
        return None, "not scored: the pre-registered audit found the hidden oracle defective"
    if not res["oracle"]["pass"]:
        return 0, "agent could not reproduce"
    minutes = res["agent"]["secs"] / 60
    files = (res.get("repo_diff") or {}).get("files_changed", 0)
    return round(100 - min(50, minutes) - min(40, 10 * files), 1), f"{minutes:.0f} min, {files} repo files patched"


def company_table(rows):
    groups = {}
    for r in rows:
        if r["score"] is None:
            continue  # audited oracle defect: excluded from every mean
        groups.setdefault(r["company"], {}).setdefault(r["team"], []).append(r["score"])
    out = []
    for company, teams in groups.items():
        scores = [s for ss in teams.values() for s in ss]
        out.append({"company": company, "n": len(scores), "mean": round(statistics.mean(scores), 1),
                    "teams": [{"team": t, "n": len(s), "mean": round(statistics.mean(s), 1)}
                              for t, s in sorted(teams.items(), key=lambda kv: -statistics.mean(kv[1]))]})
    return sorted(out, key=lambda c: -c["mean"])


def main():
    cache = json.loads(ATTR_CACHE.read_text(encoding="utf-8")) if ATTR_CACHE.exists() else {}
    tracks = {}
    for path in sorted((DATA / "runs").glob("*/result.json")):
        res = json.loads(path.read_text(encoding="utf-8"))
        if "oracle" not in res or "agent" not in res:
            continue  # exam-only or incomplete record
        if res["repo"] not in cache:
            cache[res["repo"]] = attribute.attribute(res["repo"])
        a = cache[res["repo"]]
        score, why = repo_score(res)
        diff = res.get("repo_diff") or {}
        tracks.setdefault(res.get("track", "gpu-rtx5060"), []).append({
            "repo": res["repo"], "slug": res["slug"], "score": score, "why": why,
            "agent_minutes": round(res["agent"]["secs"] / 60, 1),
            "files_patched": diff.get("files_changed"), "lines_patched": diff.get("lines_changed"),
            "replay": replay_class(res, "replay"),
            "replay_supplementary": replay_class(res, "replay_supplementary"),
            "replay_after_repair": replay_class(res, "replay_after_repair"),
            "company": a["company"], "team": a["team"], "attribution_confidence": a["confidence"],
            "attribution_evidence": a["evidence"],
            "audit": (res.get("audit") or {}).get("verdict"),
            "audit_reason": (res.get("audit") or {}).get("reason"),
        })
    ATTR_CACHE.write_text(json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")

    order = sorted(tracks, key=lambda t: (t != "cpu-gha", t))
    out = {"tracks": []}
    md = ["# Reproducibility leaderboard", "",
          "How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent tries each "
          "repo; a hidden, pre-registered oracle decides success. Scores from different hardware are never "
          "mixed. Method: README.md; full notebook: WORKLOG.md.", ""]
    for t in order:
        rows = sorted(tracks[t], key=lambda r: (r["score"] is None, -(r["score"] or 0)))
        companies = company_table(rows)
        out["tracks"].append({"track": t, "label": TRACK_LABELS.get(t, t), "repos": rows, "companies": companies})
        md += [f"## {TRACK_LABELS.get(t, t)} — {len(rows)} repos", "",
               "| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |",
               "|---|---|---|---|---|---|---|"]
        for i, r in enumerate(rows, 1):
            later = [f"{k}: {r[k]}" for k in ("replay_supplementary", "replay_after_repair")
                     if r["replay"] != "pass" and r[k] != "not run"]
            md.append(f"| {i} | [{r['repo']}](https://github.com/{r['repo']}) | "
                      f"{'not scored (oracle defect)' if r['score'] is None else r['score']} | "
                      f"{r['agent_minutes']:.0f} min | {r['files_patched']} ({r['lines_patched']} lines) | "
                      f"{'; '.join([r['replay']] + later)} | {r['company']} / {r['team']} ({r['attribution_confidence']}) |")
        md += ["", "| company | n | mean | teams |", "|---|---|---|---|"]
        for c in companies:
            teams = "; ".join(f"{x['team']} {x['mean']} (n={x['n']})" for x in c["teams"])
            md.append(f"| {c['company']}{' ⚠ n<3' if c['n'] < 3 else ''} | {c['n']} | {c['mean']} | {teams} |")
        md.append("")
    (DATA / "leaderboard.json").write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")
    (ROOT / "LEADERBOARD.md").write_text("\n".join(md), encoding="utf-8", newline="\n")
    print("\n".join(md))


if __name__ == "__main__":
    main()
