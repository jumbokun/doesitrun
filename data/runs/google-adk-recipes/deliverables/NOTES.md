# Notes: ambient-expense-agent

Following the README (uv sync, then `python expense_agent/fast_api_app.py`) mostly worked as written:
google-adk 2.8.0 installed on Python 3.12, the server listened on :8080, and the $45 trigger came back
with HTTP 200 `{"status":"success"}` (auto-approved, no LLM call).

What broke or was missing:
- **README curl doesn't work on Linux:** `$(... | base64)` uses GNU base64, which wraps its output at
  76 chars. That puts a newline inside the JSON string, and the server returns 422 "Invalid control
  character". I used `base64 -w0` instead.
- **Credentials:** a `.env` (or env vars) with `GOOGLE_API_KEY=dummy` and `MODEL_NAME=gemini-3.5-flash`
  is needed. Without GOOGLE_API_KEY, config.py calls `google.auth.default()` and crashes on startup.
  The README only shows a real key. MODEL_NAME is only listed in .env.example.
- **Not using `make`:** I ran `uv sync --python 3.12` and the python command directly instead of
  `make install`/`make dev`. They do the same thing.
