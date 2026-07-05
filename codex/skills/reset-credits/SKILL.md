---
name: reset-credits
description: Verify Codex banked rate-limit reset credits and expiration dates. Use this skill whenever the user asks "/reset-credits", asks to check reset credits, banked resets, Codex reset-credit expirations, or wants to know how many banked Codex rate-limit resets remain.
---

# Reset Credits

Use this skill to check the user's Codex banked rate-limit reset credits from the ChatGPT backend.

## Workflow

1. Run the bundled script:

   ```bash
   node <skill-dir>/scripts/check-reset-credits.mjs
   ```

2. Report the sanitized output exactly enough to answer:
   - available banked reset count
   - each credit's `granted_at`
   - each credit's `expires_at`
   - each expiration converted to the user's local timezone

3. If the script fails, report the endpoint status and sanitized error. Do not print tokens, cookies, raw auth JSON, or full HTML responses.

## Safety Notes

- The script only calls the read-only endpoint:
  `GET https://chatgpt.com/backend-api/codex/rate-limit-reset-credits`
- Never call `.../consume` unless the user explicitly asks to redeem a banked reset.
- Treat `~/.codex/auth.json` as sensitive. Inspect shape if needed, but never echo auth values.
- If network access is sandboxed and the script fails with DNS or fetch errors, retry the same script with escalated network permissions.

## Expected Output

Summarize in this shape:

```text
Available banked resets: N

1. Granted: ...
   Expires UTC: ...
   Expires local: ...
```

Keep the response concise unless the user asks for raw sanitized JSON.
