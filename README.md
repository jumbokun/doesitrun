# Does it run?

**How hard is it to get a GitHub repo's README demo actually running?**
A sandboxed AI agent tries, a hidden test decides, and the agent's installer is replayed on a brand-new machine.

**Live leaderboard → https://jumbokun.github.io/doesitrun/**

| | |
|---|---|
| Repos tested | 11 (batch 1: five 2026 releases; batch 2: six 2020–23 research repos) |
| Got running | 11 / 11 on the agent's own machine, median 28 min, none hit the 90 min cap |
| Installer replays first try | 8 / 11 on a fresh machine |
| Repo code had to be patched | 5 / 11 (every 2020–23 repo except StyleGAN2-ADA) |

Getting old research code to run is now within reach of a general agent. The weak link has moved:
*"works in my container"* is not yet *a shareable installer*.

## How a run works

```
README demo ──► agent (Claude Code, ONE tool: `docker exec` into a throwaway container)
                 │   Ubuntu 24.04 · CUDA 12.8 · RTX 5060 8 GB (Blackwell, sm_120)
                 ▼
            hidden oracle  ── written before the run, copied in only after the agent stops
                 ▼
            replay setup.sh on a FRESH container ──► oracle again
```

- **Goal** is the repo's own documented demo (e.g. StyleGAN2-ADA's `generate.py` with its CUDA plugins
  actually compiled, LaMa's `predict.py` on CUDA). Pass/fail is decided by `oracles/<repo>.sh`, never by
  the agent's own claim.
- **Deliverables** from the agent: `setup.sh` (from scratch, non-interactive), `env.sh`, `run.sh` for
  servers, `NOTES.md`, and a typed `REPORT.json` of every deviation from the README.
- **Replay**: `setup.sh` runs on a fresh container and the oracle runs again. If that fails, the log goes
  back to the same agent session for one repair round and the repaired installer is replayed again; the
  first failure stays on record. (MDM: not self-contained at first, passed after a 14-minute repair.)

## Tracks and batches

Scores are only compared within a hardware track.

| track | hardware | repos | how they were chosen |
|---|---|---|---|
| `gpu-rtx5060` | RTX 5060 Laptop 8 GB, local | 11 | batch 1: five 2026 releases; batch 2: six 2020–23 research repos with install complaints |
| `cpu-gha` | GitHub-hosted runner, 4 vCPU / 16 GB, no GPU | in progress | per company, top 25 Python repos by stars across its official orgs; the first 10 an examiner rules eligible |

The `cpu-gha` track runs entirely on GitHub Actions ([`exam.yml`](.github/workflows/exam.yml),
[`probe.yml`](.github/workflows/probe.yml)). An **examiner agent** reads each candidate (no install) and
either excludes it with a reason or writes the goal and hidden oracle; those are committed *before* any
probe runs, so the commit history is the pre-registration. Candidate pool: [`data/candidates.json`](data/candidates.json);
verdicts: `data/exams/`; run records: `data/runs/`.

## Oracle audits

Examiner-written oracles can be wrong (python-fire's asserted the word "usage" in help output that is
man-page style). Rule, fixed before any audit ran and applied to every CPU-track repo whose hidden oracle
failed on the agent's container:

1. A fresh container replays the agent's `setup.sh`, the unchanged oracle runs under `bash -x`.
2. An independent **auditor agent** (Opus, `sh` into that container only) reads the oracle, its trace, the
   goal it was meant to check and the repo's README, and rules one of:
   `repo_failure` (install/demo genuinely broken), `oracle_defect` (the oracle asserts something the README
   never promised, or depends on its own environment), `inconclusive`.
3. `oracle_defect` → the repo is **not scored** (neither pass nor fail) and is labelled on the page;
   the oracle and its verdict stay in the record. Nothing is ever flipped to a pass.

## Scoring

```
score = 100 − min(50, agent minutes) − min(40, 10 × repo files patched)      (0 if it never ran)
```

