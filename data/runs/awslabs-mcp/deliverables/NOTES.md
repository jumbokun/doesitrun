# aws-documentation-mcp-server setup notes

The README only documents running the server via `uvx awslabs.aws-documentation-mcp-server@latest`, which installs from PyPI and not from the local checkout. To install from source I did this instead:

- `uv python install 3.13` (the package's `.python-version` pins 3.13; `uv sync` swaps the venv's interpreter for that one anyway)
- `UV_PROJECT_ENVIRONMENT=/work/venv uv sync --frozen --no-dev` inside `src/aws-documentation-mcp-server`, which installs the locked deps and the package into `/work/venv`
- `env.sh` adds `/work/venv/bin` to PATH and sets `FASTMCP_LOG_LEVEL=ERROR` and `AWS_DOCUMENTATION_PARTITION=aws`, the values the README's config examples use.

I didn't need any code patches or dependency pins. I tested it with an MCP stdio client: tools list, read_documentation (Lambda welcome page as markdown) and search_documentation (docs.aws.amazon.com results) all worked.
Note: the locked mcp is 2.x, where the client result field is `is_error`, not `isError`.
