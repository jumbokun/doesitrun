# coremltools on Linux x86 CPU

README says `pip install coremltools`. That works, but it doesn't mention version limits that matter here:
- coremltools 9.0 (the latest stable on PyPI; the repo is at 9.1.dev1) supports torch up to 2.8.0 (`_TORCH_MAX_VERSION`). I pinned torch==2.7.1 and used the CPU-only wheel from download.pytorch.org.
- scikit-learn is capped at 1.5.1 (`_SKLEARN_MAX_VERSION`). With a newer sklearn, coremltools quietly turns off the sklearn converter. I pinned scikit-learn==1.5.1.
- Python 3.12 venv made with uv; pinned numpy<2.3.
- The "Failed to load _MLModelProxy / libcoremlpython" warnings are expected on Linux: prediction is macOS-only. Converting and saving work.

Checked: a traced conv+linear model converts with ct.convert(convert_to='mlprogram') and TensorType 'x', saves as .mlpackage and reloads. A sklearn LinearRegression converts and saves as .mlmodel.
