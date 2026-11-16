#!/usr/bin/env bash
# literal: awslabs/mcp @ 2ed7f904ae146f5d8bc8e775cbdf69d95e8484ef
# readme: README.md (+ src/aws-documentation-mcp-server/README.md)
set -e  # glue strict mode
uv python install 3.10  # src/aws-documentation-mcp-server/README.md:L21
# mismatch the README installs nothing into the venv: it only shows an MCP client config running uvx awslabs.aws-documentation-mcp-server@latest (L36); the test needs the command or module in the env.sh environment
