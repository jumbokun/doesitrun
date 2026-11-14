# gluonts setup notes
- Installed from the clone (`/work/gluonts`, version 0.18.0.dev0) into a uv venv at /work/venv running Python 3.12 (`uv pip install "/work/gluonts[torch]" matplotlib`).
- Before that, I installed torch from the PyTorch CPU wheel index. Otherwise pip pulls the default CUDA build, which is several GB and useless here because the machine has no GPU.
- matplotlib isn't part of `gluonts[torch]`, but the README example imports it, so I installed it separately.
- The README calls `plt.show()`. On a headless machine, env.sh sets `MPLBACKEND=Agg` and you save the plot with `plt.savefig`.
- No code changes were needed. The README example with `freq="M"`, run as written, trains and produces 3 forecasts of 12 steps each (torch only prints deprecation warnings).
