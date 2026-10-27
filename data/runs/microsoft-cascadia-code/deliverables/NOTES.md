# Cascadia Code build notes
README has no build instructions (they're in the wiki); followed requirements.txt + `python build.py -P -NF -M -I`.

- requirements.txt was pip-compiled for Python 3.11; system Python is 3.12, so created a 3.11 venv with `uv venv -p 3.11`.
- Build crashed with `ModuleNotFoundError: No module named 'pkg_resources'` (from `fs`, used by fontTools.ufoLib):
  modern venvs don't ship setuptools and setuptools>=81 drops pkg_resources. Fixed by installing `setuptools<81`.
- After that the build finished in ~15 s producing build/ttf/CascadiaCode.ttf (variable, wght axis, 4319 glyphs, GSUB/GPOS/GDEF/STAT).
