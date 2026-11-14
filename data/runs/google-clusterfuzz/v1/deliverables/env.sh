# Source this file: activates the ClusterFuzz Python 3.11 venv (with nodeenv-installed node/bower).
export VIRTUAL_ENV_DISABLE_PROMPT=1
source /work/venv/bin/activate
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
export PIPENV_VERBOSITY=-1
cd /work/clusterfuzz
