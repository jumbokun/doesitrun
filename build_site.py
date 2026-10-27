"""Render data/leaderboard.json into a static page at _site/index.html (GitHub Pages).

Pure stdlib, reads only committed data: CI needs no Docker, GPU, network or secrets.
Design follows the web3work DESIGN.md tokens (dark-native, mono numbers, semantic colors only).
"""
import datetime
import html
import json
import os
import pathlib
import statistics

ROOT = pathlib.Path(__file__).resolve().parent
OUT = ROOT / "_site"
REPO_URL = "https://github.com/jumbokun/doesitrun"


def esc(s):
    return html.escape(str(s), quote=True)


def tone(score):
    return "pos" if score >= 75 else "warn" if score >= 50 else "neg"


def replay_badge(r):
    first = r["replay"]
    if first == "pass":
        return '<span class="badge pos">replays</span>'
    repaired, retry = r.get("replay_after_repair", "not run"), r.get("replay_supplementary", "not run")
    detail = "; ".join([first] + [f"{k}: {v}" for k, v in (("retry", retry), ("after repair", repaired)) if v != "not run"])
    label = ("replays after repair" if repaired == "pass" else "replays on retry" if retry == "pass" else "replay failed")
    good = "pass" in (repaired, retry)
    return f'<span class="badge {"warn" if good else "neg"}" title="{esc(detail)}">{esc(label)}</span>'


def score_cell(r):
    if r["score"] is None:
        return (f'<div class="score"><span class="badge warn" title="{esc(r.get("audit_reason") or "")}">'
                f'oracle defect · not scored</span></div>')
    return f"""<div class="score {tone(r['score'])}">
          <span class="mono num">{r['score']:.0f}</span>
          <span class="bar"><span style="width:{max(2, r['score']):.0f}%"></span></span>
        </div>"""


def repo_rows(rows):
    out = []
    for i, r in enumerate(rows, 1):
        owner, name = r["repo"].split("/", 1)
        conf = r["attribution_confidence"]
        redundant = r["team"] in (r["company"], None, owner)
        org = esc(r["company"]) + ("" if redundant else f" · {esc(r['team'])}")
        tag = "" if conf == "none" else (f'<span class="conf conf-{esc(conf)}" title="'
                                         f'{esc("; ".join(r["attribution_evidence"]))}">{esc(conf)}</span>')
        out.append(f"""
      <li class="row">
        <span class="rank mono">{i}</span>
        <div class="who">
          <a class="repo" href="https://github.com/{esc(r['repo'])}" rel="noopener">
            <span class="owner">{esc(owner)}/</span>{esc(name)}</a>
          <div class="meta">{org}{tag}</div>
          <div class="facts">
            <span class="mono">{r['agent_minutes']:.0f} min</span>
            <span class="mono">{r['files_patched']} files patched</span>
            {replay_badge(r)}
          </div>
        </div>
        {score_cell(r)}
      </li>""")
    return "".join(out)


def company_rows(companies, excl=None):
    out = []
    for c in companies:
        warn = '<span class="badge warn">n&lt;3 · not a verdict</span>' if c["n"] < 3 else ""
        x = (excl or {}).get(c["company"])
        if x and x["excluded"]:
            warn += (f'<span class="n" title="Candidates the examiner ruled out before any run: paid API keys, '
                     f'gated models, too large for CPU, GPU-only.">{x["excluded"]} excluded</span>')
        teams = "".join(f'<li><span>{esc(t["team"])}</span><span class="mono">{t["mean"]:.0f}'
                        f'<span class="n"> n={t["n"]}</span></span></li>' for t in c["teams"])
        out.append(f"""
      <li class="company">
        <div class="chead">
          <span class="cname">{esc(c['company'])}</span>{warn}
          <span class="mono cscore {tone(c['mean'])}">{c['mean']:.0f}<span class="n"> n={c['n']}</span></span>
        </div>
        <ul class="teams">{teams}</ul>
      </li>""")
    return "".join(out)


TRACK_NOTES = {
    "cpu-gha": ("No GPU on this track. Repos built around CUDA (much of NVIDIA's catalogue, older research code) "
                "are judged on their CPU path, which their authors often never prioritised - read their scores "
                "with that in mind. Which repos were eligible was decided by an examiner agent before any run; "
                "every exclusion and its reason is in data/exams."),
    "gpu-rtx5060": ("Local RTX 5060 (Blackwell). Old PyTorch pins have no kernels for it, so 2020-23 repos needed "
                    "a newer stack; that is part of what the score measures."),
}


def exclusions_by_company():
    """Count examiner exclusions per company (API keys, gated models, too big, GPU-only, ...)."""
    out = {}
    for path in (ROOT / "data" / "exams").glob("*.json"):
        e = json.loads(path.read_text(encoding="utf-8"))
        c = out.setdefault(e.get("company", "?"), {"excluded": 0, "eligible": 0})
        c["eligible" if e.get("eligible") else "excluded"] += 1
    return out


