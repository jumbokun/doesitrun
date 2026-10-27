# repo-run-probe — WORKLOG

## Architecture

Question under test: can an agent, given only a sandbox, get freshly-popular GitHub repos
(not packaged by Pinokio) to actually run? This is the weekend validation for the
"one command runs any GitHub repo" idea. Pass rate + failure modes decide whether to build it.

- `base/Dockerfile` — thin sandbox image (CUDA 12.8 devel, git, python3, uv). Agent installs everything else.
- `box_mcp.py` — stdio MCP server with ONE tool `sh` = `docker exec <container> bash -lc <cmd>`.
  The agent's command string never touches a host shell. Every call is logged to `runs/<slug>/commands.jsonl`.
- `run_probe.py <slug>...` — per repo: locked-down container → `claude -p` (no built-in tools,
  strict MCP, dontAsk, no user settings) → hidden oracle → replay `setup.sh` on a FRESH container → oracle again.
- `oracles/<slug>.sh` — pre-registered pass criteria, written before any agent run, copied in only after the agent finishes.
- `repos.json` — the 5 targets, goals, and what the oracle checks (told to the agent in prose).
- `smoke_isolation.py` — asks the agent to try to reach the host; verifies from the command log that it can't.

### Safety model (user requirement: the laptop must stay safe)
- Untrusted repo code only ever runs inside containers; nothing is cloned to the host disk.
- No bind mounts, no secrets in the container env, `--cap-drop NET_RAW`, `no-new-privileges`,
  `--pids-limit`, memory/CPU caps, `host.docker.internal`/`gateway.docker.internal` pointed at the container's own loopback.
- The agent has no host tools: `--tools ""` + `--strict-mcp-config` + `--allowedTools mcp__box__sh` + `--permission-mode dontAsk`.
- Residual risk: containers still have internet and could reach other LAN devices by IP. Accepted for this probe.

## Facts

- Host: RTX 5060 Laptop GPU 8 GB (Blackwell sm_120 → needs CUDA 12.8+ / recent torch), Docker Desktop 29.1.3, 24 CPUs, 16 GB to WSL.
- GPU passthrough into containers verified (2026-10-26).
- Target selection (2026-10-26): Python repos created after 2026-07-20 with >800 stars, runnable on 8 GB/CPU,
  oracle definable from README, no Pinokio port found. manimgx is the polished-package control.
- Observation while selecting: many 2026 hot repos ship polished installers (pip/exe); the pain is concentrated in research code.

## Operations

- 2026-10-26: scaffold written; building rr-base.
- 2026-10-26: rr-base built (16.5 GB). Smoke test: agent tool list = [mcp__box__sh] only; no host paths visible.
- 2026-10-26: FOUND: `--add-host` overrides the names, but 192.168.65.254 (Docker Desktop host IP) still reached
  a host canary bound to 127.0.0.1. Fixed with dedicated network rr-net (bridge rr-br0) + REJECT rules in the VM's
  DOCKER-USER chain for all private ranges. `firewall_check.py` proves it (positive control on default network
  reaches the canary; rr-net does not; pypi/HF still 200). run_probe refuses to start if the check fails.
- 2026-10-26: launched lane CPU (manimgx → earshot) and lane GPU (kev → nanojev → unimate).
- 2026-10-26 12:06: batch 1 finished. 5/5 pass on the hidden oracle AND 5/5 pass after replaying setup.sh
  on a fresh container. Total agent cost $5.90 (claude-opus-5). manimgx duration independently verified
  on host by parsing the mp4 mvhd box: 6.017 s (oracle had skipped it: no ffprobe in the image).

