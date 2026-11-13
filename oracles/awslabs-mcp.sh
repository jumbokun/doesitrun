set -e
source /work/env.sh
cd /work/mcp
OUT=$(mktemp -d /tmp/oracle.XXXXXX)
cat > $OUT/client.py <<'PY'
import asyncio, shutil, sys, os
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
if shutil.which("awslabs.aws-documentation-mcp-server"):
    params = StdioServerParameters(command="awslabs.aws-documentation-mcp-server", args=[], env=dict(os.environ, FASTMCP_LOG_LEVEL="ERROR"))
else:
    params = StdioServerParameters(command=sys.executable, args=["-m","awslabs.aws_documentation_mcp_server.server"], env=dict(os.environ, FASTMCP_LOG_LEVEL="ERROR"))
def text(r): return "\n".join(c.text for c in r.content if hasattr(c,"text"))
async def main():
    async with stdio_client(params) as (r,w):
        async with ClientSession(r,w) as s:
            await s.initialize()
            names = {t.name for t in (await s.list_tools()).tools}
            print("tools:", names)
            assert "read_documentation" in names and "search_documentation" in names
            res = await s.call_tool("read_documentation", {"url":"https://docs.aws.amazon.com/lambda/latest/dg/welcome.html","max_length":5000})
            t = text(res)
            open(sys.argv[1]+"/doc.txt","w").write(t)
            print(t[:300])
            assert len(t) > 500 and "lambda" in t.lower(), "doc content missing"
asyncio.run(main())
PY
timeout 600 python $OUT/client.py $OUT
test -s $OUT/doc.txt
echo "ORACLE PASS"
