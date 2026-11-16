"""Render data/leaderboard.json into a static site at _site/ (GitHub Pages).

index.html  - the leaderboard: one track at a time (tabs), repos or companies, filters. Little prose.
method.html - how a run works, scoring, attribution, every repo not tested and why, caveats.
badge/...   - shields.io endpoint JSON per repo.

Pure stdlib, reads only committed data: CI needs no Docker, GPU, network or secrets.
Look copied from Terminal-Bench's leaderboard (the owner asked for peers, not invention): one monospace
face, black on white (dark if the system asks), square hairline boxes, one-line rows with an inline black
bar. Colour only for meaning: red for did-not-run, amber for replayed-after-a-retry.
"""
import datetime
import html
import json
import os
import pathlib
import re
import statistics

ROOT = pathlib.Path(__file__).resolve().parent
OUT = ROOT / "_site"
REPO_URL = "https://github.com/jumbokun/doesitrun"

TRACK_TABS = {  # short tab name, one-line note under the tabs
    "cpu-gha-maintained": ("CPU", "Only repos not archived and pushed to since {pushed_since}. CPU-only GitHub runner, 4 vCPU; the container gets 12 GB of its 16 GB RAM."),
    "gpu-rtx5060-maintained": ("GPU", "Only repos not archived and pushed to since {pushed_since}. One RTX 5060 laptop GPU (8 GB)."),
}


def esc(s):
    return html.escape(str(s), quote=True)


def tone(score):
    return "pos" if score >= 75 else "warn" if score >= 50 else "neg"


def load_json(p):
    return json.loads(p.read_text(encoding="utf-8"))


def patched_paths(slug):
    """Repo files whose content the agent changed (same rule as leaderboard.patched)."""
    p = ROOT / "data" / "runs" / slug / "result.json"
    if not p.exists():
        return []
    files = (load_json(p).get("repo_diff") or {}).get("files", [])
    waived = {w["path"] for w in (load_json(p).get("review") or {}).get("patched_waived", [])}
    return [f["path"] for f in files if f["added"] + f["removed"] > 0 and f["path"] not in waived]


def mins(m):
    return f"{m:.1f}" if m < 10 else f"{m:.0f}"


def status(r):
    """One of: ran, ran-patched, failed, unscored."""
    if r["score"] is None:
        return "unscored"
    if r["score"] == 0:
        return "failed"
    return "ran-patched" if r["files_patched"] else "ran"


CHECK = '<svg class="ic" viewBox="0 0 16 16" aria-hidden="true"><path d="M3.5 8.5l3 3 6-7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>'
CROSS = '<svg class="ic" viewBox="0 0 16 16" aria-hidden="true"><path d="M4.5 4.5l7 7M11.5 4.5l-7 7" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>'


def replay_cell(r):
    first = r["replay"]
    if r["score"] in (None, 0):
        return '<span class="dim">–</span>'
    if first == "pass":
        return '<span class="ok" title="The install script worked again on a fresh machine, first try">'+CHECK+'<span class="sr">yes</span></span>'
    repaired, retry = r.get("replay_after_repair", "not run"), r.get("replay_supplementary", "not run")
    if "pass" in (repaired, retry):
        return f'<span class="warn" title="{esc(first)}; worked after {"a repair round" if repaired == "pass" else "a retry"}">'+CHECK+'<span class="sr">after a retry</span></span>'
    return f'<span class="neg" title="{esc(first)}">'+CROSS+'<span class="sr">no</span></span>'


def score_cell(r):
    if r["score"] is None:
        return ('<td class="score"><span class="dim" title="The hidden test itself was found defective, so this run '
                f'is not scored. {esc(r.get("audit_reason") or "")}">n/a</span></td>')
    s = r["score"]
    return (f'<td class="score {tone(s)}"><b>{s:.1f}</b>'
            f'<span class="bar" aria-hidden="true"><i style="width:{max(2, s):.0f}%"></i></span></td>')


TIERS = {  # README-as-written tiers (literal/RULES.md), in board order
    "as-written": ("Works as written", "README works as written", "A fresh machine, the README's own commands copied line by line, no AI: the demo ran."),
    "readme-broken": ("README broken", "README broken: ran only after the AI fixed it", "Following the README exactly fails at the step shown; the agent got it running anyway."),
    "not-judged": ("Not judged", "Not judged as written", "The hidden test needs more than the README's demo shows, or the demo needs a GPU or more time than a CPU runner has."),
    "pending": ("Pending", "Being reviewed", "Ran as written and failed; the failure is still being checked."),
}


def tier_of(r):
    return (r.get("literal") or {}).get("tier")


