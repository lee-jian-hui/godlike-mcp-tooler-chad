# Sandbox Architecture for Autonomous Coding Agent

## Goal

Run an autonomous coding agent (opencode) in a sandboxed Docker environment with:

- ✅ Ability to read/write files in workspace
- ✅ Execute code/scripts within the sandbox
- ✅ Web search for context/research
- ✅ Persist state (auth tokens, SQLite DB, session data)
- ❌ Cannot harm the host system
- ❌ Cannot access internal services
- ❌ Cannot escalate privileges

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Host System                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Autonomous Agent Container              │   │
│  │                                                       │   │
│  │   ┌─────────────┐    ┌─────────────────────────┐    │   │
│  │   │   opencode  │───▶│   Workspace (/workspace) │    │   │
│  │   │    Agent    │    └─────────────────────────┘    │   │
│  │   └─────────────┘              │                    │   │
│  │                               ▼                    │   │
│  │   ┌─────────────┐    ┌─────────────────────────┐    │   │
│  │   │   SQLite    │◀───│   State Volume          │    │   │
│  │   │  Database   │    │   (/app/data)           │    │   │
│  │   └─────────────┘    └─────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│              ┌─────────────────────────┐                    │
│              │   Network Proxy Layer   │                    │
│              │   (Squid/Tinyproxy)     │                    │
│              └─────────────────────────┘                    │
│                            │                                │
│                            ▼                                │
│                         Internet                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
/workspace/           # Agent working directory (bind mount from host)
  ├── src/            # Source code to work on
  ├── tests/          # Test files
  ├── scripts/        # Helper scripts
  └── output/         # Generated files

/app/data/            # Persistent data (Docker volume)
  ├── database.sqlite # Agent state DB
  ├── auth.json       # Auth tokens
  └── cache/          # Web search cache

/tmp/                 # Temporary files
```

---

## Docker Hardening Configuration

### Recommended Run Command

```bash
docker run -d \
  --name opencode-agent \
  --read-only \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --pids-limit=100 \
  --memory=1g \
  --cpus=2 \
  --user 1000:1000 \
  -v $(pwd)/workspace:/workspace \
  -v opencode_data:/app/data \
  -v /tmp:/tmp \
  -e WORKSPACE=/workspace \
  -e DB_PATH=/app/data/database.sqlite \
  -e HTTP_PROXY=http://proxy:3128 \
  -https_proxy=http://proxy:3128 \
  -e ALLOWED_DOMAINS="api.duckduckgo.com,serpapi.com,exa.ai" \
  opencode-agent:latest
```

### Security Settings Justification

| Flag | Purpose |
|------|---------|
| `--read-only` | Prevents filesystem modification outside /workspace, /tmp, /app/data |
| `--cap-drop=ALL` | Removes all Linux capabilities |
| `--security-opt no-new-privileges` | Blocks privilege escalation |
| `--pids-limit=100` | Prevents fork bombs |
| `--memory=1g` | Limits memory usage |
| `--cpus=2` | Limits CPU usage |
| `--user 1000:1000` | Non-root execution |

### Dangerous Flags to NEVER Use

- ❌ `--privileged`
- ❌ `-v /var/run/docker.sock:/var/run/docker.sock`
- ❌ `--network=host` (unless required)
- ❌ Hardcoded secrets in images

---

## Data Persistence

### SQLite Database

**Location:** `/app/data/database.sqlite`

**Purpose:**
- Session state
- Task history
- Conversation context
- Cached decisions

### Auth Tokens

**Location:** `/app/data/auth.json`

```json
{
  "tokens": {
    "refresh_token": "...",
    "expires_at": "2025-01-01T00:00:00Z"
  },
  "session_id": "..."
}
```

### Workspace

**Location:** `/workspace` (bind mount from host)

- Agent reads/writes files here
- Host controls what code exists
- Can be reset by removing and recreating the mount

---

## Network Security

### Proxy Configuration

Use a controlled proxy to filter outbound traffic:

```
Agent → Squid Proxy → Internet
```

### Allowed Domains (Whitelist)

```python
ALLOWED_DOMAINS = [
    "api.duckduckgo.com",    # DuckDuckGo API
    "serpapi.com",           # SerpAPI
    "exa.ai",                # Exa Code Search
    "api.github.com",        # GitHub API (if needed)
]
```

### Blocked Addresses

```
❌ 10.0.0.0/8        # Private networks
❌ 172.16.0.0/12    # Private networks
❌ 192.168.0.0/16   # Private networks
❌ 169.254.169.254  # Cloud metadata
❌ 127.0.0.1        # Localhost
❌ host.docker.internal  # Docker host
```

### Search Implementation

Use APIs instead of raw HTTP for web search:

- **DuckDuckGo Instant Answer API** - Free, no auth
- **SerpAPI** - Paid, structured results
- **Exa AI** - Code-focused search

This prevents arbitrary HTTP requests while enabling research capability.

---

## Application-Level Controls

### Agent Permissions

Inside the agent, enforce:

```python
PERMISSIONS = {
    "read_files": ["/workspace/**", "/app/data/**"],
    "write_files": ["/workspace/**", "/tmp/**"],
    "execute": ["/workspace/**/*.sh", "/usr/bin/*"],
    "network": ["api.duckduckgo.com", "serpapi.com", "exa.ai"],
}
```

### Disabled Capabilities

```python
DISABLED = [
    "arbitrary_shell_execution",  # Only whitelisted commands
    "direct_system_calls",        # Use abstractions
    "unrestricted_http",         # Only allowed domains
    "file_read_outside_workspace", # Prevent data theft
]
```

---

## Monitoring & Observability

### Log All Actions

```bash
# Log file locations
/var/log/agent/agent.log     # All agent actions
/var/log/agent/network.log  # Network requests
/var/log/agent/files.log    # File operations
```

### Metrics to Track

- File read/write operations
- Network requests (allowed/blocked)
- Command executions
- Session duration
- Errors and failures

---

## Quick Start

### 1. Create Workspace Directory

```bash
mkdir -p ~/opencode-workspace
```

### 2. Start Proxy (Optional)

```bash
docker run -d --name squid-proxy \
  -p 3128:3128 \
  sameersbn/squid:latest
```

### 3. Start Agent

```bash
docker run -d --name opencode-agent \
  --read-only \
  --cap-drop=ALL \
  --security-opt no-new-privileges \
  --pids-limit=100 \
  --memory=1g \
  --cpus=2 \
  --user 1000:1000 \
  -v ~/opencode-workspace:/workspace \
  -v opencode_data:/app/data \
  -v /tmp:/tmp \
  -e HTTP_PROXY=http://host.docker.internal:3128 \
  opencode-agent:latest
```

### 4. Execute Task

```bash
docker exec opencode-agent opencode --task "Fix bug in /workspace/src"
```

---

## TL;DR

1. **Lock down container** - No root, no caps, read-only FS
2. **Use volumes** - /workspace for code, /app/data for state
3. **Restrict network** - Proxy + whitelist only
4. **Monitor everything** - Log all operations
5. **Treat as untrusted** - Assume it will try to escape

