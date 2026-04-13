# Read Secrets Skill

## Purpose
Check what secrets/environment variables are available without exposing actual values.

## Rules

### NEVER do:
- ❌ Read `.env` files directly
- ❌ Display API keys, tokens, or passwords
- ❌ Log secret values in any output

### ALWAYS do:
- ✅ Use environment variables (injected by orchestration)
- ✅ Show ONLY env var NAMES, never values
- ✅ Read `.env.example` for templates (not `.env`)

## How to Check Environment Variables

### Preferred: Use redact-secrets.sh script:
```bash
# In container:
redact-secrets.sh
```

This outputs (redacted):
```
=== Environment Variables (Redacted) ===
DISCORD_BOT_TOKEN=••••••••••••••••••••••••••••••••••••••
OPENCODE_API_KEY=••••••••••••••••••••••••••••••••••••••
GIT_WORKSPACE_TOKEN=••••••••••••••••••••••••••••••••••••••OrU
```

### Alternative: Show env var names only (masked):
```bash
# In container:
env | grep -E "^[A-Z_]+=" | cut -d= -f1 | sort
```

This outputs:
```
DISCORD_APPLICATION_ID
DISCORD_BOT_TOKEN
GIT_WORKSPACE_TOKEN
OPENCODE_API_KEY
...
```

### Check if specific provider is configured:
```bash
env | grep -E "^(OPENCODE|MINIMAX|ANTHROPIC|OPENAI)_" | cut -d= -f1
```

### Show what's set without values:
```bash
env | awk -F= '{print $1}' | sort
```

## If You Need a Secret Value

1. **Don't read it** - the user will provide it via environment
2. **Ask the user**: "Please provide the value as an environment variable"
3. **Don't assume** - verify it's set before using

## Alternative: Docker Exec

To check from outside the container:
```bash
docker exec openclaw env | grep -E "^[A-Z_]+=" | cut -d= -f1 | sort
```

This shows env var names only - safe to display.

## Example Output (safe to show)

```
Configured environment variables:
- DISCORD_BOT_TOKEN
- OPENCODE_API_KEY
- GIT_WORKSPACE_TOKEN
- MINIMAX_API_KEY
```

## Example Output (unsafe - DON'T show)

```
DISCORD_BOT_TOKEN=MTQ5MTY5NTk0Nzk2NzYzMTM2MA...
OPENCODE_API_KEY=sk-abc123...
```