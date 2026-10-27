# Reproducibility leaderboard (v0)

How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent (Claude Code, one `docker exec` tool, RTX 5060 8 GB, CUDA 12.8) tries each repo; a hidden, pre-registered oracle decides success. Scoring and caveats: see `leaderboard.py` docstring and WORKLOG.md.

**n = 11 repos. One run each. Too few per company for company claims; this table shows the structure, not a verdict.**

## Repos (higher = easier)

| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |
|---|---|---|---|---|---|---|
| 1 | [academa-labs/manimgx](https://github.com/academa-labs/manimgx) | 94.1 | 6 min | 0 (0 lines) | pass | Independent / academa-labs (none) |
| 2 | [Leonxlnx/earshot](https://github.com/Leonxlnx/earshot) | 77.9 | 22 min | 0 (0 lines) | pass | Independent / Leonxlnx (none) |
| 3 | [NVlabs/stylegan2-ada-pytorch](https://github.com/NVlabs/stylegan2-ada-pytorch) | 77.1 | 23 min | 0 (0 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 4 | [Friedrich-M/UniMate](https://github.com/Friedrich-M/UniMate) | 72.4 | 28 min | 0 (0 lines) | pass | Academia / Berkeley (low) |
| 5 | [jaredpalmer/kev](https://github.com/jaredpalmer/kev) | 69.1 | 31 min | 0 (0 lines) | pass | Independent / jaredpalmer (none) |
| 6 | [TianyuCodings/NanoJev](https://github.com/TianyuCodings/NanoJev) | 66.9 | 33 min | 0 (0 lines) | pass | Independent / TianyuCodings (none) |
| 7 | [GuyTevet/motion-diffusion-model](https://github.com/GuyTevet/motion-diffusion-model) | 58.5 | 32 min | 1 (5 lines) | fail: installer not self-contained → supplementary: fail: download timeout | Independent / GuyTevet (none) |
| 8 | [WongKinYiu/yolov7](https://github.com/WongKinYiu/yolov7) | 54.0 | 16 min | 3 (6 lines) | fail: download timeout → supplementary: pass | Academia / Institute of Information Science, Academia Sinica (medium) |
| 9 | [microsoft/Bringing-Old-Photos-Back-to-Life](https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life) | 43.0 | 37 min | 2 (8 lines) | pass | Microsoft / Microsoft Research (high) |
| 10 | [advimman/lama](https://github.com/advimman/lama) | 39.0 | 21 min | 4 (57 lines) | pass | Samsung / Samsung AI Center (medium) |
| 11 | [IDEA-Research/GroundingDINO](https://github.com/IDEA-Research/GroundingDINO) | 32.4 | 48 min | 2 (5 lines) | fail: download timeout → supplementary: pass | IDEA / IDEA Research (high) |

## Companies (mean repo score)

| company | n | mean | teams |
|---|---|---|---|
| NVIDIA ⚠ n<3 | 1 | 77.1 | NVIDIA Research 77.1 (n=1) |
| Independent | 5 | 73.3 | academa-labs 94.1 (n=1); Leonxlnx 77.9 (n=1); jaredpalmer 69.1 (n=1); TianyuCodings 66.9 (n=1); GuyTevet 58.5 (n=1) |
| Academia ⚠ n<3 | 2 | 63.2 | Berkeley 72.4 (n=1); Institute of Information Science, Academia Sinica 54.0 (n=1) |
| Microsoft ⚠ n<3 | 1 | 43.0 | Microsoft Research 43.0 (n=1) |
| Samsung ⚠ n<3 | 1 | 39.0 | Samsung AI Center 39.0 (n=1) |
| IDEA ⚠ n<3 | 1 | 32.4 | IDEA Research 32.4 (n=1) |