def readme_cell(r):
    t = tier_of(r)
    if not t:
        return '<td class="num d-only"><span class="dim">–</span></td>'
    lab, _, _ = TIERS[t]
    why = (r.get("literal") or {}).get("why") or ""
    if t != "as-written":
        lab = (r.get("literal") or {}).get("short") or lab
    cls = {"as-written": "ok", "readme-broken": "neg", "not-judged": "dim", "pending": "dim"}[t]
    mark = CHECK if t == "as-written" else CROSS if t == "readme-broken" else "–"
    if t == "as-written":
        lab = "yes"
    return (f'<td class="rd d-only"><span class="{cls}" title="{esc(why)}">{mark} {esc(lab)}</span></td>')


def repo_table(t):
    rows = []
    lit = any(tier_of(r) for r in t["repos"])
    all_replay = all(r["replay"] == "pass" for r in t["repos"] if (r["score"] or 0) > 0)  # then the stats line says it
    counts = {}
    for r in t["repos"]:
        counts[tier_of(r)] = counts.get(tier_of(r), 0) + 1
    prev, i = object(), 0
    for r in t["repos"]:
        if lit and tier_of(r) != prev:
            prev, i = tier_of(r), 0
            if prev in TIERS:
                _, head, desc = TIERS[prev]
                rows.append(f'<tr class="grp"><td colspan="9"><b>{esc(head)}</b> <span class="mono">{counts[prev]}</span>'
                            f'<span class="gdesc">{esc(desc)}</span></td></tr>')
        i += 1
        owner, name = r["repo"].split("/", 1)
        st = status(r)
        files = patched_paths(r["slug"]) if r["files_patched"] else []
        changed = (f'<span class="chg" title="{esc(", ".join(files))}">{r["files_patched"]}</span>'
                   if r["files_patched"] else '<span class="dim">0</span>')
        note = ""
        if st in ("failed", "unscored"):
            note = (f'<div class="note neg">{esc(r["public_reason"])}</div>' if r.get("public_reason")
                    else '<div class="note">Did not pass; see the run log.</div>' if st == "failed" else "")
        lit_m = f' · {esc(TIERS[tier_of(r)][0])}' if tier_of(r) in TIERS else ""
        team = "" if r["team"] in (r["company"], None, owner) else f' · {esc(r["team"])}'
        rows.append(f"""
<tr data-st="{st}" data-tier="{esc(tier_of(r) or '')}" data-q="{esc((r['repo'] + ' ' + r['company'] + ' ' + (r['team'] or '')).lower())}">
  <td class="rank">{i}</td>
  <td class="repo"><a href="https://github.com/{esc(r['repo'])}" rel="noopener"><span class="owner">{esc(owner)}/</span><wbr><span class="nm">{esc(name)}</span></a>
    <div class="sub m-only">{esc(r['company'])}{team} · {mins(r['agent_minutes'])} min{lit_m}</div>{note}</td>
  <td class="co d-only"{f' title="{esc(r["team"])}"' if team else ''}>{esc(r['company'])}</td>
  {readme_cell(r) if lit else ''}
  {score_cell(r)}
  <td class="num d-only">{mins(r['agent_minutes'])}<span class="unit"> min</span></td>
  <td class="num d-only">{changed}</td>
  {'' if all_replay else f'<td class="num d-only">{replay_cell(r)}</td>'}
  <td class="num d-only"><a class="log" href="{REPO_URL}/tree/main/data/runs/{esc(r['slug'])}" rel="noopener" title="Run record: result, install script, agent notes">log</a></td>
</tr>""")
    return f"""
<table class="board">
  <thead><tr><th class="rank">#</th><th>Repo</th><th class="d-only">Company</th>{'<th class="d-only" title="Does the README work when followed exactly, with no AI?">README</th>' if lit else ''}<th class="score" title="100 − agent minutes (max 50) − 10 per repo file changed (max 40); 0 if it never ran">Score</th>
    <th class="num d-only">Time</th><th class="num d-only" title="Repo files whose content had to change">Files patched</th>
    {'' if all_replay else '<th class="num d-only" title="The install script works again on a fresh machine">Replays</th>'}<th class="num d-only">Log</th></tr></thead>
  <tbody>{''.join(rows)}</tbody>
</table>"""


