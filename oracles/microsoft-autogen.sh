set -e
source /work/env.sh
cd /work/autogen
O=$(mktemp -d /tmp/oracle.XXXXXX)
# Run from a fresh dir so nothing in the clone shadows the installed packages.
cd $O
# (1) Core quickstart, verbatim agent logic from python/docs/src/user-guide/core-user-guide/quickstart.ipynb
#     (Modifier / Checker counting down from 10 on SingleThreadedAgentRuntime; no model, no API key).
cat > core_quickstart.py <<'PY'
import asyncio
from dataclasses import dataclass
from typing import Callable

from autogen_core import (AgentId, DefaultTopicId, MessageContext, RoutedAgent, SingleThreadedAgentRuntime,
                          default_subscription, message_handler)


@dataclass
class Message:
    content: int


@default_subscription
class Modifier(RoutedAgent):
    def __init__(self, modify_val: Callable[[int], int]) -> None:
        super().__init__("A modifier agent.")
        self._modify_val = modify_val

    @message_handler
    async def handle_message(self, message: Message, ctx: MessageContext) -> None:
        val = self._modify_val(message.content)
        print(f"{'-'*80}\nModifier:\nModified {message.content} to {val}")
        await self.publish_message(Message(content=val), DefaultTopicId())  # type: ignore


@default_subscription
class Checker(RoutedAgent):
    def __init__(self, run_until: Callable[[int], bool]) -> None:
        super().__init__("A checker agent.")
        self._run_until = run_until

    @message_handler
    async def handle_message(self, message: Message, ctx: MessageContext) -> None:
        if not self._run_until(message.content):
            print(f"{'-'*80}\nChecker:\n{message.content} passed the check, continue.")
            await self.publish_message(Message(content=message.content), DefaultTopicId())
        else:
            print(f"{'-'*80}\nChecker:\n{message.content} failed the check, stopping.")


async def main() -> None:
    runtime = SingleThreadedAgentRuntime()
    await Modifier.register(runtime, "modifier", lambda: Modifier(modify_val=lambda x: x - 1))
    await Checker.register(runtime, "checker", lambda: Checker(run_until=lambda x: x <= 1))
    runtime.start()
    await runtime.send_message(Message(10), AgentId("checker", "default"))
    await runtime.stop_when_idle()

asyncio.run(main())
PY
timeout 300 python -I core_quickstart.py > core.txt 2>&1 || { cat core.txt; exit 1; }
cat core.txt
# Expected trace per the notebook output: 10..2 pass, Modifier 10->9 ... 2->1, then 1 fails and stops.
[ "$(grep -c '^Modified [0-9]* to [0-9]*$' core.txt)" = 9 ]
grep -qx 'Modified 2 to 1' core.txt
grep -qx '2 passed the check, continue.' core.txt
grep -qx '1 failed the check, stopping.' core.txt
# (2) README "Hello World" (README.md:53-68) with the model client swapped for the documented offline
#     ReplayChatCompletionClient (autogen_ext/models/replay/_replay_chat_completion_client.py docstring),
#     so AssistantAgent.run() executes end to end without an OpenAI key.
cat > hello_replay.py <<'PY'
import asyncio
from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.replay import ReplayChatCompletionClient

async def main() -> None:
    model_client = ReplayChatCompletionClient(["Hello World!"])
    agent = AssistantAgent("assistant", model_client=model_client)
    result = await agent.run(task="Say 'Hello World!'")
    print(result)
    msgs = result.messages
    assert len(msgs) >= 1, msgs
    # agents/_base_chat_agent.py:126-153: last message is the agent's chat_message
    assert msgs[-1].source == "assistant" and msgs[-1].content == "Hello World!", msgs[-1]
    await model_client.close()
    print("HELLO_OK")

asyncio.run(main())
PY
timeout 300 python -I hello_replay.py > hello.txt 2>&1 || { cat hello.txt; exit 1; }
tail -5 hello.txt
grep -qx 'HELLO_OK' hello.txt
echo "ORACLE PASS"
