"""Attribute a GitHub repo to a company and team, with the evidence for it.

Confidence: high = owner is a known org account; medium = company named in LICENSE/CONTRIBUTING
(copyright holder or CLA); low = README mention only (may be a citation, so it never assigns a
company by itself, it can only name the team of an already-attributed company or flag academia).
Usage: python attribute.py owner/repo [...]
"""
import base64
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
RULES = json.loads((ROOT / "orgs.json").read_text(encoding="utf-8"))["companies"]
ACADEMIA = json.loads((ROOT / "orgs.json").read_text(encoding="utf-8"))["academia_markers"]


def gh_file(repo, path):
    p = subprocess.run(["gh", "api", f"repos/{repo}/{path}", "--jq", ".content"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if p.returncode or not p.stdout.strip():
        return ""
    return base64.b64decode(p.stdout.strip()).decode("utf-8", "replace")


def contains(text, phrase):
    return re.search(r"(?<![A-Za-z])" + re.escape(phrase) + r"(?![A-Za-z])", text) is not None


def paper_affiliations(readme):
    """Author institutions of the first arXiv paper linked in the README, via OpenAlex.
    Returns [(display_name, type, raw_strings)] in author order; [] if unknown."""
    m = re.search(r"arxiv\.org/(?:abs|pdf)/(\d{4}\.\d{4,5})", readme)
    if not m:
        return None, []
    p = subprocess.run(["curl", "-s", "-m", "20", f"https://api.openalex.org/works/doi:10.48550/arXiv.{m.group(1)}"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    try:
        work = json.loads(p.stdout)
    except ValueError:
        return m.group(1), []
    out = []
    for a in work.get("authorships", []):
        raws = a.get("raw_affiliation_strings") or []
        for inst in a.get("institutions", []):
            out.append((inst.get("display_name") or "", inst.get("type") or "", raws))
    return m.group(1), out


def attribute(repo):
    owner = repo.split("/")[0]
    license_text = gh_file(repo, "license") + "\n" + gh_file(repo, "contents/CONTRIBUTING.md")
    readme = gh_file(repo, "readme")[:20000]
    evidence = []
    company = team = None
    confidence = "none"

    for name, rule in RULES.items():
        for org, org_team in rule["owners"].items():
            if owner.lower() == org.lower():
                company, team, confidence = name, org_team, "high"
                evidence.append(f"owner '{owner}' is {name} org account ({org_team})")
    if company is None:
        for name, rule in RULES.items():
            hits = [ph for ph in rule["license"] if contains(license_text, ph)]
            if hits:
                company, team, confidence = name, name, "medium"
                evidence.append(f"LICENSE/CONTRIBUTING names {name}: {hits}")
                break
    if company is None:
        arxiv_id, insts = paper_affiliations(readme)
        for display, kind, raws in insts:  # author order: first author's institution wins
            text = display + " " + " ".join(raws)
            hit = next((n for n in RULES if contains(text, n)), None)
            if hit:
                company, confidence = hit, "medium"
                team = next((t for ph, t in RULES[hit]["readme"].items() if contains(text, ph)), hit)
                evidence.append(f"paper arXiv:{arxiv_id} author affiliation '{display}' (OpenAlex)")
                break
            if kind in ("education", "facility", "nonprofit", "government") and company is None:
                company, team, confidence = "Academia", display, "medium"
                evidence.append(f"paper arXiv:{arxiv_id} first institution '{display}' ({kind}, OpenAlex)")
                break
        if arxiv_id and not insts:
            evidence.append(f"paper arXiv:{arxiv_id} has no affiliation data in OpenAlex")
    if company not in (None, "Academia"):
        for phrase, readme_team in RULES[company]["readme"].items():
            if contains(readme, phrase) and team in (company, None):
                team = readme_team
                evidence.append(f"README mentions '{phrase}' -> team {readme_team} (low)")
                break
    if company is None:
        mentions = [n for n, r in RULES.items() if any(contains(readme, p) for p in list(r["readme"]) + r["license"])]
        acad = [m for m in ACADEMIA if contains(readme, m)]
        if acad:
            company, team, confidence = "Academia", acad[0], "low"
            evidence.append(f"README affiliation markers: {acad[:3]}")
        else:
            company, team = "Independent", owner
        if mentions:
            evidence.append(f"README also mentions {mentions} (not used: could be citation)")
    return {"repo": repo, "company": company, "team": team, "confidence": confidence, "evidence": evidence}


if __name__ == "__main__":
    for r in sys.argv[1:]:
        print(json.dumps(attribute(r), ensure_ascii=False))
