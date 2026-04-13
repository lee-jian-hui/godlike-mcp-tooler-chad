# Secrets Handling Rules

## Core Principle
**NEVER read secrets from files. Use environment variables only.**

## Specific Rules

### DO NOT
- ❌ Read `.env` files directly
- ❌ Log or display API keys, tokens, passwords
- ❌ Commit secrets to git
- ❌ Use hardcoded credentials in code
- ❌ Store credentials in files (except properly secured vaults)
- ❌ Display secrets in any output (Discord, logs, etc.)

### DO
- ✅ Use environment variables injected by orchestration
- ✅ Access secrets via `process.env` or similar
- ✅ If a secret is needed, request it via environment variable
- ✅ Use `.env.example` as template (never commit `.env`)
- ✅ Use secrets from mounted Kubernetes secrets
- ✅ Use the read_secrets skill for viewing masked secrets

## File Access Rules

| File Type | Access |
|-----------|--------|
| `.env` | ❌ NEVER read directly |
| `.pem`, `.key` | ❌ NEVER read |
| `*.pem`, `*.key` in configs | ❌ NEVER read |
| `.env.example` | ✅ OK (template only) |
| Environment variables | ✅ OK (use process.env) |

## Handling Secrets in Code

### JavaScript/Node.js
```javascript
// ✅ GOOD
const apiKey = process.env.API_KEY;

// ❌ BAD
const apiKey = require('./secrets.json').apiKey;
```

### Python
```python
# ✅ GOOD
import os
api_key = os.environ.get('API_KEY')

# ❌ BAD
with open('config.json') as f:
    api_key = json.load(f)['api_key']
```

### Shell
```bash
# ✅ GOOD
curl -H "Authorization: $API_KEY" ...

# ❌ BAD
curl -H "Authorization: $(cat secrets.txt)"
```

## If You Need a Secret

1. Check if it's available as an environment variable
2. If not, ask the user to provide it via environment variable
3. Do NOT try to read it from any file

## Breach Protocol

If you accidentally see or log a secret:
1. Do NOT use it or store it
2. Do NOT share it with anyone
3. Report it to the user immediately

## Reference

**Always use `skills/read_secrets.md`** - For safe env var checking (never read .env files directly)