Only objective inputs: wall-clock agent time, and repo files changed as measured by `git diff`
on the agent's clone (whitespace ignored) — not the agent's notes, which under-report patches.
Replay is shown next to the score but not in it: it grades the installer we produced, not the repo's authors.

## Who made it

Every repo rolls up to a company and, where knowable, a team (so all of Google's repos form a Google score,
split into DeepMind, Google Research, …). Evidence, strongest first:

| confidence | signal |
|---|---|
| high | owning GitHub org (`google-deepmind`, `facebookresearch`, `NVlabs`, `microsoft`, …) |
| medium | company as LICENSE copyright holder or required CLA |
| medium | author affiliations of the README's arXiv paper, via [OpenAlex](https://openalex.org) |
| low | README mentions (team names and academia only; a README naming Google may just cite it) |

Rules live in [`orgs.json`](orgs.json); per-repo evidence in [`data/attribution.json`](data/attribution.json).

## Safety model

The agent never touches the host:

- Its only tool is an MCP server ([`box_mcp.py`](box_mcp.py)) that runs one command via `docker exec`;
  the command string is a single argv element and never reaches a host shell. Every call is logged.
- Headless `claude -p` with `--tools ""`, `--strict-mcp-config`, `--permission-mode dontAsk`, no user settings.
- Containers: no bind mounts, no secrets, `--cap-drop NET_RAW`, `no-new-privileges`, CPU/memory/pid limits.
- Overriding `host.docker.internal` is **not** enough on Docker Desktop: `192.168.65.254` still reaches
  services bound to the host's `127.0.0.1`. Probe containers use a dedicated bridge whose private-range
  egress is rejected in the Docker VM's `DOCKER-USER` chain, and [`firewall_check.py`](firewall_check.py)
  proves it before every batch with host canaries plus a positive control. If the check fails, nothing runs.

## Run it yourself

Locally: Windows 11 + Docker Desktop (WSL2) with an NVIDIA GPU. On CI: GitHub-hosted Ubuntu runners
(`RR_IMAGE=rr-cpu`). The firewall works on both and is re-proven before every batch.

```bash
docker build -t rr-base base
python firewall_check.py                        # must print FIREWALL OK
python run_probe.py manimgx                     # one repo from repos.json
python run_probe.py --repos=repos_b2.json lama  # another target list
python leaderboard.py                           # data/runs -> data/leaderboard.json, LEADERBOARD.md
python build_site.py                            # -> _site/index.html (CI does this on push)
```

Requires the Claude Code CLI logged in. To add a repo, append it to a repos file with a goal and write
`oracles/<slug>.sh` *before* running it.

## Layout

| path | what |
|---|---|
| `run_probe.py` | harness: examiner, container → agent → oracle → replay → repair → replay |
| `box_mcp.py` | the agent's single tool |
| `oracles/` | pre-registered pass criteria |
| `repos.json`, `repos_b2.json` | targets and goals per batch |
| `attribute.py`, `orgs.json` | company/team attribution |
| `leaderboard.py`, `build_site.py` | scoring and the static site |
| `WORKLOG.md` | full lab notebook, including every failure and protocol change |

## Limitations

Small sample, one run per repo, one GPU generation (Blackwell needs recent PyTorch, which penalises old pins),
8 GB VRAM limits which repos are eligible, and agent time also moves with download speed. Company rows with
n < 3 are previews of the format, not rankings. Every protocol change is logged in [`WORKLOG.md`](WORKLOG.md).

Suggest a repo or dispute a result: open an issue.

## License

[MIT](LICENSE)

---

### 中文简介

**Does it run?** 测的是：一个 GitHub 仓库的 README 演示，到底有多难真正跑起来。

做法是让一个 AI Agent 在隔离的沙箱里照着 README 去装、去跑，由一个事先写好、Agent 看不到的测试来判定成功，
最后再把 Agent 写的安装脚本放到一台全新的机器上重放一遍。榜单按「谁家的仓库最好复现」汇总到公司和团队
（比如谷歌下面再分 DeepMind、Google Research）。目前 11 个仓库全部能跑通，但只有 8 个的安装脚本能在新机器上一次复现。