def company_table(t):
    rows = []
    for i, c in enumerate(t["companies"], 1):
        repos = [r for r in t["repos"] if r["company"] == c["company"]]
        ran = sum(1 for r in repos if (r["score"] or 0) > 0)
        teams = " · ".join(f'{esc(x["team"])} <span class="mono">{x["mean"]:.0f}</span>' for x in c["teams"]) \
            if len(c["teams"]) > 1 else ""
        small = ' <span class="flag" title="Fewer than 3 repos: not a verdict on the company">few repos</span>' if c["n"] < 3 else ""
        lit = [r for r in repos if tier_of(r) in ("as-written", "readme-broken")]
        aw = sum(1 for r in lit if tier_of(r) == "as-written")
        aw_cell = (f'<td class="num">{aw}<span class="unit">/{len(lit)}</span></td>' if any(tier_of(r) for r in t["repos"]) else "")
        rows.append(f"""
<tr>
  <td class="rank">{i}</td>
  <td class="repo"><span class="cname">{esc(c['company'])}</span>{small}{f'<div class="sub">{teams}</div>' if teams else ''}</td>
  <td class="score {tone(c['mean'])}"><b>{c['mean']:.1f}</b><span class="bar" aria-hidden="true"><i style="width:{max(2, c['mean']):.0f}%"></i></span></td>
  <td class="num">{ran}<span class="unit">/{len(repos)}</span></td>
  {aw_cell}
</tr>""")
    return f"""
<table class="board">
  <thead><tr><th class="rank">#</th><th>Company</th><th class="score">Mean score</th><th class="num">Ran</th>{'<th class="num" title="Judged repos whose README works as written">README as written</th>' if any(tier_of(r) for r in t["repos"]) else ''}</tr></thead>
  <tbody>{''.join(rows)}</tbody>
</table>"""


def exams():
    return [load_json(p) for p in sorted((ROOT / "data" / "exams").glob("*.json"))]


def active_slugs():
    p = ROOT / "data" / "active.json"
    if not p.exists():
        return None, None
    a = load_json(p)
    return {x["slug"] for v in a["companies"].values() for x in v}, a.get("pushed_since")


def not_tested(track, all_exams):
    """Exams ruled out before any run, for the tracks that come from exams."""
    if track.startswith("gpu"):
        return []
    out = [e for e in all_exams if not e.get("eligible")]
    if track == "cpu-gha-maintained":
        act, _ = active_slugs()
        out = [e for e in out if e["slug"] in (act or set())]
    return out


def finding_lit(rows, ran):
    n = {k: sum(1 for r in rows if tier_of(r) == k) for k in TIERS}
    judged = n["as-written"] + n["readme-broken"]
    if not judged:
        return ""
    return (f'<p class="finding lead"><b class="mono">{n["as-written"]}/{judged}</b> READMEs work exactly as written, no AI'
            f'<span class="sep">·</span><b class="mono">{n["readme-broken"]}</b> break at a step the agent had to fix'
            + (f'<span class="sep">·</span><b class="mono">{n["not-judged"] + n["pending"]}</b> not judged' if n["not-judged"] + n["pending"] else "")
            + '</p>')


def track_panel(t, idx, all_exams, pushed_since):
    rows = t["repos"]
    ran = [r for r in rows if (r["score"] or 0) > 0]
    patched = sum(1 for r in ran if r["files_patched"])
    med = statistics.median(r["agent_minutes"] for r in rows) if rows else 0
    first = sum(1 for r in ran if r["replay"] == "pass")
    failed = sum(1 for r in rows if r["score"] == 0)
    unscored = sum(1 for r in rows if r["score"] is None)
    nt = not_tested(t["track"], all_exams)
    _, note = TRACK_TABS.get(t["track"], (t["track"], t["label"]))
    note = note.format(pushed_since=pushed_since or "")
    chips = [("all", f"All {len(rows)}")]
    tiers = {k: sum(1 for r in rows if tier_of(r) == k) for k in TIERS}
    chips += [(k, f"{TIERS[k][0]} {n}") for k, n in tiers.items() if n]
    chips += [("ran-patched", f"Code changed {patched}")] if patched else []
    if failed:
        chips.append(("failed", f"Did not run {failed}"))
    if unscored:
        chips.append(("unscored", f"Not scored {unscored}"))
    chip_html = "".join(f'<button type="button" class="chip{" on" if k == "all" else ""}" data-f="{k}">{esc(v)}</button>'
                        for k, v in chips)
    nt_line = (f'<p class="after">{len(nt)} more repos were not tested because their README says they need a GPU, a paid API '
               f'key, a cloud account or a gated model, or there is no runnable demo. '
               f'<a href="method.html#not-tested">See the list</a></p>') if nt else ""
    return f"""
<section class="track" id="t-{esc(t['track'])}" data-track="{esc(t['track'])}"{'' if idx == 0 else ' hidden'}>
  {finding_lit(rows, ran)}<p class="finding"><b class="mono">{len(ran)}/{len(rows)}</b> README demos ran{" with the agent's help" if tiers["as-written"] else ""}
    <span class="sep">·</span> median <b class="mono">{med:.0f} min</b>
    <span class="sep">·</span> <b class="mono">{patched}</b> needed changes to the repo's code
    <span class="sep">·</span> <b class="mono">{first}/{len(ran)}</b> installs replay on a fresh machine</p>
  <p class="tnote">{esc(note)}</p>
  <div class="view" data-view="repos">
    <div class="tools">
      <div class="chips" role="group" aria-label="Filter">{chip_html}</div>
      <input class="search" type="search" placeholder="Filter repos or companies" aria-label="Filter repos or companies">
    </div>
    {repo_table(t)}
    <p class="empty" hidden>No repos match.</p>
    {nt_line}
  </div>
  <div class="view" data-view="companies" hidden>
    {company_table(t)}
    <p class="after">Mean of the repo scores per company. Teams are split only where GitHub org accounts show them.</p>
  </div>
</section>"""