| repo | oracle | agent | replay setup | replay oracle |
|---|---|---|---|---|
| manimgx | pass | 5 min / 16 turns / $0.61 | 1 min | pass |
| earshot | pass | 22 min / 24 turns / $0.98 | 6 min | pass |
| kev | pass | 30 min / 34 turns / $1.47 | 13 min | pass |
| nanojev | pass | 33 min / 35 turns / $1.64 | 29 min | pass |
| unimate | pass | 27 min / 29 turns / $1.20 | 9 min | pass |

  Failure modes the agent hit and fixed (from NOTES.md): Python version mismatch (3.12 vs 3.13 wheels);
  PEP-668 / no `python` on PATH; missing apt deps (ffmpeg, python3-venv, python3-dev for triton JIT);
  pinned torch cu124 has no sm_120 kernels (UniMate → torch 2.8 cu128, no code change);
  conda assumed but absent (→ uv venv); undocumented model download (flan-t5-base); silent 90 s startup.

## Interpretation (batch 1)
- Test set was too easy to find the ceiling: all 2026 repos with careful READMEs and recent pins.
  The real pain is likely older/abandoned research code — not yet measured.
- A general agent + Docker already does this. A product's moat would have to be: verified sandbox
  (we found a real host-reach hole), replay-verified setup.sh, and a shared cache so the 20–30 min
  agent run happens once per repo while everyone else gets the 1–29 min replay.
- Stopped containers kept for inspection: ~80 GB of Docker disk.
- 2026-10-26: batch 2 (hard set) pre-registered in repos_b2.json + oracles/: 2020–2023 research repos with
  install complaints in issues (title counts e.g. yolov7 CUDA=42, GroundingDINO install=17/_C=10, OldPhotos CUDA=21):
  GroundingDINO, Bringing-Old-Photos (archived), LaMa, stylegan2-ada-pytorch, yolov7, MDM.
  Oracles force GPU code paths instead of the VRAM-delta check (two lanes share the GPU).
  Note: LaMa README's LaMa_test_images.zip is not in the repo; oracle generates its own image+mask.
- 2026-10-26 14:00: Docker Desktop's WSL VM was torn down mid-run ("unshare caught expected signal interrupt",
  Hyper-V vNIC deleted 14:01). Both in-flight replays (groundingdino, yolov7) died with API 500 → those replay
  failures are INFRA, not agent results. Host had 31.4 GB RAM / 3.6 GB free afterwards; two lanes downloading
  multi-GB torch wheels concurrently is the likely trigger (unproven). Restarted with `docker desktop restart`.
  Resume is single-lane; crashed replay logs kept as *.crash.*, invalidated replay kept in result.json.
- 2026-10-26 14:2x: replays of groundingdino/yolov7 after the crash failed on uv network timeouts (30 s) while
  downloading torch deps; probe-network throughput re-measured at ~3.8 MB/s (default net ~5.8 MB/s), so a
  transient stall + no retry in setup.sh. Counted as FAIL per protocol; a clearly labelled supplementary
  replay (`--replay-supplementary`, stored under replay_supplementary) runs after the batch.
- 2026-10-26 14:4x: user requirement — don't use much memory. Host had 0.1 GB free; WSL VM committed 11.9 GB,
  of which 11.7 GB was page cache from downloads. Dropped VM caches (commit → 6.8 GB, host free → 1.8 GB),
  capped rr-oldphotos live to 4 GB, wrote ~/.wslconfig (memory=8GB, autoMemoryReclaim=dropCache).
  CONDITION CHANGE: lama, mdm and the supplementary replays run at 4 GB/container (earlier repos had 5–10 GB).
  resume_lowmem.sh restarts WSL after oldphotos so the cap takes effect, then resumes.
- 2026-10-26 15:2x: drop_caches_loop.sh (every 2 min while running) kept the VM at ~2.5–4 GB commit
  (was hitting the 8 GB cap with page cache); host free 0.6 → 4.7 GB.
- 2026-10-26 16:33: batch 2 finished. Agent-stage oracle 6/6. Protocol replay 3/6.

