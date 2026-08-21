---
name: codex-connection-doctor
description: Use when Codex Desktop or CLI repeatedly reconnects, reaches 5/5 retries, hangs, falls back from WebSocket, or logs 10054, unexpected EOF, stream disconnected, or websocket closed before response.completed.
---

# Codex Connection Doctor

Use the bundled repair script for the known failure pattern. Keep the interaction short and explain that it changes only `~/.codex/config.toml`.

## Automatic repair

Run:

```powershell
& "<skill-folder>\scripts\repair_codex_connection.ps1"
```

The script acts only when today's Desktop logs contain a known reconnect signal. It backs up the config, selects a custom HTTPS provider with WebSocket disabled, runs `codex doctor`, and restores the original config if verification fails.

If the user supplied current reconnect evidence but the local text log is unavailable, rerun with `-Force`. Do not use `-SkipDoctor` outside isolated tests.

After `RESULT=repaired`, ask the user to restart Codex Desktop and try one normal task. Do not claim the Desktop issue is fixed until that test succeeds without reconnecting.

## Boundaries

- Never change `auth.json`, delete tasks or databases, clear caches, or add removed feature flags such as `responses_websockets`.
- If an existing `openai-http` provider differs from the safe preset, stop instead of overwriting it.
- Never upload real configs, backups, logs, databases, tokens, or diagnostic dumps.
- Treat cache-summary errors separately; this Skill is only for connection interruption symptoms.