def write_badges(tracks):
    """shields.io endpoint JSON per repo and track: _site/badge/<track>/<owner>/<repo>.json.
    Embed: https://img.shields.io/endpoint?url=https://jumbokun.github.io/doesitrun/badge/<track>/<owner>/<repo>.json"""
    for t in tracks:
        short = "CPU" if t["track"].startswith("cpu") else "GPU"
        for r in t["repos"]:
            if r["score"] is None:
                msg, color = f"{short} · not scored", "lightgrey"
            elif r["score"] == 0:
                msg, color = f"{short} · did not run", "red"
            else:
                msg = f"{short} · {r['score']:.0f}/100"
                color = "brightgreen" if r["score"] >= 75 else "yellow" if r["score"] >= 50 else "orange"
            path = OUT / "badge" / (t.get("view_of") or t["track"]) / (r["repo"] + ".json")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(json.dumps({"schemaVersion": 1, "label": "does it run?", "message": msg, "color": color,
                                         "cacheSeconds": 86400}).encode("utf-8"))


EXCLUSION_KINDS = [  # first match wins; keyword buckets over the examiner's one-sentence reasons
    ("Paid API key or account", r"api key|api_key|credential|account|paid|serper|openai|gemini models"),
    ("Gated model", r"gated|license accept|access request|hf_token|request.*access|terms of use"),
    ("GPU, or too big for a 12 GB container / 15 GB download", r"\bgpu\b|cuda|vram|too large|\bparameters\b|\d+\s?gb\b|\d+(\.\d+)?b\b|docker"),
]


def exclusion_kind(reason):
    r = (reason or "").lower()
    return next((k for k, pat in EXCLUSION_KINDS if re.search(pat, r)), "No runnable demo / other")


