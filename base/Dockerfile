# Sandbox base for probe runs. Deliberately thin: the agent must figure out
# Python versions, system packages and CUDA wheels itself — that is what we measure.
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        git git-lfs curl ca-certificates build-essential python3 python3-venv python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

WORKDIR /work
CMD ["sleep", "infinity"]
