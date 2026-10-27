# qlib LightGBM Alpha158 – setup notes

Following the README's "Install from source" path (Python 3.12 venv; `pip install numpy cython`, then `pip install .`):

1. **`pip install .` failed** because `Python.h` was missing. qlib builds Cython extensions (`qlib/data/_libs/rolling.cpp`),
   and the stock Ubuntu 24.04 image doesn't include the Python headers. Fix: `apt-get install python3-dev`.
   (The README only hints at this as a conda/"missing header files" note.)
2. `python scripts/get_data.py qlib_data --target_dir ~/.qlib/qlib_data/cn_data --region cn` worked as written,
   despite the README warning that the official dataset is disabled. It gave Yahoo-based CN data up to 2020-09-25.
3. The task allowed lowering `num_threads` in `examples/benchmarks/LightGBM/workflow_config_lightgbm_Alpha158.yaml`
   from 20 to 4 (4-CPU box). I made no code patches.
4. The clone is pinned to commit 54355232 so the setup is reproducible.

Result: `qrun examples/benchmarks/LightGBM/workflow_config_lightgbm_Alpha158.yaml` takes about 80 s on CPU. It gives
IC≈0.0468, Rank IC≈0.049, and an annualized excess return with cost of ≈8.1%. Artifacts go to `./mlruns/...`
(`sig_analysis/ic.pkl`, `portfolio_analysis/report_normal_1day.pkl`, ...).

Files: `setup.sh` (apt python3-dev, clone, venv in /work/venv, install, data download), `env.sh` (activates venv, cd /work/qlib).