CSS = """
:root { --bg:#fff; --ink:#0a0a0a; --ink-2:#525252; --ink-3:#8a8a8a; --line:#e5e5e5; --fill:#f4f4f4; --bar:#0a0a0a;
  --neg:#d92d20; --warn:#b54708; --mono:"JetBrains Mono",ui-monospace,"SF Mono",Consolas,monospace; color-scheme:light; }
@media (prefers-color-scheme:dark) { :root { --bg:#0a0a0a; --ink:#f2f2f2; --ink-2:#a3a3a3; --ink-3:#737373; --line:#262626;
  --fill:#171717; --bar:#f2f2f2; --neg:#ff6b5e; --warn:#f5a524; color-scheme:dark; } }
* { box-sizing:border-box; margin:0; padding:0; }
body { background:var(--bg); color:var(--ink); font:400 14px/1.5 var(--mono); font-variant-numeric:tabular-nums; -webkit-font-smoothing:antialiased; }
a { color:inherit; text-decoration:underline; text-decoration-color:var(--line); text-underline-offset:3px; }
a:hover { text-decoration-color:currentColor; }
:focus-visible { outline:2px solid var(--ink); outline-offset:2px; }
.wrap { max-width:1200px; margin:0 auto; padding:0 16px; }
header.top { border-bottom:1px solid var(--line); background:var(--fill); }
header.top .wrap { display:flex; align-items:center; gap:24px; height:56px; }
.brand { font-weight:600; letter-spacing:.02em; text-transform:uppercase; text-decoration:none; white-space:nowrap; }
.links { display:flex; gap:16px; margin-left:auto; }
.links a { color:var(--ink-2); text-transform:uppercase; text-decoration:none; font-size:13px; padding:12px 0; }
.links a:hover, .links a[aria-current] { color:var(--ink); }
.links .l-board { display:none; }
.hero { text-align:center; padding:48px 0 32px; }
h1 { font:400 40px/1.05 var(--mono); letter-spacing:-.04em; text-transform:uppercase; }
.lede { color:var(--ink-2); max-width:640px; margin:16px auto 0; font-size:15px; line-height:1.6; }
.cta { display:flex; flex-wrap:wrap; gap:8px; justify-content:center; margin-top:24px; }
.btn { display:inline-flex; align-items:center; min-height:44px; padding:0 16px; font-weight:500; text-decoration:none; border:1px solid var(--line); background:var(--fill); }
.btn.primary { background:var(--ink); color:var(--bg); border-color:var(--ink); }
.btn:hover { opacity:.85; }
.switch { display:flex; flex-wrap:wrap; gap:8px; justify-content:space-between; align-items:center; margin-top:8px; }
.tabs, .seg { display:flex; border:1px solid var(--line); }
.tabs button, .seg button { background:var(--bg); border:0; border-left:1px solid var(--line); color:var(--ink-2); font:500 13px/1 var(--mono);
  text-transform:uppercase; padding:0 14px; min-height:44px; cursor:pointer; white-space:nowrap; }
.tabs button:first-child, .seg button:first-child { border-left:0; }
.tabs button .n { color:var(--ink-3); margin-left:6px; }
.tabs button[aria-selected="true"], .seg button[aria-pressed="true"] { background:var(--fill); color:var(--ink); }
.finding { margin-top:20px; color:var(--ink-2); }
.finding b { color:var(--ink); font-weight:600; }
.finding .sep { color:var(--ink-3); margin:0 6px; }
.tnote { margin-top:4px; font-size:12px; color:var(--ink-3); }
.tools { display:flex; flex-wrap:wrap; gap:8px; align-items:center; margin:16px 0 12px; }
.chips { display:flex; border:1px solid var(--line); max-width:100%; overflow-x:auto; }
.chip { background:var(--bg); border:0; border-left:1px solid var(--line); color:var(--ink-2); font:500 13px/1 var(--mono); padding:0 12px; min-height:44px; cursor:pointer; white-space:nowrap; }
.chip:first-child { border-left:0; }
.chip.on { background:var(--fill); color:var(--ink); }
.search { flex:1 1 220px; min-width:0; background:var(--bg); border:1px solid var(--line); color:var(--ink); font:400 13px/1 var(--mono); padding:0 12px; min-height:44px; }
.search::placeholder { color:var(--ink-3); }
.search:focus { outline:none; border-color:var(--ink-3); }
table.board { width:100%; border-collapse:collapse; border:1px solid var(--line); }
.board th { text-align:left; font:500 12px/1 var(--mono); text-transform:uppercase; letter-spacing:.04em; color:var(--ink); padding:16px 12px; border-bottom:1px solid var(--line); white-space:nowrap; }
.board td { padding:12px; border-top:1px solid var(--line); vertical-align:middle; }
.board tbody tr:first-child td { border-top:0; }
.board tbody tr:hover td { background:var(--fill); }
.board .rank { width:40px; color:var(--ink-3); text-align:right; }
.board .num { text-align:right; white-space:nowrap; color:var(--ink-2); }
.board th.num, .board th.score { text-align:right; }
.unit { color:var(--ink-3); }
.repo a { text-decoration:none; overflow-wrap:anywhere; }
.repo a:hover { text-decoration:underline; }
.repo .owner { color:var(--ink-3); }
.co { color:var(--ink-2); white-space:nowrap; }
.cname { font-weight:500; }
.sub { font-size:12px; color:var(--ink-3); margin-top:2px; }
.sub .mono { color:var(--ink-2); }
.note { font-size:12px; color:var(--ink-2); margin-top:4px; max-width:560px; overflow-wrap:anywhere; }
.note.neg { color:var(--neg); }
.score { white-space:nowrap; text-align:right; width:1%; }
.score b { font-weight:600; display:inline-block; min-width:4ch; text-align:right; }
.score .bar { display:none; }
.score.neg b { color:var(--neg); }
.score.warn, .score.pos { color:var(--ink); }
.ic { width:16px; height:16px; vertical-align:-3px; }
.sr { position:absolute; width:1px; height:1px; overflow:hidden; clip:rect(0 0 0 0); }
.ok { color:var(--ink); } .warn { color:var(--warn); } .neg { color:var(--neg); } .dim { color:var(--ink-3); }
.chg { color:var(--ink); font-weight:600; cursor:help; text-decoration:underline dotted var(--ink-3); text-underline-offset:3px; }
tr.grp td { background:var(--fill); padding:14px 12px; border-top:1px solid var(--line); }
tr.grp b { font-weight:600; text-transform:uppercase; letter-spacing:.04em; font-size:12px; }
tr.grp .mono { color:var(--ink-3); margin-left:6px; font-size:12px; }
.gdesc { display:block; color:var(--ink-3); font-size:12px; margin-top:4px; }
.rd { font-size:12px; min-width:150px; max-width:200px; }
.finding.lead { font-size:16px; color:var(--ink); }
.flag { font-size:12px; color:var(--ink-3); margin-left:6px; text-transform:uppercase; }
.after { font-size:12px; color:var(--ink-3); margin-top:12px; }
.empty { padding:24px 0; color:var(--ink-3); }
.d-only { display:none; }
footer { margin:48px 0 0; padding:24px 0; border-top:1px solid var(--line); font-size:12px; color:var(--ink-3); display:flex; gap:16px; flex-wrap:wrap; }
.prose { max-width:760px; padding-top:32px; }
.prose h1 { font-size:32px; }
.prose .lede { margin-left:0; }
.prose h2 { font:600 15px/1.3 var(--mono); text-transform:uppercase; letter-spacing:.04em; margin:40px 0 8px; padding-top:16px; border-top:1px solid var(--line); }
.prose p, .prose li { margin:8px 0; color:var(--ink-2); }
.prose ul { padding-left:18px; }
.prose code { font-size:12px; background:var(--fill); border:1px solid var(--line); padding:1px 5px; color:var(--ink); }
@media (min-width:768px) {
  .wrap { padding:0 32px; }
  .links { gap:24px; }
  .links .l-board { display:inline; }
  .hero { padding:80px 0 48px; }
  h1 { font-size:88px; }
  .lede { font-size:17px; }
  .d-only { display:table-cell; }
  .m-only { display:none; }
  .board td { padding:0 16px; height:52px; }
  .board th { padding:18px 16px; }
  .note { padding-bottom:10px; }
  .board td.repo:has(.note) { padding-top:10px; }
  .repo .owner, .repo .nm { white-space:nowrap; }
  .board td.repo { min-width:220px; }

  .score .bar { display:inline-block; vertical-align:middle; width:72px; height:12px; background:var(--fill); margin-left:12px; }
  .score .bar i { display:block; height:100%; background:var(--bar); }
  .score.neg .bar i { background:var(--neg); }
}
@media (min-width:768px) and (max-width:1099px) { .score .bar { display:none; } }
@media (min-width:1100px) { .rd { min-width:210px; max-width:none; white-space:nowrap; } }
"""