def track_section(t, i):
    multi = "Most companies have a single repo here. Treat these rows as a preview of the format, not a ranking."
    few = any(c["n"] < 3 for c in t["companies"])
    note = TRACK_NOTES.get(t["track"], "")
    excl = exclusions_by_company() if t["track"] == "cpu-gha" else {}
    return f"""
<section id="track-{i}">
  <div class="overline">{esc(t['label'])}</div>
  <h2>Repos · {len(t['repos'])}</h2>
  <div class="sub">Score 0–100, higher = easier to get running. One run per repo.</div>
  {f'<div class="caveat" style="margin:0 0 12px">{esc(note)}</div>' if note else ''}
  <ol class="board">{repo_rows(t['repos'])}
  </ol>
</section>
<section id="companies-{i}">
  <div class="overline">{esc(t['label'])}</div>
  <h2>Companies &amp; teams</h2>
  <div class="sub">Mean repo score per company, split by team where attribution allows.</div>
  <ul class="board">{company_rows(t['companies'], excl)}
  </ul>
  {f'<div class="caveat">{multi}</div>' if few else ''}
</section>
"""


def main():
    data = json.loads((ROOT / "data" / "leaderboard.json").read_text(encoding="utf-8"))
    tracks = data["tracks"]
    rows = [r for t in tracks for r in t["repos"]]
    ran = [r for r in rows if (r["score"] or 0) > 0]
    sections = "".join(track_section(t, i) for i, t in enumerate(tracks))
    replays = sum(r["replay"] == "pass" for r in rows)
    median_min = statistics.median(r["agent_minutes"] for r in rows) if rows else 0
    sha = os.environ.get("GITHUB_SHA", "local")[:7]
    built = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Does it run? — GitHub repo reproducibility leaderboard</title>
<meta name="description" content="A sandboxed AI agent tries to run each repo's README demo; a hidden test decides. Which repos run, and which fight back?">
<meta property="og:title" content="Does it run?">
<meta property="og:description" content="{len(rows)} GitHub repos, one sandboxed agent, a hidden test. Who is easiest to reproduce?">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230a0b0d'/%3E%3Cpath d='M9 17l5 5 9-12' stroke='%2300d4aa' stroke-width='3.5' fill='none' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root {{
  --bg-base:#0a0b0d; --bg-panel:#111214; --bg-surface:#1a1b1f; --bg-surface-hover:#222329; --bg-inset:#0e0f11;
  --text-primary:#f0f1f3; --text-secondary:#a0a4ab; --text-tertiary:#5c5f66;
  --pos:#00d4aa; --pos-bg:rgba(0,212,170,.08); --neg:#ff4757; --neg-bg:rgba(255,71,87,.08);
  --warn:#ffb347; --warn-bg:rgba(255,179,71,.08); --accent:#5b7fff; --accent-bg:rgba(91,127,255,.08);
  --border-subtle:rgba(255,255,255,.04); --border:rgba(255,255,255,.06); --border-strong:rgba(255,255,255,.10);
  --mono:"JetBrains Mono","SF Mono",Consolas,monospace; --sans:Inter,-apple-system,system-ui,sans-serif;
}}
* {{ box-sizing:border-box; margin:0; padding:0; }}
html {{ scroll-behavior:smooth; scroll-padding-top:16px; }}
body {{ background:var(--bg-base); color:var(--text-secondary); font:400 14px/1.55 var(--sans);
  padding:24px 16px calc(80px + env(safe-area-inset-bottom)); -webkit-font-smoothing:antialiased; }}
a {{ color:var(--accent); text-decoration:none; }}
.wrap {{ max-width:880px; margin:0 auto; }}
.mono {{ font-family:var(--mono); font-variant-numeric:tabular-nums; }}
.overline {{ font:500 11px/1 var(--sans); letter-spacing:.5px; text-transform:uppercase; color:var(--text-tertiary); }}
header h1 {{ font:600 28px/1.15 var(--sans); letter-spacing:-.6px; color:var(--text-primary); margin:10px 0 8px; }}
header p {{ max-width:620px; }}
.stats {{ display:grid; grid-template-columns:repeat(2,1fr); gap:1px; margin:24px 0 8px;
  background:var(--border); border:1px solid var(--border); border-radius:12px; overflow:hidden; }}
