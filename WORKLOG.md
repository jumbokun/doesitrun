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
