set -e
source /work/env.sh
cd /work/mcp
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/client.py <<'PY'
import asyncio, json, shutil, sys, os
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
out = sys.argv[1]
env = dict(os.environ, FASTMCP_LOG_LEVEL="ERROR", AWS_DOCUMENTATION_PARTITION="aws")
if shutil.which("awslabs.aws-documentation-mcp-server"):   # pyproject.toml:38-39 console script
    params = StdioServerParameters(command="awslabs.aws-documentation-mcp-server", args=[], env=env)
else:
    params = StdioServerParameters(command=sys.executable, args=["-m", "awslabs.aws_documentation_mcp_server.server"], env=env)
def text(r): return "\n".join(c.text for c in r.content if hasattr(c, "text"))
# field names differ across mcp SDK majors (isError / is_error, structuredContent / structured_content)
def is_err(r): return bool(getattr(r, "isError", None) or getattr(r, "is_error", None))
def structured(r): return getattr(r, "structuredContent", None) or getattr(r, "structured_content", None)
async def main():
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            names = {t.name for t in (await s.list_tools()).tools}
            print("tools:", names)
            assert {"read_documentation", "search_documentation"} <= names, names

            url = "https://docs.aws.amazon.com/lambda/latest/dg/welcome.html"
            res = await s.call_tool("read_documentation", {"url": url, "max_length": 5000})
            t = text(res)
            open(out + "/doc.txt", "w").write(t)
            print(t[:300])
            # fetch errors come back as isError (server_utils.py fetch_markdown raises DocumentationToolError)
            assert not is_err(res), t[:500]
            # v1 checked `"lambda" in text`, which the tool's own header line always satisfies
            # ("AWS Documentation from <url>:", util.py:281). Check the page body instead.
            body = t.split("\n", 1)[1] if t.startswith("AWS Documentation from") else t
            assert len(body) > 1000, len(body)
            assert body.lower().count("lambda") >= 5, "Lambda page body missing"
            assert "<html" not in body.lower(), "page was not converted to markdown"

            # README "Search Documentation" feature (global partition): search_documentation
            res = await s.call_tool("search_documentation", {"search_phrase": "AWS Lambda function URL", "limit": 5})
            st = text(res)
            open(out + "/search.txt", "w").write(st)
            assert not is_err(res), st[:500]
            data = structured(res) or json.loads(st)
            if "result" in data and "search_results" not in data:   # FastMCP may wrap non-dict returns
                data = data["result"]
            results = data["search_results"]
            urls = [x.get("url", "") for x in results]
            print("search:", urls)
            # server_aws.py:498-515 reports search failures as one result with url='' and an Error title
            assert any(u.startswith("https://docs.aws.amazon.com/") for u in urls), results[:2]
            assert not any((x.get("title") or "").startswith("Error") for x in results), results[:2]
asyncio.run(main())
PY
timeout 600 python $OUT/client.py $OUT
test -s $OUT/doc.txt
echo "ORACLE PASS"