.stat {{ background:var(--bg-panel); padding:14px 16px; }}
.stat .v {{ font:600 20px/1.2 var(--mono); letter-spacing:-.5px; color:var(--text-primary); font-variant-numeric:tabular-nums; }}
.stat .l {{ font-size:12px; letter-spacing:.2px; color:var(--text-tertiary); margin-top:2px; }}
section {{ margin-top:40px; }}
section > h2 {{ font:600 18px/1.3 var(--sans); letter-spacing:-.3px; color:var(--text-primary); margin-bottom:4px; }}
section > .sub {{ font-size:12px; color:var(--text-tertiary); margin-bottom:12px; }}
ol, ul {{ list-style:none; }}
.board {{ border:1px solid var(--border); border-radius:12px; overflow:hidden; background:var(--bg-surface); }}
.row {{ display:grid; grid-template-columns:28px 1fr 64px; gap:12px; align-items:start; padding:14px 16px;
  border-top:1px solid var(--border-subtle); }}
.row:first-child {{ border-top:0; }}
.rank {{ color:var(--text-tertiary); font-size:13px; padding-top:2px; }}
.repo {{ color:var(--text-primary); font:500 15px/1.3 var(--sans); letter-spacing:-.2px; word-break:break-word; }}
.repo .owner {{ color:var(--text-tertiary); font-weight:400; }}
.repo:hover {{ color:var(--accent); }}
.meta {{ font-size:12px; color:var(--text-secondary); margin-top:3px; display:flex; gap:6px; align-items:center; flex-wrap:wrap; }}
.conf {{ font:500 10px/1 var(--sans); letter-spacing:.4px; text-transform:uppercase; padding:3px 5px; border-radius:4px;
  color:var(--text-tertiary); border:1px solid var(--border-strong); cursor:help; }}
.conf-high {{ color:var(--text-secondary); }}
.facts {{ display:flex; gap:10px; flex-wrap:wrap; align-items:center; margin-top:8px; font-size:12px; color:var(--text-tertiary); }}
.badge {{ font:600 10px/1 var(--sans); letter-spacing:.4px; text-transform:uppercase; padding:4px 7px; border-radius:4px; }}
.badge.pos {{ color:var(--pos); background:var(--pos-bg); border:1px solid rgba(0,212,170,.2); }}
.badge.warn {{ color:var(--warn); background:var(--warn-bg); border:1px solid rgba(255,179,71,.2); }}
.badge.neg {{ color:var(--neg); background:var(--neg-bg); border:1px solid rgba(255,71,87,.2); }}
.score {{ text-align:right; }}
.score .num {{ display:block; font-size:20px; font-weight:600; letter-spacing:-.5px; line-height:1.1; }}
.score .bar {{ display:block; height:3px; background:var(--bg-inset); border-radius:2px; margin-top:8px; overflow:hidden; }}
.score .bar span {{ display:block; height:100%; border-radius:2px; }}
.pos {{ color:var(--pos); }} .score.pos .bar span {{ background:var(--pos); }}
.warn {{ color:var(--warn); }} .score.warn .bar span {{ background:var(--warn); }}
.neg {{ color:var(--neg); }} .score.neg .bar span {{ background:var(--neg); }}
.company {{ padding:14px 16px; border-top:1px solid var(--border-subtle); }}
.company:first-child {{ border-top:0; }}
.chead {{ display:flex; align-items:center; gap:8px; flex-wrap:wrap; }}
.cname {{ color:var(--text-primary); font:500 15px/1.3 var(--sans); }}
.cscore {{ margin-left:auto; font-size:15px; font-weight:500; }}
.n {{ color:var(--text-tertiary); font-size:11px; font-weight:400; }}
.teams {{ margin-top:6px; }}
.teams li {{ display:flex; justify-content:space-between; gap:12px; font-size:12px; padding:3px 0 3px 12px;
  border-left:1px solid var(--border-strong); color:var(--text-secondary); }}
.method {{ background:var(--bg-surface); border:1px solid var(--border); border-radius:12px; padding:16px; }}
.method h3 {{ font:500 15px/1.3 var(--sans); color:var(--text-primary); margin:16px 0 6px; }}
.method h3:first-child {{ margin-top:0; }}
.method li {{ padding-left:14px; position:relative; margin:4px 0; }}
.method li::before {{ content:""; position:absolute; left:2px; top:10px; width:4px; height:4px; border-radius:50%; background:var(--text-tertiary); }}
code {{ font-family:var(--mono); font-size:12px; background:var(--bg-inset); border:1px solid var(--border); border-radius:4px; padding:1px 5px; color:var(--text-primary); }}
.caveat {{ border-left:3px solid var(--warn); background:var(--warn-bg); padding:10px 12px; border-radius:0 8px 8px 0; margin-top:12px; color:var(--text-secondary); }}
footer {{ margin-top:48px; font-size:12px; color:var(--text-tertiary); display:flex; gap:12px; flex-wrap:wrap; }}
nav.tabs {{ position:fixed; left:0; right:0; bottom:0; height:calc(56px + env(safe-area-inset-bottom));
  padding-bottom:env(safe-area-inset-bottom); display:flex; background:rgba(17,18,20,.85);
  backdrop-filter:blur(12px); -webkit-backdrop-filter:blur(12px); border-top:1px solid var(--border); z-index:10; }}
