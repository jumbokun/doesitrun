# Reproducibility leaderboard

How hard is it to get a GitHub repo's README demo actually running? A sandboxed agent tries each repo; a hidden, pre-registered oracle decides success. Scores from different hardware are never mixed. Method: README.md; full notebook: WORKLOG.md.

## CPU · GitHub-hosted runner (4 vCPU, 16 GB) — 80 repos

| # | repo | score | agent | repo files patched | fresh-container replay | company / team (confidence) |
|---|---|---|---|---|---|---|
| 1 | [google-research/harness2](https://github.com/google-research/harness2) | 99.6 | 0 min | 0 (0 lines) | pass | Google / Google Research (high) |
| 2 | [google/yapf](https://github.com/google/yapf) | 99.6 | 0 min | 0 (0 lines) | pass | Google / Google (high) |
| 3 | [microsoft/SkillOpt](https://github.com/microsoft/SkillOpt) | 99.4 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 4 | [NVIDIA/garak](https://github.com/NVIDIA/garak) | 99.4 | 1 min | 0 (0 lines) | pass | NVIDIA / NVIDIA (high) |
| 5 | [microsoft/JARVIS](https://github.com/microsoft/JARVIS) | 99.3 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 6 | [facebookresearch/detr](https://github.com/facebookresearch/detr) | 99.1 | 1 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 7 | [microsoft/markitdown](https://github.com/microsoft/markitdown) | 98.9 | 1 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 8 | [google/adk-recipes](https://github.com/google/adk-recipes) | 98.7 | 1 min | 0 (0 lines) | pass | Google / Google (high) |
| 9 | [QwenLM/Qwen3](https://github.com/QwenLM/Qwen3) | 98.6 | 1 min | 0 (0 lines) | pass | Alibaba / Qwen (high) |
| 10 | [google/langextract](https://github.com/google/langextract) | 98.3 | 2 min | 0 (0 lines) | pass | Google / Google (high) |
| 11 | [microsoft/pyright](https://github.com/microsoft/pyright) | 98.3 | 2 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 12 | [microsoft/cascadia-code](https://github.com/microsoft/cascadia-code) | 98.2 | 2 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 13 | [facebookresearch/AnimatedDrawings](https://github.com/facebookresearch/AnimatedDrawings) | 98.1 | 2 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 14 | [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS) | 98.1 | 2 min | 0 (0 lines) | pass | Alibaba / Qwen (high) |
| 15 | [facebookresearch/demucs](https://github.com/facebookresearch/demucs) | 98.0 | 2 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 16 | [Tencent/AI-Infra-Guard](https://github.com/Tencent/AI-Infra-Guard) | 98.0 | 2 min | 0 (0 lines) | pass | Tencent / Tencent (high) |
| 17 | [TencentARC/GFPGAN](https://github.com/TencentARC/GFPGAN) | 98.0 | 2 min | 0 (0 lines) | pass | Tencent / ARC Lab (high) |
| 18 | [modelscope/ClearerVoice-Studio](https://github.com/modelscope/ClearerVoice-Studio) | 97.8 | 2 min | 0 (0 lines) | pass | Alibaba / ModelScope (high) |
| 19 | [facebookresearch/vggt](https://github.com/facebookresearch/vggt) | 97.4 | 3 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 20 | [google-deepmind/sonnet](https://github.com/google-deepmind/sonnet) | 97.3 | 3 min | 0 (0 lines) | pass | Google / Google DeepMind (high) |
| 21 | [microsoft/VibeVoice](https://github.com/microsoft/VibeVoice) | 96.8 | 3 min | 0 (0 lines) | pass | Microsoft / Microsoft (high) |
| 22 | [bytedance/MegaTTS3](https://github.com/bytedance/MegaTTS3) | 96.0 | 4 min | 0 (0 lines) | pass | ByteDance / ByteDance (high) |
| 23 | [modelscope/ms-swift](https://github.com/modelscope/ms-swift) | 95.8 | 4 min | 0 (0 lines) | pass | Alibaba / ModelScope (high) |
| 24 | [bytedance/piano_transcription](https://github.com/bytedance/piano_transcription) | 95.7 | 4 min | 0 (0 lines) | pass | ByteDance / ByteDance (high) |
| 25 | [modelscope/FunASR](https://github.com/modelscope/FunASR) | 95.5 | 4 min | 0 (0 lines) | pass | Alibaba / ModelScope (high) |
| 26 | [facebookresearch/fairseq](https://github.com/facebookresearch/fairseq) | 94.9 | 5 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 27 | [PaddlePaddle/models](https://github.com/PaddlePaddle/models) | 94.3 | 6 min | 0 (0 lines) | pass | Baidu / PaddlePaddle (high) |
| 28 | [facebookresearch/nougat](https://github.com/facebookresearch/nougat) | 94.1 | 6 min | 0 (0 lines) | pass | Meta / FAIR (high) |
| 29 | [PaddlePaddle/PaddleNLP](https://github.com/PaddlePaddle/PaddleNLP) | 93.9 | 6 min | 0 (0 lines) | pass | Baidu / PaddlePaddle (high) |
| 30 | [bytedance/GiantMIDI-Piano](https://github.com/bytedance/GiantMIDI-Piano) | 93.8 | 6 min | 0 (0 lines) | pass | ByteDance / ByteDance (high) |
| 31 | [PaddlePaddle/PaddleSeg](https://github.com/PaddlePaddle/PaddleSeg) | 93.7 | 6 min | 0 (0 lines) | pass | Baidu / PaddlePaddle (high) |
| 32 | [PaddlePaddle/PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | 92.8 | 7 min | 0 (0 lines) | pass | Baidu / PaddlePaddle (high) |
| 33 | [modelscope/DiffSynth-Studio](https://github.com/modelscope/DiffSynth-Studio) | 92.5 | 8 min | 0 (0 lines) | pass | Alibaba / ModelScope (high) |
| 34 | [QwenLM/Qwen](https://github.com/QwenLM/Qwen) | 92.1 | 8 min | 0 (0 lines) | pass | Alibaba / Qwen (high) |
| 35 | [PaddlePaddle/PaddleX](https://github.com/PaddlePaddle/PaddleX) | 89.6 | 10 min | 0 (0 lines) | pass | Baidu / PaddlePaddle (high) |
| 36 | [TencentARC/T2I-Adapter](https://github.com/TencentARC/T2I-Adapter) | 89.5 | 10 min | 0 (0 lines) | pass | Tencent / ARC Lab (high) |
| 37 | [NVlabs/stylegan3](https://github.com/NVlabs/stylegan3) | 88.5 | 2 min | 1 (2 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 38 | [NVlabs/Sana](https://github.com/NVlabs/Sana) | 88.1 | 12 min | 0 (0 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 39 | [baidu/Unlimited-OCR](https://github.com/baidu/Unlimited-OCR) | 87.6 | 12 min | 0 (0 lines) | pass | Baidu / Baidu (high) |
| 40 | [ByteDance-Seed/m3-agent](https://github.com/ByteDance-Seed/m3-agent) | 87.1 | 3 min | 1 (8 lines) | pass | ByteDance / Seed (high) |
| 41 | [microsoft/unilm](https://github.com/microsoft/unilm) | 86.2 | 4 min | 1 (11 lines) | pass | Microsoft / Microsoft (high) |
| 42 | [facebookresearch/detectron2](https://github.com/facebookresearch/detectron2) | 86.0 | 4 min | 1 (4 lines) | pass | Meta / FAIR (high) |
| 43 | [microsoft/qlib](https://github.com/microsoft/qlib) | 85.6 | 4 min | 1 (2 lines) | pass | Microsoft / Microsoft (high) |
| 44 | [modelscope/modelscope](https://github.com/modelscope/modelscope) | 83.9 | 6 min | 1 (3 lines) | pass | Alibaba / ModelScope (high) |
| 45 | [Tencent-Hunyuan/HY-World-2.0](https://github.com/Tencent-Hunyuan/HY-World-2.0) | 82.7 | 7 min | 1 (9 lines) | pass | Tencent / Hunyuan (high) |
| 46 | [QwenLM/Qwen-Agent](https://github.com/QwenLM/Qwen-Agent) | 82.0 | 8 min | 1 (68 lines) | pass | Alibaba / Qwen (high) |
| 47 | [google-deepmind/pysc2](https://github.com/google-deepmind/pysc2) | 80.3 | 10 min | 1 (1 lines) | pass | Google / Google DeepMind (high) |
| 48 | [microsoft/Swin-Transformer](https://github.com/microsoft/Swin-Transformer) | 76.8 | 3 min | 2 (43 lines) | pass | Microsoft / Microsoft (high) |
| 49 | [NVlabs/stylegan](https://github.com/NVlabs/stylegan) | 75.9 | 4 min | 2 (4 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 50 | [PaddlePaddle/PaddleDetection](https://github.com/PaddlePaddle/PaddleDetection) | 74.8 | 5 min | 2 (3 lines) | pass | Baidu / PaddlePaddle (high) |
| 51 | [Tencent/tencent-ml-images](https://github.com/Tencent/tencent-ml-images) | 74.4 | 6 min | 2 (0 lines) | pass | Tencent / Tencent (high) |
| 52 | [facebookresearch/Detectron](https://github.com/facebookresearch/Detectron) | 74.2 | 6 min | 2 (19 lines) | fail: other; replay_after_repair: pass | Meta / FAIR (high) |
| 53 | [Tencent-Hunyuan/Hunyuan3D-2](https://github.com/Tencent-Hunyuan/Hunyuan3D-2) | 73.0 | 17 min | 1 (2 lines) | pass | Tencent / Hunyuan (high) |
| 54 | [bytedance/Protenix](https://github.com/bytedance/Protenix) | 70.3 | 10 min | 2 (15 lines) | pass | ByteDance / ByteDance (high) |
| 55 | [NVIDIA/FastPhotoStyle](https://github.com/NVIDIA/FastPhotoStyle) | 68.0 | 2 min | 3 (13 lines) | fail: other; replay_after_repair: pass | NVIDIA / NVIDIA (high) |
| 56 | [PaddlePaddle/PaddleGAN](https://github.com/PaddlePaddle/PaddleGAN) | 65.5 | 24 min | 1 (18 lines) | pass | Baidu / PaddlePaddle (high) |
| 57 | [google-research/timesfm](https://github.com/google-research/timesfm) | 59.2 | 1 min | 4 (0 lines) | pass | Google / Google Research (high) |
| 58 | [Tencent/FaceDetection-DSFD](https://github.com/Tencent/FaceDetection-DSFD) | 55.8 | 4 min | 5 (65 lines) | pass | Tencent / Tencent (high) |
| 59 | [PaddlePaddle/PaddleFormers](https://github.com/PaddlePaddle/PaddleFormers) | 55.5 | 4 min | 4 (41 lines) | fail: other; replay_after_repair: pass | Baidu / PaddlePaddle (high) |
| 60 | [NVlabs/stylegan2](https://github.com/NVlabs/stylegan2) | 53.7 | 6 min | 5 (31 lines) | pass | NVIDIA / NVIDIA Research (high) |
| 61 | [bytedance/Sa2VA](https://github.com/bytedance/Sa2VA) | 40 | 79 min | 1 (39 lines) | pass | ByteDance / ByteDance (high) |
| 62 | [bytedance/LatentSync](https://github.com/bytedance/LatentSync) | 10 | 90 min | 5 (23 lines) | pass | ByteDance / ByteDance (high) |
| 63 | [bytedance/Dolphin](https://github.com/bytedance/Dolphin) | 0 | 90 min | 1 (5 lines) | fail: other | ByteDance / ByteDance (high) |
| 64 | [ByteDance-Seed/Depth-Anything-3](https://github.com/ByteDance-Seed/Depth-Anything-3) | 0 | 3 min | 1 (5 lines) | fail: other | ByteDance / Seed (high) |
| 65 | [google-research/bert](https://github.com/google-research/bert) | 0 | 3 min | 0 (0 lines) | fail: other | Google / Google Research (high) |
| 66 | [google/trax](https://github.com/google/trax) | 0 | 8 min | 1 (6 lines) | fail: other | Google / Google (high) |
| 67 | [modelscope/FunClip](https://github.com/modelscope/FunClip) | 0 | 14 min | 1 (5 lines) | fail: other | Alibaba / ModelScope (high) |
| 68 | [NVIDIA/Megatron-LM](https://github.com/NVIDIA/Megatron-LM) | 0 | 25 min | 0 (0 lines) | fail: other | NVIDIA / NVIDIA (high) |
| 69 | [NVlabs/SPADE](https://github.com/NVlabs/SPADE) | 0 | 10 min | 0 (0 lines) | fail: other | NVIDIA / NVIDIA Research (high) |
| 70 | [Tencent-Hunyuan/Hunyuan3D-1](https://github.com/Tencent-Hunyuan/Hunyuan3D-1) | 0 | 90 min | 4 (20 lines) | fail: other | Tencent / Hunyuan (high) |
| 71 | [Tencent-Hunyuan/Hunyuan3D-2.1](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1) | 0 | 90 min | 1 (10 lines) | fail: other | Tencent / Hunyuan (high) |
| 72 | [bytedance/UI-TARS](https://github.com/bytedance/UI-TARS) | not scored (oracle defect) | 1 min | 0 (0 lines) | fail: other | ByteDance / ByteDance (high) |
| 73 | [facebookresearch/ParlAI](https://github.com/facebookresearch/ParlAI) | not scored (oracle defect) | 2 min | 0 (0 lines) | fail: other | Meta / FAIR (high) |
| 74 | [facebookresearch/pytorch3d](https://github.com/facebookresearch/pytorch3d) | not scored (oracle defect) | 9 min | 0 (0 lines) | fail: other | Meta / FAIR (high) |
| 75 | [google/python-fire](https://github.com/google/python-fire) | not scored (oracle defect) | 0 min | 0 (0 lines) | fail: other | Google / Google (high) |
| 76 | [microsoft/data-formulator](https://github.com/microsoft/data-formulator) | not scored (oracle defect) | 2 min | 0 (0 lines) | fail: other | Microsoft / Microsoft (high) |
| 77 | [NVIDIA/SkillSpector](https://github.com/NVIDIA/SkillSpector) | not scored (oracle defect) | 1 min | 0 (0 lines) | fail: other | NVIDIA / NVIDIA (high) |
| 78 | [NVIDIA/warp](https://github.com/NVIDIA/warp) | not scored (oracle defect) | 1 min | 0 (0 lines) | fail: other | NVIDIA / NVIDIA (high) |
| 79 | [PaddlePaddle/PaddleSpeech](https://github.com/PaddlePaddle/PaddleSpeech) | not scored (oracle defect) | 17 min | 0 (0 lines) | fail: other | Baidu / PaddlePaddle (high) |
| 80 | [Tencent/PocketFlow](https://github.com/Tencent/PocketFlow) | not scored (oracle defect) | 88 min | 0 (0 lines) | fail: other | Tencent / Tencent (high) |

| company | n | mean | teams |
|---|---|---|---|
| Microsoft | 9 | 93.3 | Microsoft 93.3 (n=9) |
| Meta | 8 | 92.7 | FAIR 92.7 (n=8) |
| Alibaba | 10 | 83.6 | Qwen 92.7 (n=4); ModelScope 77.6 (n=6) |
| Baidu | 9 | 83.1 | Baidu 87.6 (n=1); PaddlePaddle 82.5 (n=8) |
| Google | 9 | 70.3 | Google DeepMind 88.8 (n=2); Google 74.2 (n=4); Google Research 52.9 (n=3) |
| Tencent | 9 | 63.5 | ARC Lab 93.8 (n=2); Tencent 76.1 (n=3); Hunyuan 38.9 (n=4) |
| NVIDIA | 8 | 59.2 | NVIDIA Research 61.2 (n=5); NVIDIA 55.8 (n=3) |
| ByteDance | 9 | 54.8 | ByteDance 58.0 (n=7); Seed 43.5 (n=2) |

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
| 9 | [microsoft/Bringing-Old-Photos-Back-to-Life](https://github.com/microsoft/Bringing-Old-Photos-Back-to-Life) | 43.0 | 37 min | 2 (8 lines) | pass | Microsoft / Microsoft (high) |
| 10 | [advimman/lama](https://github.com/advimman/lama) | 39.0 | 21 min | 4 (57 lines) | pass | Samsung / Samsung AI Center (medium) |
| 11 | [IDEA-Research/GroundingDINO](https://github.com/IDEA-Research/GroundingDINO) | 32.4 | 48 min | 2 (5 lines) | fail: download timeout; replay_supplementary: pass | IDEA / IDEA Research (high) |

| company | n | mean | teams |
|---|---|---|---|
| NVIDIA ⚠ n<3 | 1 | 77.1 | NVIDIA Research 77.1 (n=1) |
| Independent | 5 | 73.3 | academa-labs 94.1 (n=1); Leonxlnx 77.9 (n=1); jaredpalmer 69.1 (n=1); TianyuCodings 66.9 (n=1); GuyTevet 58.5 (n=1) |
| Academia ⚠ n<3 | 2 | 63.2 | Berkeley 72.4 (n=1); Institute of Information Science, Academia Sinica 54.0 (n=1) |
| Microsoft ⚠ n<3 | 1 | 43.0 | Microsoft 43.0 (n=1) |
| Samsung ⚠ n<3 | 1 | 39.0 | Samsung AI Center 39.0 (n=1) |
| IDEA ⚠ n<3 | 1 | 32.4 | IDEA Research 32.4 (n=1) |
