# I let an AI agent try to run 80 big-tech GitHub repos. Here's what broke.

*October 2026 · [live leaderboard](https://jumbokun.github.io/doesitrun/) · [code and every raw record](https://github.com/jumbokun/doesitrun)*

"Just follow the README" is the oldest lie in open source. I wanted a number for it, so I built a harness where an AI
agent gets a brand-new Linux box, one tool (`docker exec`), and a repo's README, and has to make the README's own demo
work. A test the agent never sees decides whether it did. Then its install script is replayed on another fresh machine.

I ran it on the 10 most-starred eligible Python repos from each of Google, Meta, Microsoft, NVIDIA, Alibaba,
Tencent, ByteDance and Baidu, on free GitHub Actions runners (4 vCPU, 16 GB RAM, **no GPU**).

## TL;DR

- **62 of 80 README demos ran.** Median agent time: 4 minutes. Most well-maintained repos are easy.
- **34 of the 114 most-starred repos I looked at could not even be attempted on a normal machine:** 16 need a GPU or
  more than 16 GB, 11 need a paid API key, 5 need a gated model, 2 other. At ByteDance it was 10 of the 20 examined.
- **Official download links rot.** All 34 model links in [google-research/bert](https://github.com/google-research/bert)'s
  README return HTTP 403; so does the bucket [google/trax](https://github.com/google/trax)'s README loads from; the
  pretrained models for [NVlabs/SPADE](https://github.com/NVlabs/SPADE) are a Google Drive 404.
- **The AI-written tests were wrong about half the time.** Of 18 failures, 9 turned out to be the hidden test's fault,
  not the repo's. Without an independent audit, 9 repos would have been scored 0 unfairly.

## How a run works

1. **Selection is fixed up front.** Per company: the top 25 Python repos by stars across its official GitHub orgs.
   ([candidate list](data/candidates.json))
2. **An examiner agent** reads each candidate in star order, without installing anything. It either excludes it with
   a reason ([all 34 reasons](data/exams)), or writes a goal and a hidden test. The tests are committed *before* any run,
   so the git history is the pre-registration.
3. **A probe agent** (Claude Opus) gets the goal but not the test, in a locked-down container: no host access, private
   networks firewalled off. It has 90 minutes.
4. **The hidden test runs**, then the agent's `setup.sh` is **replayed on a fresh container** to see if the install is
   shareable. If the replay fails, the log goes back to the agent for one repair round.
5. **Every failed test is audited** by a third agent, which looks at the test, its line-by-line trace, the README and
   the installed environment, and rules "repo failure", "test defect" or "inconclusive". A defective test means the
   repo is left unscored. It is never turned into a pass.

Score = `100 − agent minutes (max 50) − 10 × repo files the agent modified (max 40)`, or 0 if the demo never ran.
The number of files changed comes from `git diff` on the repo, not from the agent's notes.

## What broke

**Dead links, years old.** The BERT README links 34 pretrained checkpoints on Google Cloud Storage; every one of them
returns 403 today. Someone reported the bucket going private in 2020 ([#1152](https://github.com/google-research/bert/issues/1152));
the repo is now archived, so the README will keep pointing there. trax's README loads its translation model and
vocabulary from `gs://trax-ml`, which also returns 403 to anonymous users, and that repo is archived too. SPADE's README
sends you to a Google Drive file that is a 404 ([#175](https://github.com/NVlabs/SPADE/issues/175), open since 2024).

**Missing dependencies.** ByteDance-Seed/Depth-Anything-3 uses `addict` in 14 source files but doesn't declare it, so
`pip install -e .` gives a CLI that crashes on import. That's known ([#86](https://github.com/ByteDance-Seed/Depth-Anything-3/issues/86))
and two PRs are open.

**What agents fixed silently.** Across the 80 CPU runs, the agents' own reports list 78 dependency-pin changes,
67 steps the README didn't mention, and 42 GPU-compatibility changes. These counts are self-reported. Code changes
are measured directly with `git diff`: in 30 of 80 repos the agent modified at least one of the repo's own files.

**Installers.** Of the 62 repos whose demo ran, 59 install scripts replayed on a fresh machine on the first try, and
the other 3 replayed after one repair round. (On the earlier GPU batch, first-try replays failed on stalled multi-GB
wheel downloads and on helper files the agent never packaged.)

## The tests were the weakest link

I expected the examiner's hidden tests to be the reliable part. They weren't. Some of the 9 defects:

- **python-fire:** the test grepped the `--help` output for "usage". Fire prints man-page style help
  (NAME / SYNOPSIS) and never uses that word.
- **microsoft/data-formulator:** the test called an internal API without the `X-Workspace-Id` header the server requires
  by design. With the header it works.
- **NVIDIA/warp:** the test defined a Warp kernel inside `python -c`. Warp's own docs say not to: its code generator
  reads kernel source with `inspect`, which fails for code with no source file.
- **NVIDIA/SkillSpector:** the scanner exits 1 when it finds a risk, as documented. The test treated that as a crash.

The auditor isn't a rubber stamp: it ruled BERT, trax, SPADE and Depth-Anything-3 genuine failures, each with a command
and its output as evidence. It isn't perfectly stable either. Three repos were audited twice by mistake, and the two
verdicts disagreed once.

## The table

CPU track, mean score (number scored). Teams are split only where separate GitHub org accounts show them.

| company | mean (n) | teams |
|---|---|---|
| Microsoft | 93 (9) | one org account |
| Meta | 93 (8) | FAIR |
| Alibaba | 84 (10) | Qwen 93 · ModelScope 78 |
| Baidu | 83 (9) | Baidu 88 · PaddlePaddle 82 |
| Google | 70 (9) | DeepMind 89 · Google 74 · Google Research 53 |
| Tencent | 64 (9) | ARC Lab 94 · Tencent 76 · Hunyuan 39 |
| NVIDIA | 59 (8) | NVIDIA Research 61 · NVIDIA 56 |
| ByteDance | 55 (9) | ByteDance 58 · Seed 44 |

Read it with care. Each repo ran once. NVIDIA's mean is pulled down mostly by two zeros that have nothing to do with
CUDA (Megatron-LM's tokenizer fails to load with current transformers; SPADE's pretrained models are a 404). Porting
CUDA-first StyleGAN-era code to CPU cost it points too. And "top 25 by stars" mixes research dumps with polished
products. The interesting part is less the order than *why* things fail.

## What I got wrong along the way

All of it is in [WORKLOG.md](WORKLOG.md). The parts that matter for trusting the numbers:

- A local dispatcher bug sent an audit with an empty repo list. GitHub substituted the default, which meant "all repos",
  and it audited a repo whose test had passed. That repo was then silently dropped from the ranking until I caught
  it. There are now guards against it.
- The auditor wasn't told when the agent had run out of time. One timed-out repo was briefly marked "test defect". A
  timed-out failure now stays 0.
- My first team split used README mentions. That put an archived Google repo under Google Research and made a much
  more dramatic headline than the data supports. Teams now come from org accounts only.

## Try it, dispute it

- [Request a test](https://github.com/jumbokun/doesitrun/issues/new?template=test-my-repo.yml) for your repo, or
  [dispute a result](https://github.com/jumbokun/doesitrun/issues/new?template=dispute-a-result.yml) with evidence.
- Tested repos can show a badge: `https://img.shields.io/endpoint?url=https://jumbokun.github.io/doesitrun/badge/cpu-gha/OWNER/REPO.json`
- The CPU track runs on free GitHub Actions; the GPU track ran on a local RTX 5060. The harness and every record
  are MIT-licensed.
