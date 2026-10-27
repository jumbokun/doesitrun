# Reproducibility leaderboard

How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent tries each repo; a hidden, pre-registered oracle decides success. Scores from different hardware are never mixed. Method: README.md; full notebook: WORKLOG.md.

## CPU · GitHub-hosted runner (4 vCPU, 16 GB) — 35 repos

| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |
|---|---|---|---|---|---|---|
| 1 | [google-research/harness2](https://github.com/google-research/harness2) | 99.6 | 0 min | 0 (0 lines) | pass | Google / Google Research (high) |
| 2 | [google/yapf](https://github.com/google/yapf) | 99.6 | 0 min | 0 (0 lines) | pass | Google / Google (high) |
| 3 | [microsoft/SkillOpt](https://github.com/microsoft/SkillOpt) | 99.4 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft Research (high) |
| 4 | [microsoft/JARVIS](https://github.com/microsoft/JARVIS) | 99.3 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 5 | [facebookresearch/detr](https://github.com/facebookresearch/detr) | 99.1 | 1 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 6 | [microsoft/markitdown](https://github.com/microsoft/markitdown) | 98.9 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 7 | [google/adk-recipes](https://github.com/google/adk-recipes) | 98.7 | 1 min | 0 (0 lines) | pass | Google / Google (high) |
| 8 | [google/langextract](https://github.com/google/langextract) | 98.3 | 2 min | 0 (0 lines) | pass | Google / Google (high) |
| 9 | [microsoft/pyright](https://github.com/microsoft/pyright) | 98.3 | 2 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 10 | [microsoft/cascadia-code](https://github.com/microsoft/cascadia-code) | 98.2 | 2 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 11 | [facebookresearch/AnimatedDrawings](https://github.com/facebookresearch/AnimatedDrawings) | 98.1 | 2 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 12 | [facebookresearch/demucs](https://github.com/facebookresearch/demucs) | 98.0 | 2 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 13 | [Tencent/AI-Infra-Guard](https://github.com/Tencent/AI-Infra-Guard) | 98.0 | 2 min | 0 (0 lines) | pass | Tencent / Tencent (high) |
| 14 | [TencentARC/GFPGAN](https://github.com/TencentARC/GFPGAN) | 98.0 | 2 min | 0 (0 lines) | pass | Tencent / ARC Lab (high) |
| 15 | [facebookresearch/vggt](https://github.com/facebookresearch/vggt) | 97.4 | 3 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 16 | [google-deepmind/sonnet](https://github.com/google-deepmind/sonnet) | 97.3 | 3 min | 0 (0 lines) | pass | Google / Google DeepMind (high) |
| 17 | [microsoft/VibeVoice](https://github.com/microsoft/VibeVoice) | 96.8 | 3 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 18 | [facebookresearch/fairseq](https://github.com/facebookresearch/fairseq) | 94.9 | 5 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 19 | [facebookresearch/nougat](https://github.com/facebookresearch/nougat) | 94.1 | 6 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 20 | [microsoft/unilm](https://github.com/microsoft/unilm) | 86.2 | 4 min | 1 (11 lines) | pass | Microsoft / Microsoft (high) |
| 21 | [facebookresearch/detectron2](https://github.com/facebookresearch/detectron2) | 86.0 | 4 min | 1 (4 lines) | pass | Meta / FAIR (high) |
| 22 | [microsoft/qlib](https://github.com/microsoft/qlib) | 85.6 | 4 min | 1 (2 lines) | pass | Microsoft / Microsoft (high) |
| 23 | [google-deepmind/pysc2](https://github.com/google-deepmind/pysc2) | 80.3 | 10 min | 1 (1 lines) | pass | Google / Google DeepMind (high) |
| 24 | [microsoft/Swin-Transformer](https://github.com/microsoft/Swin-Transformer) | 76.8 | 3 min | 2 (43 lines) | pass | Microsoft / Microsoft (high) |
| 25 | [facebookresearch/Detectron](https://github.com/facebookresearch/Detectron) | 74.2 | 6 min | 2 (19 lines) | fail: other; replay_after_repair: pass | Meta / FAIR (high) |
| 26 | [Tencent-Hunyuan/Hunyuan3D-2](https://github.com/Tencent-Hunyuan/Hunyuan3D-2) | 73.0 | 17 min | 1 (2 lines) | pass | Tencent / Hunyuan (high) |
| 27 | [ByteDance-Seed/Depth-Anything-3](https://github.com/ByteDance-Seed/Depth-Anything-3) | 0 | 3 min | 1 (5 lines) | fail: other | ByteDance / Seed (high) |
| 28 | [bytedance/UI-TARS](https://github.com/bytedance/UI-TARS) | 0 | 1 min | 0 (0 lines) | fail: other | ByteDance / ByteDance (high) |
| 29 | [google-research/bert](https://github.com/google-research/bert) | 0 | 3 min | 0 (0 lines) | fail: other | Google / Google Research (high) |
| 30 | [google/trax](https://github.com/google/trax) | 0 | 8 min | 1 (6 lines) | fail: other | Google / Google Research (high) |
| 31 | [facebookresearch/ParlAI](https://github.com/facebookresearch/ParlAI) | not scored (oracle defect) | 2 min | 0 (0 lines) | fail: other | Meta / FAIR (high) |
| 32 | [facebookresearch/pytorch3d](https://github.com/facebookresearch/pytorch3d) | not scored (oracle defect) | 9 min | 0 (0 lines) | fail: other | Meta / FAIR (high) |
| 33 | [google/python-fire](https://github.com/google/python-fire) | not scored (oracle defect) | 0 min | 0 (0 lines) | fail: other | Google / Google (high) |
| 34 | [google-research/timesfm](https://github.com/google-research/timesfm) | not scored (oracle defect) | 1 min | 4 (0 lines) | pass | Google / Google Research (high) |
| 35 | [microsoft/data-formulator](https://github.com/microsoft/data-formulator) | not scored (oracle defect) | 2 min | 0 (0 lines) | fail: other | Microsoft / Microsoft Research (high) |

| company | n | mean | teams |
|---|---|---|---|
| Microsoft | 9 | 93.3 | Microsoft Research 99.4 (n=1); Microsoft 92.5 (n=8) |
| Meta | 8 | 92.7 | FAIR 92.7 (n=8) |
| Tencent | 3 | 89.7 | Tencent 98.0 (n=1); ARC Lab 98.0 (n=1); Hunyuan 73.0 (n=1) |
| Google | 8 | 71.7 | Google 98.9 (n=3); Google DeepMind 88.8 (n=2); Google Research 33.2 (n=3) |
| ByteDance ⚠ n<3 | 2 | 0 | Seed 0 (n=1); ByteDance 0 (n=1) |

## GPU · RTX 5060 Laptop 8 GB — 11 repos

| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |
|---|---|---|---|---|---|---|
| 1 | [academa-labs/manimgx](https://github.com/academa-labs/manimgx) | 94.1 | 6 min | 0 (0 lines) | pass | Independent / academa-labs (none) |
| 2 | [Leonxlnx/earshot](https://github.com/Leonxlnx/earshot) | 77.9 | 22 min | 0 (0 lines) | pass | Independent / Leonxlnx (none) |
| 3 | [NVlabs/stylegan2-ada-pytorch](https://github.com/NVlabs/stylegan2-ada-pytorch) | 77.1 | 23 min | 0 (0 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 4 | [Friedrich-M/UniMate](https://github.com/Friedrich-M/UniMate) | 72.4 | 28 min | 0 (0 lines) | pass | Academia / Berkeley (low) |
| 5 | [jaredpalmer/kev](https://github.com/jaredpalmer/kev) | 69.1 | 31 min | 0 (0 lines) | pass | Independent / jaredpalmer (none) |
| 6 | [TianyuCodings/NanoJev](https://github.com/TianyuCodings/NanoJev) | 66.9 | 33 min | 0 (0 lines) | pass | Independent / TianyuCodings (none) |
| 7 | [GuyTevet/motion-diffusion-model](https://github.com/GuyTevet/motion-diffusion-model) | 58.5 | 32 min | 1 (5 lines) | fail: installer not self-contained; replay_supplementary: fail: download timeout; replay_after_repair: pass | Independent / GuyTevet (none) |
| 8 | [WongKinYiu/yolov7](https://github.com/WongKinYiu/yolov7) | 54.0 | 16 min | 3 (6 lines) | fail: download timeout; replay_supplementary: pass | Academia / Institute of Information Science, Academia Sinica (medium) |
| 9 | [microsoft/Bringing-Old-Photos-Back-to-Life](https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life) | 43.0 | 37 min | 2 (8 lines) | pass | Microsoft / Microsoft Research (high) |
| 10 | [advimman/lama](https://github.com/advimman/lama) | 39.0 | 21 min | 4 (57 lines) | pass | Samsung / Samsung AI Center (medium) |
| 11 | [IDEA-Research/GroundingDINO](https://github.com/IDEA-Research/GroundingDINO) | 32.4 | 48 min | 2 (5 lines) | fail: download timeout; replay_supplementary: pass | IDEA / IDEA Research (high) |

| company | n | mean | teams |
|---|---|---|---|
| NVIDIA ⚠ n<3 | 1 | 77.1 | NVIDIA Research 77.1 (n=1) |
| Independent | 5 | 73.3 | academa-labs 94.1 (n=1); Leonxlnx 77.9 (n=1); jaredpalmer 69.1 (n=1); TianyuCodings 66.9 (n=1); GuyTevet 58.5 (n=1) |
| Academia ⚠ n<3 | 2 | 63.2 | Berkeley 72.4 (n=1); Institute of Information Science, Academia Sinica 54.0 (n=1) |
| Microsoft ⚠ n<3 | 1 | 43.0 | Microsoft Research 43.0 (n=1) |
| Samsung ⚠ n<3 | 1 | 39.0 | Samsung AI Center 39.0 (n=1) |
| IDEA ⚠ n<3 | 1 | 32.4 | IDEA Research 32.4 (n=1) |