JS = """
(function () {
  var tabs = document.querySelectorAll('.tabs [data-track]');
  var seg = document.querySelectorAll('.seg [data-v]');
  var view = 'repos';
  function show(track) {
    tabs.forEach(function (b) { b.setAttribute('aria-selected', b.dataset.track === track); });
    document.querySelectorAll('section.track').forEach(function (s) { s.hidden = s.dataset.track !== track; });
    if (history.replaceState) history.replaceState(null, '', '#' + track + (view === 'companies' ? '/companies' : ''));
  }
  function setView(v) {
    view = v;
    seg.forEach(function (b) { b.setAttribute('aria-pressed', b.dataset.v === v); });
    document.querySelectorAll('.view').forEach(function (el) { el.hidden = el.dataset.view !== v; });
    var cur = document.querySelector('.tabs [aria-selected="true"]');
    if (cur) show(cur.dataset.track);
  }
  tabs.forEach(function (b) { b.addEventListener('click', function () { show(b.dataset.track); }); });
  seg.forEach(function (b) { b.addEventListener('click', function () { setView(b.dataset.v); }); });
  document.querySelectorAll('section.track').forEach(function (sec) {
    var f = 'all', q = '';
    var rows = sec.querySelectorAll('[data-view="repos"] tbody tr:not(.grp)');
    var grps = sec.querySelectorAll('[data-view="repos"] tbody tr.grp');
    var empty = sec.querySelector('.empty');
    function apply() {
      var n = 0;
      rows.forEach(function (r) {
        var ok = (f === 'all' || r.dataset.st === f || r.dataset.tier === f) && (!q || r.dataset.q.indexOf(q) >= 0);
        r.hidden = !ok; if (ok) n++;
      });
      empty.hidden = n > 0;
      grps.forEach(function (g) { g.hidden = f !== 'all' || !!q; });
    }
    sec.querySelectorAll('.chip').forEach(function (c) {
      c.addEventListener('click', function () {
        f = c.dataset.f;
        sec.querySelectorAll('.chip').forEach(function (x) { x.classList.toggle('on', x === c); });
        apply();
      });
    });
    var s = sec.querySelector('.search');
    if (s) s.addEventListener('input', function () { q = s.value.trim().toLowerCase(); apply(); });
  });
  var h = location.hash.slice(1).split('/');
  if (h[1] === 'companies') setView('companies');
  if (h[0] && document.querySelector('.tabs [data-track="' + h[0] + '"]')) show(h[0]);
})();
"""

