# Read Secrets Skill

This skill reads secrets from environment variables and outputs masked values.

## Triggers

- User asks to read secrets
- User mentions "secrets", "env vars", "API keys"

## Actions

1. List all environment variables that match secret patterns
2. Mask sensitive values (show first 5 and last 5 characters)
3. Output formatted list of secrets

## Output Format

```
=== Secrets Found ===

OPENCODE_API_KEY: sk-qrWqd*****trGxE*****
DISCORD_BOT_TOKEN: MTQ5M*****uo
```

## Security

- Never output full secret values
- Always mask with asterisks
- Only show first 5 and last 5 characters

## Notes

- Only reads variables that contain: API_KEY, TOKEN, SECRET, PASSWORD
- Excludes PATH, HOME, SHELL, USER variables