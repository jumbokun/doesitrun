"""Render the share images from data/leaderboard.json (run locally, commit the PNGs; Pages only copies them).

    python og_card.py            -> docs/og.png    (1.91:1 link preview, og:image)
                                    docs/post.png  (4:5 image to attach to a post)

One square per judged repo: filled = the README works exactly as written, red = it breaks at a step.
Layout is in CSS pixels; device_scale_factor makes the master sharp (og 3840 px wide, post 2160 px wide).
"""
import html, json
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent
LB = json.loads((ROOT / "data/leaderboard.json").read_text(encoding="utf-8"))
REPOS = {t["track"]: t for t in LB["tracks"]}["cpu-gha-maintained"]["repos"]
URL = "jumbokun.github.io/doesitrun"


def tier(r):
    return (r.get("literal") or {}).get("tier")


def companies():
    out = {}
    for r in REPOS:
        c = out.setdefault(r["company"], {"ok": 0, "bad": 0, "other": 0})
        c[{"as-written": "ok", "readme-broken": "bad"}.get(tier(r), "other")] += 1
    rows = sorted(out.items(), key=lambda kv: (-(kv[1]["ok"] / max(1, kv[1]["ok"] + kv[1]["bad"])) if kv[1]["ok"] + kv[1]["bad"] else 1,
                                               -(kv[1]["ok"] + kv[1]["bad"]), kv[0]))
    return rows


def card(kind):
    rows = companies()
    ok = sum(c["ok"] for _, c in rows)
    bad = sum(c["bad"] for _, c in rows)
    ran = sum(1 for r in REPOS if r["score"])
    lines = []
    for name, c in rows:
        judged = c["ok"] + c["bad"]
        cells = "".join('<i class="ok"></i>' for _ in range(c["ok"])) + "".join('<i class="bad"></i>' for _ in range(c["bad"]))
        frac = f'{c["ok"]}/{judged}' if judged else "none judged"
        lines.append(f'<div class="row{" dim" if not judged else ""}"><span class="co">{html.escape(name)}</span>'
                     f'<span class="cells">{cells}</span><span class="fr">{frac}</span></div>')
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
:root {{ --ink:#0a0a0a; --ink-2:#525252; --ink-3:#8a8a8a; --line:#e5e5e5; --neg:#d92d20; }}
body {{ background:#fff; color:var(--ink); font-family:"JetBrains Mono",monospace; font-variant-numeric:tabular-nums;
       -webkit-font-smoothing:antialiased; }}
.card {{ width:var(--w); height:var(--h); padding:var(--pad); display:flex; flex-direction:column; }}
.brand {{ font-weight:600; font-size:var(--s-brand); letter-spacing:-.01em; }}
.brand span {{ color:var(--ink-3); font-weight:400; margin-left:.6em; }}
h1 {{ font-weight:600; font-size:var(--s-h1); line-height:1.12; letter-spacing:-.03em; margin-top:var(--gap); text-wrap:balance; }}
h1 b {{ font-weight:700; }}
.sub {{ color:var(--ink-2); font-size:var(--s-sub); line-height:1.45; margin-top:calc(var(--gap) * .5); max-width:var(--sub-w); }}
.sub b {{ color:var(--ink); font-weight:600; }}
.chart {{ margin-top:var(--gap); display:grid; grid-template-columns:repeat(var(--cols), 1fr); column-gap:var(--cg); flex:1; align-content:start; }}
.row {{ display:grid; grid-template-columns:var(--co-w) 1fr auto; align-items:center; gap:var(--cell-gap);
       padding:var(--row-pad) 0; border-top:1px solid var(--line); }}
.row.dim {{ color:var(--ink-3); }}
.co {{ font-size:var(--s-row); font-weight:500; }}
.cells {{ display:flex; gap:var(--cell-gap); }}
.cells i {{ width:var(--cell); height:var(--cell); display:block; }}
.cells i.ok {{ background:var(--ink); }}
.cells i.bad {{ background:var(--neg); }}
.fr {{ font-size:var(--s-row); color:var(--ink-2); text-align:right; }}
.foot {{ display:flex; justify-content:space-between; align-items:center; font-size:var(--s-foot); color:var(--ink-2);
        padding-top:calc(var(--gap) * .5); border-top:1px solid var(--ink); }}
.key {{ display:flex; gap:1.4em; }}
.key i {{ display:inline-block; width:.8em; height:.8em; margin-right:.45em; vertical-align:-.05em; }}
.foot .url {{ color:var(--ink); font-weight:600; }}
.og {{ --w:1200px; --h:628px; --pad:52px 60px 44px; --gap:28px; --s-brand:20px; --s-h1:46px; --s-sub:19px; --sub-w:1000px;
      --cols:2; --cg:56px; --co-w:150px; --row-pad:9px; --cell:17px; --cell-gap:5px; --s-row:17px; --s-foot:16px; }}
.post {{ --w:1080px; --h:1350px; --pad:72px 76px 60px; --gap:42px; --s-brand:26px; --s-h1:68px; --s-sub:27px; --sub-w:900px;
        --cols:1; --cg:0; --co-w:220px; --row-pad:12px; --cell:30px; --cell-gap:8px; --s-row:26px; --s-foot:22px; }}
.post .foot {{ flex-direction:column; align-items:flex-start; gap:18px; }}
</style></head><body>
<div class="card {kind}">
  <div class="brand">Does it run?<span>README benchmark · Nov 2026</span></div>
  <h1><b>{ok} of {ok + bad}</b> big-tech READMEs work exactly as written.</h1>
  <p class="sub">{len(REPOS)} maintained Python repos from {len(rows)} companies, run line by line on a fresh Linux box with no AI.
    With an AI agent, <b>{ran} of {len(REPOS)}</b> ran.</p>
  <div class="chart">{"".join(lines)}</div>
  <div class="foot"><span class="key"><span><i style="background:var(--ink)"></i>works as written</span>
    <span><i style="background:var(--neg)"></i>breaks at a step</span></span><span class="url">{URL}</span></div>
</div></body></html>"""


def main():
    out = ROOT / "docs"
    with sync_playwright() as p:
        b = p.chromium.launch(channel="chrome")
        for kind, w, h, scale, name in (("og", 1200, 628, 3.2, "og.png"), ("post", 1080, 1350, 2, "post.png")):
            pg = b.new_page(viewport={"width": w, "height": h}, device_scale_factor=scale)
            pg.set_content(card(kind), wait_until="networkidle")
            pg.evaluate("document.fonts.ready")
            over = pg.evaluate("(() => { const c = document.querySelector('.card'); return c.scrollHeight - c.clientHeight; })()")
            assert over <= 0, f"{kind}: content overflows the card by {over}px"
            pg.screenshot(path=str(out / name), clip={"x": 0, "y": 0, "width": w, "height": h})
            print(f"wrote docs/{name}")
        b.close()


if __name__ == "__main__":
    main()
