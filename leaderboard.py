"""Build the reproducibility leaderboard from committed run records (data/runs/<slug>/result.json).

Repo score (0-100, higher = easier to get running), objective inputs only:
    0                                   if the agent could not pass the hidden oracle
    100 - min(50, agent_minutes)        effort: 1 point per agent minute
        - min(40, 10 * files_patched)   repo code that had to change (git diff, whitespace ignored;
                                        files with no changed line, i.e. chmod or binary output, not counted)
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
MAINTAINED = "cpu-gha-maintained"
GPU_MAINTAINED = "gpu-rtx5060-maintained"
TRACK_LABELS = {"cpu-gha": "CPU · GitHub-hosted runner (4 vCPU, 16 GB)",
                "gpu-rtx5060": "GPU · RTX 5060 Laptop 8 GB"}


def team_of(a):
    """Split by team only on org-account evidence. A team inferred from a README mention is low confidence
    (unilm is MSR but its README does not say so; trax's does), so such repos stay under the company name."""
    if any("README mentions" in e for e in a.get("evidence", [])):
        return a["company"]
    return a["team"]


def replay_class(res, key):
    r = res.get(key)
    if not r:
        return "not run"
    return r.get("class") or ("pass" if r.get("oracle", {}).get("pass") else "fail: other")


def patched(diff, review=None):
    """Files whose content had to change. Mode-only (chmod +x) and binary entries show 0 changed lines
    in `git diff --numstat`; they are demo outputs overwriting tracked images/PDFs or an executable bit,
    not repo code being fixed, so they stay in the record but are not scored. A review may also waive a
    change shown not to be needed for the README demo (agent overreach); the reason is kept in the record."""
    waived = {w["path"] for w in (review or {}).get("patched_waived", [])}
    files = (diff or {}).get("files", [])
    return [f for f in files if f["added"] + f["removed"] > 0 and f["path"] not in waived] if files else []


def repo_score(res):
    if not res["oracle"]["pass"] and res["agent"].get("timed_out"):
        # The oracle never had a finished install to judge, so no audit can unscore this: not reproduced
        # within the 90-minute budget.
        return 0, "agent hit the time limit before the demo ran"
    if (res.get("review") or {}).get("rerun_pending"):
        return None, "not scored: the hidden test was revised after review and this run predates it"
    verdict = (res.get("correction") or res.get("audit") or {}).get("verdict")
    if not res["oracle"]["pass"] and verdict == "oracle_defect":
        return None, "not scored: the pre-registered audit found the hidden oracle defective"
    if not res["oracle"]["pass"]:
        return 0, "agent could not reproduce"
    minutes = res["agent"]["secs"] / 60
    files = len(patched(res.get("repo_diff"), res.get("review")))
    return round(100 - min(50, minutes) - min(40, 10 * files), 1), f"{minutes:.0f} min, {files} repo files patched"


TIER_RANK = {"as-written": 0, "readme-broken": 1, "not-judged": 2, "pending": 3}


def literal_of(slug):
    """README-as-written verdict (literal/RULES.md). A pass is a pass. A failure counts against the README only
    when its triage says so AND the triage's quoted error line is in the current run's logs (a rerun after a
    script or harness fix makes an old triage stale: then the repo is 'pending' until it is triaged again)."""
    d = DATA / "literal" / slug
    if not (d / "result.json").exists():
        return None
    res = json.loads((d / "result.json").read_text(encoding="utf-8"))
    if res.get("oracle", {}).get("pass"):
        return {"tier": "as-written"}
    tri = d / "triage.json"
    if tri.exists():
        t = json.loads(tri.read_text(encoding="utf-8"))
        logs = "".join((d / f).read_text(encoding="utf-8", errors="replace") for f in ("setup.log", "oracle.log")
                       if (d / f).exists())
        if t.get("error") and t["error"] in logs:
            tier = {"readme": "readme-broken", "test": "not-judged", "env": "not-judged"}.get(t["verdict"], "pending")
            return {"tier": tier, "verdict": t["verdict"], "step": t.get("step"), "why": t.get("why"), "short": t.get("short")}
    return {"tier": "pending"}


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
            "files_patched": len(patched(diff, res.get("review"))) if "files" in diff else diff.get("files_changed"), "lines_patched": diff.get("lines_changed"),
            "replay": replay_class(res, "replay"),
            "replay_supplementary": replay_class(res, "replay_supplementary"),
            "replay_after_repair": replay_class(res, "replay_after_repair"),
            "company": a["company"], "team": team_of(a), "attribution_confidence": a["confidence"],
            "attribution_evidence": a["evidence"],
            # A documented correction (dispute upheld with evidence) takes precedence over the audit verdict;
            # both stay in the record.
            "audit": (res.get("correction") or res.get("audit") or {}).get("verdict"),
            "audit_reason": (res.get("correction") or res.get("audit") or {}).get("reason"),
            "corrected": bool(res.get("correction")),
            # One verified sentence for readers on why a run did not pass (data/reviews); never the raw audit text.
            "public_reason": (res.get("review") or {}).get("public_reason"),
            "literal": literal_of(res["slug"]),
        })
    ATTR_CACHE.write_text(json.dumps(cache, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")

    order = sorted(tracks, key=lambda t: (t != "cpu-gha", t))
    labels = dict(TRACK_LABELS)
    active_path = DATA / "active.json"
    if "cpu-gha" in tracks and active_path.exists():
        # A view, not a new track: the CPU rows whose repo is in the pre-registered maintained set.
        active = json.loads(active_path.read_text(encoding="utf-8"))
        slugs = {a["slug"] for v in active["companies"].values() for a in v}
        tracks[MAINTAINED] = [r for r in tracks["cpu-gha"] if r["slug"] in slugs]
        labels[MAINTAINED] = f"CPU · maintained repos only (not archived, pushed since {active['pushed_since']})"
        order.insert(0, MAINTAINED)
    gpu_active = DATA / "active_gpu.json"
    if "gpu-rtx5060" in tracks and gpu_active.exists():
        g = json.loads(gpu_active.read_text(encoding="utf-8"))
        keep = {x["slug"] for x in g["repos"] if x["maintained"]}
        tracks[GPU_MAINTAINED] = [r for r in tracks["gpu-rtx5060"] if r["slug"] in keep]
        labels[GPU_MAINTAINED] = f"GPU · RTX 5060 Laptop 8 GB · maintained repos only (not archived, pushed since {g['pushed_since']})"
    # Publish only the maintained views: archived or quiet repos stay in data/runs as raw logs, off the board.
    order = [t for t in (MAINTAINED, GPU_MAINTAINED) if t in tracks]
    out = {"tracks": []}
    md = ["# Reproducibility leaderboard", "",
          "How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent tries each "
          "repo; a hidden, pre-registered oracle decides success. Scores from different hardware are never "
          "mixed. Method: README.md; full notebook: WORKLOG.md.", ""]
    for t in order:
        rows = sorted(tracks[t], key=lambda r: (TIER_RANK.get((r.get("literal") or {}).get("tier"), 9),
                                                r["score"] is None, -(r["score"] or 0)))
        companies = company_table(rows)
        out["tracks"].append({"track": t, "label": labels.get(t, t), "repos": rows, "companies": companies,
                              "view_of": "cpu-gha" if t == MAINTAINED else "gpu-rtx5060"})
        md += [f"## {labels.get(t, t)} — {len(rows)} repos", "",
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
