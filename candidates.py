"""Pre-registered candidate selection for a company-sampled batch.

Rule (fixed before any exam or run): per company, the top CANDIDATES_PER_COMPANY Python repos by stars
across its official GitHub org accounts, forks excluded. The examiner then screens them in star order
and the first TARGET_PER_COMPANY judged eligible are probed; every exclusion is recorded with a reason.
Usage: python candidates.py  -> data/candidates.json
"""
import hashlib
import json
import pathlib
import re
import subprocess

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


def main():
    out = {"rule": __doc__.strip().splitlines()[2:5], "companies": {}}
    for company, orgs in COMPANY_ORGS.items():
        pool = [r for org in orgs for r in top_repos(org, CANDIDATES_PER_COMPANY)]
        pool.sort(key=lambda r: -r["stars"])
        picked = pool[:CANDIDATES_PER_COMPANY]
        for r in picked:
            r["slug"] = slugify(r["repo"])
        out["companies"][company] = {"orgs": orgs, "target": TARGET_PER_COMPANY, "candidates": picked}
        print(company, len(picked), [r["repo"] for r in picked[:5]], "...")
    (ROOT / "data").mkdir(exist_ok=True)
    (ROOT / "data" / "candidates.json").write_text(json.dumps(out, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
