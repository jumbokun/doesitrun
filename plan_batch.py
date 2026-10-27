"""Turn examiner verdicts (data/exams/*.json) into the run list for the CPU track (repos_cpu.json).

Only repos the examiner judged eligible AND for which it wrote oracles/<slug>.sh are included; the
first TARGET per company in star order, as pre-registered in data/candidates.json. Exclusions and
their reasons stay in data/exams for the record.
Usage: python plan_batch.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent


def main():
    cands = json.loads((ROOT / "data" / "candidates.json").read_text(encoding="utf-8"))["companies"]
    exams = {}
    for p in (ROOT / "data" / "exams").glob("*.json"):
        e = json.loads(p.read_text(encoding="utf-8"))
        exams[e["slug"]] = e
    plan, summary = [], {}
    for company, spec in cands.items():
        picked, excluded = [], []
        for c in spec["candidates"]:
            e = exams.get(c["slug"])
            if e is None:
                continue
            if e.get("eligible") and (ROOT / "oracles" / f"{c['slug']}.sh").exists() and len(picked) < spec["target"]:
                picked.append(c["slug"])
                plan.append({"slug": c["slug"], "repo": c["repo"], "dir": e["dir"], "company": company,
                             "gpu": False, "mem": "12g", "server": bool(e.get("server")),
                             "goal": e["goal"], "check": e["check"]})
            elif not e.get("eligible"):
                excluded.append(f"{c['repo']}: {e.get('reason')}")
        summary[company] = {"eligible": len(picked), "excluded": len(excluded)}
        print(f"{company}: {len(picked)} eligible, {len(excluded)} excluded")
        for x in excluded:
            print("   -", x)
    (ROOT / "repos_cpu.json").write_text(json.dumps(plan, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")
    print(json.dumps(summary))


if __name__ == "__main__":
    main()