| repo | agent oracle | agent | protocol replay | supplementary replay |
|---|---|---|---|---|
| stylegan2ada | pass | 22 min / 17 turns / $0.79 | pass | - |
| oldphotos | pass | 36 min / 35 turns / $1.24 | pass | - |
| lama | pass | 21 min / 46 turns / $2.03 | pass | - |
| groundingdino | pass | 47 min / 36 turns / $1.61 | FAIL (uv 30 s timeout, torch deps) | pass (4 GB) |
| yolov7 | pass | 16 min / 22 turns / $0.75 | FAIL (uv 30 s timeout, torch deps) | pass (4 GB) |
| mdm | pass | 31 min / 61 turns / $3.13 | FAIL (setup.sh needs undelivered requirements.txt/patches/tools) | FAIL (pypi.nvidia.com timeout; extras added) |

  $ = Claude Code's API-price estimate (total_cost_usd); actual billing is subscription quota (apiKeySource=none).
  MDM's Google Drive checkpoint was tested in isolation on rr-net: gdown 5.2.0 fetched the 207 MB zip in 27 s,
  so Drive was not the blocker. MDM's replay is UNRESOLVED, not passed.

  What the agent had to fix in 2020–23 repos: every one pinned torch without sm_120 kernels (1.7/1.8/1.9/2.5
  → 2.8/2.11 cu128); conda/python3.6–3.7 assumed; unresolvable old pins; code patches needed in 3/6
  (oldphotos 1 line scikit-image dtype, lama 4 patches for albumentations>=1.0 etc., mdm 5-line patch +
  chumpy-free SMPL pickle rewrite); dead tooling (gdown --fuzzy in 6.x, spacy/typer-slim/click, libgl1-mesa-glx).

## Interpretation (batches 1+2)
- Getting an old repo running is now within a general agent's reach: 11/11 passed the hidden oracle on the
  agent's own container, median ~27 min, worst 47 min, none timed out.
- The weak link moved to REPRODUCIBILITY: 3/6 batch-2 setup.sh failed on a fresh machine — 2 on transient
  multi-GB wheel download stalls (no retry/timeout tuning), 1 on not packaging its own helper files.
  "Works on my container" ≠ a shareable installer. A product must enforce: self-contained deliverable,
  download retries / a local wheel+model cache, and a mandatory fresh-container replay before publishing.
- That strengthens the shared-cache thesis: pay the 20–60 min agent run once per repo, ship a replay-verified
  installer plus cached artifacts, so the user's install doesn't depend on PyPI/NVIDIA CDN luck.
