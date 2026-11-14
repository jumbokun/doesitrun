# AutoGen setup notes

- Followed the README: `pip install -U "autogen-agentchat" "autogen-ext[openai]"` (it installed 0.7.5), run inside a uv venv at /work/venv using Python 3.12. Ubuntu 24.04 marks the system Python as externally managed (PEP 668), so a venv is needed. The README doesn't mention this.
- Core quickstart (Modifier/Checker on SingleThreadedAgentRuntime, wrapped in `asyncio.run`) works as written. It counts down from 10 and ends with "1 failed the check, stopping."
- README Hello World works with no API key once `OpenAIChatCompletionClient` is swapped for `autogen_ext.models.replay.ReplayChatCompletionClient(['Hello World!'])`. The final message is "Hello World!".
- No code patches or version pins were needed.
- `env.sh` activates /work/venv.
