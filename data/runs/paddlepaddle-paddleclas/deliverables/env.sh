# Source me: activates the PaddleClas venv
. /work/venv/bin/activate
# Don't put cwd/script dir on sys.path: otherwise running python from /work/PaddleClas
# imports the repo-root paddleclas.py as a top-level module instead of the installed package.
export PYTHONSAFEPATH=1