- 2026-10-27: moved out of the web3work monorepo into its own repo (format-patch --relative + git am,
  tree hash identical), renamed to **doesitrun**, made public (history audited first: no secrets, no
  personal paths). Leaderboard v0 + attribution + static site; GitHub Pages via Actions on push to
  data/ or the renderer → https://jumbokun.github.io/doesitrun/ . Checked live at 390/1280 px.
  Local folder is still `repo-run-probe/` under web3work (renaming it would break running jobs' paths).
- 2026-10-27: harness now gives every container uv/pip/HF timeouts+retries (measurement hygiene for the
  ranking) and records an objective repo_diff; backfilled for all 11 runs (5/11 patched repo code).
- 2026-10-27: repair round validated on MDM (14 min repair, then fresh-container replay PASS). Records now
  self-contained in data/runs (track, goal/check, replay class); leaderboard ranks per hardware track.
- 2026-10-27: user wants nothing on the local machine and no paid servers → CPU track on free GitHub-hosted
  runners (public repo). Firewall ported to native Linux: INPUT reject for the probe bridge (container→host via
  bridge gateway bypasses DOCKER-USER) + Azure WireServer 168.63.129.16 blocked. Claude subscription token is a
  repo secret (user set it; never passed through chat). Acceptable-use risk of testing third-party repos on
  Actions noted to the user.
- 2026-10-27: batch 3 pre-registered: data/candidates.json = top 25 Python repos by stars per company across
  official orgs (Google, Meta, Microsoft, NVIDIA, Alibaba, Tencent, ByteDance, Baidu; 200 candidates); examiner
  agent screens in star order until 10 eligible per company and writes goal + hidden oracle, committed before
  probes run. PROTOCOL CHANGE vs batches 1-2: oracles are now examiner-written (spot-checked), not hand-written.
- 2026-10-27: housekeeping — history rebuilt before push: LF normalization (.gitattributes), write_text pinned to
  LF, the repair round split out of the firewall commit it had been swept into, and .gitignore "runs/" fixed to
  "/runs/" (it was silently ignoring data/runs).
- 2026-10-27: full CPU batch dispatched (79 repos, 8 company workflows x 2 parallel). Early check found
  python-fire scored 0 by an ORACLE DEFECT: the examiner asserted `grep -qi usage` on Fire's help, which is
  man-page style (NAME/SYNOPSIS); under set -e it exited silently with 0 bytes. Reproduced locally.
  PROTOCOL ADDITION (committed before implementing or running it): oracle audits — see README "Oracle audits".
  Oracles now run with bash -x. BERT's failure is genuine (setup.sh needs an undelivered tools/ file; a 403).
- 2026-10-27: first audits — microsoft/data-formulator: oracle_defect (oracle's curl omitted the X-Workspace-Id
  header the code requires by design); google/python-fire: oracle_defect (confirms local repro); google-research/bert
  and google/trax: repo_failure — their README model links (GCS) now return 403 AccessDenied to anonymous users.
  Auditor is not rubber-stamping defects.
- 2026-10-27: Tencent and ByteDance (3D/video/large-model repos) ran near the 90-min cap at 2 parallel; cancelled
  both runs (collect still committed the finished ones: Tencent 3, ByteDance 2) and redispatched the remaining 15
  at 5 parallel. The 4 jobs in flight at cancel time were rerun from scratch.
- 2026-10-27: auto-audit dispatcher (local script, polls every 3 min) sends each committed CPU failure to the audit
  exactly once. First version broke on a Git Bash vs Windows /tmp path and dispatched one empty run (cancelled).
- 2026-10-27 INCIDENT: the broken first dispatcher sent an audit with slugs="" (run 40441957458); GitHub substituted
  the default "[]" = all repos, so it began auditing all 80 incl. passing ones until cancelled. Its collect committed
  an audit of google-research/timesfm (oracle had PASSED; the leaderboard then silently dropped it as
  oracle_defect) and a duplicate BERT audit. Restored both records (fca5e35) and added guards: audit refuses passed
  runs, scoring only honours oracle_defect on a failed oracle, audit mode requires an explicit non-empty list.
- 2026-10-27: audit verdicts so far — oracle_defect: python-fire, data-formulator, ParlAI, pytorch3d, UI-TARS;
  repo_failure: BERT, trax (GCS 403), Depth-Anything-3 (missing `addict` dependency). Roughly half of oracle failures
  are examiner defects: examiner-written oracles are not reliable enough to score without the audit.
- 2026-10-27 08:0x: CPU batch complete — 80/80 records. 62/80 oracles passed; 59/80 first replays passed; median agent
  4.2 min; 4 hit the 90-min cap (incl. ByteDance Dolphin: no setup.sh, audit "inconclusive", stays 0). Audits:
  repo_failure 6 (BERT/trax GCS 403, SPADE Drive 404, Depth-Anything-3 missing dependency, FunClip, Megatron-LM
  tokenizer), oracle_defect 8 (fire, data-formulator, ParlAI, pytorch3d, UI-TARS, SkillSpector, warp,
  PaddleSpeech), inconclusive 1, pending 3 (Tencent Hunyuan3D-1, Hunyuan3D-2.1, PocketFlow; run 40464509343 will
  commit and redeploy on its own). Company means (CPU): Microsoft 93, Meta 93, Alibaba 84, Baidu 83, Google 70
  (Google Research 40), NVIDIA 59, Tencent 57 (Hunyuan 39), ByteDance 55. One run per repo.
- Open: run-to-run variance (2+ runs per repo), examiner oracle quality (8 defects among ~18 failures), GPU track at
  scale (needs a GPU host; GCP $300 credit requires a paid upgrade), REPORT.json kinds are agent-reported.
