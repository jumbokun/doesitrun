# aws-documentation-mcp-server setup

README only documents running the published package via `uvx awslabs.aws-documentation-mcp-server@latest`;
it has no instructions for installing from the source tree. Nothing broke.

What I did:
- `uv sync --frozen --no-dev` inside `src/aws-documentation-mcp-server` with `UV_PROJECT_ENVIRONMENT=/work/venv`
  (Python 3.12 via uv), so the local source + locked deps are installed in /work/venv.
- `env.sh` puts /work/venv/bin on PATH and sets FASTMCP_LOG_LEVEL=ERROR, AWS_DOCUMENTATION_PARTITION=aws (from README config).

Verified with an MCP stdio client: tools include read_documentation and search_documentation; read_documentation on
the Lambda welcome page returns markdown ("# What is AWS Lambda? ...").