FAVICON = ("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' "
           "fill='%230a0a0a'/%3E%3Cpath d='M9 17l5 5 9-12' stroke='%23ffffff' stroke-width='3.5' fill='none' "
           "stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E")


def shell(title, desc, body, current):
    sha = os.environ.get("GITHUB_SHA", "local")[:7]
    built = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
    nav = [("index.html", "Leaderboard"), ("method.html", "Method"), (REPO_URL, "GitHub")]
    links = "".join(f'<a href="{h}"{" class=\"l-board\"" if h == "index.html" else ""}'
                    f'{" aria-current=\"page\"" if h == current else ""}>{t}</a>' for h, t in nav)
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{esc(title)}</title>
<meta name="description" content="{esc(desc)}">
<meta property="og:title" content="Does it run?">
<meta property="og:description" content="{esc(desc)}">
<link rel="icon" href="{FAVICON}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<style>{CSS}</style>
</head>
<body>
<header class="top"><div class="wrap"><a class="brand" href="index.html">Does it run?</a><nav class="links" aria-label="Pages">{links}</nav></div></header>
<div class="wrap">
{body}
<footer><span>Built {built} from <a href="{REPO_URL}/commit/{esc(sha)}">{esc(sha)}</a></span>
  <a href="{REPO_URL}">Code and every raw run log</a><a href="method.html">Method</a></footer>
</div>
</body>
</html>
"""


def index_page(tracks, all_exams, pushed_since):
    tabs = "".join(
        f'<button type="button" role="tab" data-track="{esc(t["track"])}" aria-selected="{"true" if i == 0 else "false"}">'
        f'{esc(TRACK_TABS.get(t["track"], (t["track"],))[0])}<span class="n">{len(t["repos"])}</span></button>'
        for i, t in enumerate(tracks))
    panels = "".join(track_panel(t, i, all_exams, pushed_since) for i, t in enumerate(tracks))
    body = f"""
<main>
<div class="hero">
<h1>Does it run?</h1>
<p class="lede">Do big companies' READMEs work as written? A script runs each README's own commands, line by line, on a fresh
  Linux box with no AI. Then an AI agent gets the same README and a clean box. A hidden test checks the demo's output both times.</p>
<div class="cta"><a class="btn primary" href="method.html">How it works →</a><a class="btn" href="{REPO_URL}/tree/main/data/runs">Every run log →</a></div>
</div>
<div class="switch"><div class="tabs" role="tablist" aria-label="Track">{tabs}</div>
  <div class="seg" role="group" aria-label="View"><button type="button" data-v="repos" aria-pressed="true">Repos</button><button type="button" data-v="companies" aria-pressed="false">Companies</button></div>
</div>
{panels}
</main>
<script>{JS}</script>"""
    return shell("Does it run? GitHub repo reproducibility leaderboard",
                 "Do big companies' READMEs work as written? Each README is run line by line with no AI, then by an AI agent; a hidden test decides.",
                 body, "index.html")


def method_page(tracks, all_exams, pushed_since):
    act, _ = active_slugs()
    nt = [e for e in all_exams if not e.get("eligible") and (act is None or e["slug"] in act)]
    groups = {}
    for e in nt:
        groups.setdefault(exclusion_kind(e.get("reason")), []).append(e)
    nt_html = ""
    for k, es in sorted(groups.items(), key=lambda kv: -len(kv[1])):
        lis = "".join(f'<li><a href="https://github.com/{esc(e["repo"])}">{esc(e["repo"])}</a> — {esc(e.get("reason") or "")}</li>'
                      for e in sorted(es, key=lambda e: (e.get("company", ""), e["repo"])))
        nt_html += f"<h3>{esc(k)} · {len(es)}</h3><ul>{lis}</ul>"
    body = f"""
<main class="prose">
<h1>Method</h1>
<p class="lede">How each repo is run and scored, and which repos were left out.</p>

<h2>With an AI agent</h2>
<ul>
  <li>The agent (Claude Code, Opus 5.5 pinned on the CPU tracks) has one tool, <code>docker exec</code>, into a throwaway
    container on a CPU-only GitHub-hosted runner (4 vCPU, 16 GB RAM, of which the container may use 12 GB; the prompts say 16 GB). No host access; private networks and cloud metadata are
    firewalled off. 90 minutes per repo.</li>
  <li>The goal is the repo's own README demo. A hidden test, committed before the run and copied in only after the agent
    stops, runs the demo on known input and checks the output.</li>
  <li>The agent's <code>setup.sh</code> is then replayed on a fresh container to see whether the install can be repeated.</li>
  <li>Every test was checked against the repo's source, then every pass against its raw log: it runs the README's main
    demo, a broken install cannot pass, and the task never hints at anything the README doesn't say. Revised tests are
    committed before they are re-run; superseded runs are kept. Each verdict and its evidence:
    <a href="{REPO_URL}/tree/main/data/reviews">data/reviews</a>.</li>
