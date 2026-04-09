# OpenCode Agent Configuration

## Overview

This file defines the autonomous opencode agent behavior, permissions, and execution model.

---

## Agent Identity

- **Name**: opencode-autonomous
- **Mode**: Autonomous (no human intervention)
- **Max Session Duration**: 30 minutes
- **Max Iterations**: 50

---

## Working Directory

```
/workspace/          # Primary working directory (bind mount)
```

### Directory Structure

```
/workspace/
├── README.md           # Task specification (provided by user)
├── src/                # Source code to modify
├── tests/              # Test files
├── scripts/             # Helper scripts
├── docs/               # Documentation
└── output/             # Generated artifacts
```

---

## Available Tools

### File Operations (Unrestricted within /workspace)

- **read**: Read any file in /workspace
- **write**: Write/create files in /workspace
- **edit**: Modify existing files in /workspace
- **glob**: Find files by pattern in /workspace
- **grep**: Search content in /workspace

### Execution

- **bash**: Execute shell commands
  - Allowed: `npm`, `python`, `node`, `git`, `cargo`, `go`, `make`, `./scripts/*`
  - Blocked: `rm -rf /`, `dd`, `mkfs`, `:(){ :|:& };:`

### Network

- **websearch**: Search web for context
- **webfetch**: Fetch URLs (only allowed domains)
- **codesearch**: Search code documentation

### Allowed Domains

```
api.duckduckgo.com
serpapi.com
exa.ai
api.github.com
docs.github.com
```

---

## Execution Rules

### Before Executing Any Task

1. Read `/workspace/README.md` for task specification
2. Explore workspace structure: `ls -la /workspace`
3. Understand codebase before making changes

### During Task Execution

1. **Read first** - Understand existing code before modifying
2. **Verify changes** - Run tests/linters after modifications
3. **Atomic commits** - Group related changes
4. **Handle errors** - Don't ignore failures

### Task Completion

1. Run lint/typecheck if available
2. Verify tests pass
3. Summarize changes made

---

## Prohibited Actions

### File System

- ❌ Read files outside /workspace, /tmp, /app/data
- ❌ Write to system directories (/etc, /var, /usr)
- ❌ Delete files outside /workspace/output

### Network

- ❌ Access blocked IP ranges (10.x, 172.16.x, 192.168.x)
- ❌ Access localhost or host.docker.internal
- ❌ Make requests outside allowed domains

### Execution

- ❌ Execute interactive prompts (use -y flags)
- ❌ Run commands requiring sudo/root
- ❌ Long-running processes (timeout after 60s)

---

## Persistence

### State Location

```
/app/data/
├── database.sqlite    # Agent state
├── auth.json          # Auth tokens
└── cache/             # Web search cache
```

### State Management

- Save state after each significant operation
- Load previous context on startup
- Resume interrupted tasks gracefully

---

## Example Usage

### Start Autonomous Task

```bash
docker exec opencode-agent opencode \
  --task "Add user authentication to the app" \
  --workspace /workspace
```

### Continuous Mode

```bash
docker exec opencode-agent opencode --continuous
```

---

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WORKSPACE` | Working directory | `/workspace` |
| `DB_PATH` | SQLite database path | `/app/data/database.sqlite` |
| `HTTP_PROXY` | Proxy for outbound requests | none |
| `ALLOWED_DOMAINS` | Comma-separated allowed domains | api.duckduckgo.com |
| `MAX_ITERATIONS` | Max agent iterations | 50 |
| `TIMEOUT_SECONDS` | Task timeout | 1800 |

## Secrets Management

### ⚠️ NEVER read from .env files

Secrets should NEVER be read from `.env` files. Use these methods instead:

1. **Kubernetes Secrets** - For K8s deployments
2. **Environment variables** - Set by the orchestrator (not from .env)
3. **External secrets operators** - For enterprise setups

### Kubernetes Secret Injection

```yaml
# k8s/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: openclaw-secrets
  namespace: openclaw
type: Opaque
stringData:
  discord-bot-token: ${DISCORD_BOT_TOKEN}
  discord-application-id: ${DISCORD_APPLICATION_ID}
```

### Service-Specific .env Files

| Service | Secrets File | Injected Via |
|---------|--------------|--------------|
| OpenClaw Gateway | `secrets/openclaw.env` | K8s Secret → Env var |
| OpenCode (coder) | `secrets/opencode-coder.env` | ConfigMap |
| OpenCode (judge) | `secrets/opencode-judge.env` | ConfigMap |
| Squid Proxy | `secrets/squid.env` | ConfigMap |

Each service reads only its own environment file injected by Kubernetes.