nav.tabs a {{ flex:1; display:flex; align-items:center; justify-content:center; min-height:44px;
  font:500 13px/1 var(--sans); color:var(--text-tertiary); }}
nav.tabs a:hover, nav.tabs a:focus-visible {{ color:var(--accent); outline:none; }}
@media (min-width:768px) {{
  html {{ scroll-padding-top:72px; }}
  body {{ padding:0 24px 64px; }}
  nav.tabs {{ position:sticky; top:0; bottom:auto; height:56px; justify-content:flex-end; gap:4px;
    margin:0 -24px 32px; padding:0 max(24px, calc((100vw - 880px) / 2)); border-top:0; border-bottom:1px solid var(--border); }}
  nav.tabs .brand {{ margin-right:auto; color:var(--text-primary); font-weight:600; flex:none; }}
  nav.tabs a {{ flex:none; padding:0 14px; }}
  header {{ padding-top:24px; }}
  header h1 {{ font-size:40px; letter-spacing:-1px; }}
  .stats {{ grid-template-columns:repeat(4,1fr); }}
  .row {{ grid-template-columns:36px 1fr 96px; padding:16px 20px; }}
}}
@media (max-width:767px) {{ nav.tabs .brand {{ display:none; }} }}
</style>
</head>
<body>
<nav class="tabs" aria-label="Sections">
  <a class="brand" href="#top">Does it run?</a>
  <a href="#track-0">Leaderboard</a><a href="#companies-0">Companies</a><a href="#method">Method</a>
</nav>
<div class="wrap">
<header id="top">
  <div class="overline">GitHub reproducibility leaderboard</div>
  <h1>Does it run?</h1>
  <p>A sandboxed AI agent gets one tool, a fresh Linux box with an 8&nbsp;GB GPU, and a repo's README.
  A hidden, pre-registered test decides whether the demo really works. Then we replay the agent's
  installer on a brand-new machine.</p>
  <div class="stats">
    <div class="stat"><div class="v">{len(rows)}</div><div class="l">repos tested</div></div>
    <div class="stat"><div class="v">{len(ran)}/{len(rows)}</div><div class="l">got running</div></div>
    <div class="stat"><div class="v">{median_min:.0f} min</div><div class="l">median agent time</div></div>
    <div class="stat"><div class="v">{replays}/{len(rows)}</div><div class="l">installer replays first try</div></div>
  </div>
</header>

{sections}
<section id="method">
  <h2>Method</h2>
  <div class="method">
    <h3>The run</h3>
    <ul>
      <li>Agent: Claude Code with a single tool, <code>docker exec</code> into a throwaway container
        (Ubuntu 24.04, CUDA 12.8, RTX 5060 8&nbsp;GB). No host access; private networks firewalled off.</li>
      <li>Goal: the repo's own README demo. Success is decided by a hidden script written before the run
        and copied in only after the agent stops.</li>
      <li>Replay: the agent's <code>setup.sh</code> is run on a fresh container to see if the install is shareable.</li>
    </ul>
    <h3>The score</h3>
    <ul>
      <li><code>100 − min(50, agent minutes) − min(40, 10 × repo files patched)</code>; 0 if it never ran.</li>
      <li>Files patched is measured with <code>git diff</code> on the repo (whitespace ignored), not taken from the agent's notes.</li>
      <li>Replay is shown but not scored: it grades our installer, not the repo's authors.</li>
    </ul>
    <h3>Who made it</h3>
    <ul>
      <li>Company and team come from, in order: the owning GitHub org (high), LICENSE copyright or CLA (medium),
        the linked paper's author affiliations via OpenAlex (medium), README mentions (low). Hover the tag for evidence.</li>
    </ul>
    <div class="caveat">Small sample, one run each, one GPU generation (Blackwell needs recent PyTorch, which
      penalises old pins). Agent time also moves with download speed. Scores are a signal, not a verdict.</div>
  </div>
</section>

<footer>
  <span>Built {built} from <a href="{REPO_URL}/commit/{esc(sha)}">{esc(sha)}</a></span>
  <a href="{REPO_URL}">Source &amp; raw data</a>
</footer>
</div>
</body>
</html>
"""
    OUT.mkdir(exist_ok=True)
    (OUT / "index.html").write_text(page, encoding="utf-8", newline="\n")
    (OUT / "leaderboard.json").write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")
    print(f"wrote {OUT / 'index.html'} ({len(rows)} repos)")


if __name__ == "__main__":
    main()