</ul>

<h2>README as written</h2>
<ul>
  <li>Before any AI touches it, each README is run exactly as written: a script of the README's own commands, copied
    verbatim. Every line cites the file and line it came from at the pinned commit, and
    <a href="{REPO_URL}/blob/main/literal_check.py">literal_check.py</a> fetches each cited line and confirms the command is
    on it. The rules: <a href="{REPO_URL}/blob/main/literal/RULES.md">literal/RULES.md</a>.</li>
  <li>The machine starts as a developer's would: Ubuntu 24.04 with git, curl, build tools, cmake, Python 3.12 with venv,
    pip and uv, and a few common system libraries. The script may fill in a placeholder the README asks you to fill,
    install a prerequisite the README names in words, and change directory. Nothing else.</li>
  <li>The same hidden test then checks the demo. A pass means the README works as written.</li>
  <li>A failure counts against the README only after triage: the exact error line is quoted from the log (a script
    checks it is there) and the failing README step is named. A failure caused by our script or by the container is
    fixed and run again. When the hidden test needs more than the README's demo, or the demo needs a GPU or more time
    than a CPU runner has, the repo is marked not judged.</li>
  <li>Scripts, logs and triage for every repo: <a href="{REPO_URL}/tree/main/data/literal">data/literal</a>.</li>
</ul>

<h2>The score</h2>
<ul>
  <li><code>100 − min(50, agent minutes) − min(40, 10 × repo files changed)</code>; 0 if the demo never ran.</li>
  <li>Files changed is measured with <code>git diff</code> on the repo (whitespace ignored); files with no changed line,
    such as a chmod or an image a demo overwrote, don't count.</li>
  <li>A review can waive a change shown not to be needed for the README demo (the agent overreaching); each waiver and
    its reason is in the run record.</li>
  <li>Replay is shown next to the score but not in it: it grades our install script, not the repo's authors.</li>
</ul>

<h2>Which repos</h2>
<ul>
  <li>Up to 25 of the most-starred Python repos per company, registered in
    <a href="{REPO_URL}/blob/main/data/candidates.json">data/candidates.json</a> before any run.</li>
  <li>Maintained: GitHub reported the repo not archived and pushed to since {esc(pushed_since or '')}
    (<a href="{REPO_URL}/blob/main/data/active.json">data/active.json</a>).</li>
  <li>Company comes from the owning GitHub org; teams are split only where separate org accounts show them.</li>
</ul>

<h2 id="not-tested">Not tested · {len(nt)}</h2>
<p>A stated requirement is not a fault, so these maintained repos were left out before any run. Each reason was checked
  against the README or docs. A repo counts as needing a GPU only when its README says so in words (needs a GPU,
  a GPU memory minimum, run on GPU machines); a <code>device="cuda"</code> default in sample code or a
  "tested on" line does not.</p>
{nt_html}

<h2>Limits</h2>
<p>This is a personal and fairly subjective test. Each repo ran once with one pinned agent; what counts as the demo and the
  score formula are my choices; agent time also moves with download speed. Companies with fewer than 3 repos are flagged.
  Scores are a signal, not a verdict.</p>
</main>"""
    css_extra = "<style>.prose h3{font:500 15px/1.3 var(--sans);color:var(--ink);margin:20px 0 4px}.prose ul ul{margin-top:0}.prose li{font-size:13px}</style>"
    return shell("Method · Does it run?", "How Does it run? tests each repo, scores it, and which repos were left out.",
                 css_extra + body, "method.html")


def main():
    data = load_json(ROOT / "data" / "leaderboard.json")
    tracks = data["tracks"]
    all_exams = exams()
    _, pushed_since = active_slugs()
    OUT.mkdir(exist_ok=True)
    write_badges(tracks)
    (OUT / "index.html").write_text(index_page(tracks, all_exams, pushed_since), encoding="utf-8", newline="\n")
    (OUT / "method.html").write_text(method_page(tracks, all_exams, pushed_since), encoding="utf-8", newline="\n")
    (OUT / "leaderboard.json").write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8", newline="\n")
    print(f"wrote {OUT / 'index.html'} and method.html ({sum(len(t['repos']) for t in tracks)} rows)")


if __name__ == "__main__":
    main()
