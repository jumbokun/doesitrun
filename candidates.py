"""Pre-registered candidate selection for a company-sampled batch.

Rule (fixed before any exam or run): per company, the top CANDIDATES_PER_COMPANY Python repos by stars
across its official GitHub org accounts, forks excluded. The examiner then screens them in star order
and the first TARGET_PER_COMPANY judged eligible are probed; every exclusion is recorded with a reason.
Usage: python candidates.py  -> data/candidates.json
       python candidates.py --add Company [Company ...] --target N
         -> appends companies from LATER_COMPANY_ORGS without touching companies already registered
"""
import hashlib
import json
import pathlib
import re
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent
CANDIDATES_PER_COMPANY = 25
TARGET_PER_COMPANY = 10
COMPANY_ORGS = {
    "Google": ["google-research", "google-deepmind", "google"],
    "Meta": ["facebookresearch"],
    "Microsoft": ["microsoft"],
    "NVIDIA": ["NVlabs", "NVIDIA"],
    "Alibaba": ["QwenLM", "alibaba", "modelscope", "alibaba-damo-academy"],
    "Tencent": ["Tencent", "TencentARC", "Tencent-Hunyuan"],
    "ByteDance": ["bytedance", "ByteDance-Seed"],
    "Baidu": ["PaddlePaddle", "baidu"],
}
# Companies added after batch 3, same rule, registered one batch at a time with --add.
LATER_COMPANY_ORGS = {
    "OpenAI": ["openai"],
    "Amazon": ["amazon-science", "awslabs", "aws"],
    "Apple": ["apple", "ml-explore"],
}


def slugify(repo):
    s = re.sub(r"[^a-z0-9]+", "-", repo.lower()).strip("-")
    return s if len(s) <= 30 else s[:24].rstrip("-") + "-" + hashlib.sha1(repo.encode()).hexdigest()[:5]  # stable across runs


def top_repos(org, n):
    q = f"org:{org} language:Python fork:false"
    p = subprocess.run(["gh", "api", "-X", "GET", "search/repositories", "-f", f"q={q}", "-f", "sort=stars",
                        "-f", "order=desc", "-f", f"per_page={n}", "--jq",
                        "[.items[] | {repo: .full_name, stars: .stargazers_count, archived: .archived, "
                        "pushed: .pushed_at, description: .description}]"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if p.returncode:
        raise RuntimeError(p.stderr)
    return json.loads(p.stdout)


def company_entry(company, orgs, target):
    pool = [r for org in orgs for r in top_repos(org, CANDIDATES_PER_COMPANY)]
    pool.sort(key=lambda r: -r["stars"])
    picked = pool[:CANDIDATES_PER_COMPANY]
    for r in picked:
        r["slug"] = slugify(r["repo"])
    print(company, len(picked), [r["repo"] for r in picked[:5]], "...")
    return {"orgs": orgs, "target": target, "candidates": picked}


def main():
    path = ROOT / "data" / "candidates.json"
    args = sys.argv[1:]
    if args[:1] == ["--add"]:
        # Append new companies only: re-querying registered ones would change their pre-registered lists.
        target = TARGET_PER_COMPANY
        if "--target" in args:
            i = args.index("--target")
            target = int(args[i + 1])
            args = args[:i] + args[i + 2:]
        out = json.loads(path.read_text(encoding="utf-8"))
        for company in args[1:]:
            if company in out["companies"]:
                raise SystemExit(f"{company} is already registered; refusing to re-query it")
            out["companies"][company] = {**company_entry(company, LATER_COMPANY_ORGS[company], target),
                                         "registered": time.strftime("%Y-%m-%d")}
    else:
        out = {"rule": __doc__.strip().splitlines()[2:5], "companies": {}}
        for company, orgs in COMPANY_ORGS.items():
            out["companies"][company] = company_entry(company, orgs, TARGET_PER_COMPANY)
    path.parent.mkdir(exist_ok=True)
    path.write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
