# OpenClaw Integration Plan (Docker-Based)

## Overview

Run OpenClaw (orchestration) + Podman (infra container spawning) in a sandboxed Docker container with Discord as the messaging interface.

**Updated**: Switched from Kubernetes to Docker for simpler local development.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Docker Container (Sandboxed)                    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  openclaw-container                                           │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────────┐  │ │
│  │  │ OpenClaw        │    │     .opencode/                  │  │ │
│  │  │ Gateway         │───▶│  ├─ agents/coder.md            │  │ │
│  │  │ (Discord bot)   │    │  └─ subagents/judge.md        │  │ │
│  │  └─────────────────┘    └─────────────────────────────────┘  │ │
│  │          │                                                     │ │
│  │          ▼                                                     │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────────┐  │ │
│  │  │ Podman          │    │     /workspace                   │  │ │
│  │  │ (infra runner)  │    │     (code from git)              │  │ │
│  │  └─────────────────┘    └─────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              ▼                                       │
│                     Docker Volume (ephemeral)                       │
└─────────────────────────────────────────────────────────────────────┘
          │
          │ Network
          ▼
     Discord User
```

---

## Component Roles

| Component | Role |
|-----------|------|
| **Docker Container** | Sandboxed environment, not root |
| **OpenClaw Gateway** | Discord bot, message handling, session management |
| **Podman** | Run infra containers (Airflow, Kafka) inside container |
| **Judge Subagent** | Validates dangerous actions before execution |
| **/workspace** | Ephemeral storage, code from git |

---

## Sandbox Strategy (4 Layers)

### Layer 1: Container Security
```yaml
# docker-compose.yml
user: "node"  # Non-root user (UID 1000)
read_only: false  # Workspace needs to be writable
```

### Layer 2: Resource Limits
```yaml
deploy:
  resources:
    limits:
      memory: 4G
      pids: 100
```

### Layer 3: No Host Access
- No Docker socket mounted from host
- No HostPath volumes (using Docker volumes)
- Container runs isolated

### Layer 4: Judge Subagent
- All destructive commands validated before execution
- Rules defined in `.opencode/subagents/judge.md`

---

## Implementation Steps

### Step 1: Create Discord Bot
See: `discord/bot-setup.md`

### Step 2: Configure Environment
```bash
# Copy and edit .env file
cp .env.example .env
# Add your Discord bot token
```

### Step 3: Build & Run
```bash
# Build the image
docker build -t openclaw:local .

# Run the container
docker run -d --name openclaw openclaw:local

# Or with docker-compose
docker-compose up -d
```

### Step 4: Verify
```bash
# Check container is running
docker ps

# Check OpenClaw is installed
docker exec openclaw openclaw --version

# Check Podman is available
docker exec openclaw podman --version
```

---

## File Structure

```
.
├── openclaw-integration-plan.md    # This file
├── Dockerfile                       # Container image definition
├── docker-compose.yml               # Container orchestration
├── .env.example                     # Environment template
├── .env                             # Your secrets (gitignored)
├── .dockerignore                    # Build exclusions
├── scripts/
│   └── entrypoint.sh               # Startup script (git clone)
├── .opencode/
│   ├── opencode.json               # OpenCode config
│   ├── agents/
│   │   └── coder.md                # Coder agent prompt
│   └── subagents/
│       └── judge.md                # Judge subagent safety rules
└── discord/
    └── bot-setup.md                # Discord bot setup guide
```

---

## Configuration Details

### Environment Variables (.env)
```
DISCORD_BOT_TOKEN=your_bot_token
DISCORD_APPLICATION_ID=your_app_id
OPENCLAW_GATEWAY_TOKEN=secret-token
OPENCODE_MODEL=opencode/minimax-m2.5-free

# Optional: Git clone at startup
GIT_REPO_URL=https://github.com/username/repo.git
GIT_USERNAME=your-username
GIT_EMAIL=your-email@example.com
```

### OpenCode Config (`.opencode/opencode.json`)
- Model: `opencode/minimax-m2.5-free`
- Tools: read, write, edit, bash, task
- Permissions scoped to workspace

### Judge Safety Rules
- **ALWAYS DENY**: Internal IPs (10.x, 172.16.x, 192.168.x), cloud metadata (169.254.169.254)
- **REQUIRES APPROVAL**: podman delete, rm -rf, DROP DATABASE

---

## Discord Channel Setup

### Dedicated Channel Creation
1. Create a new channel: `#opencode-agent`
2. Set channel permissions:
   - Bot: Read Messages, Send Messages
   - Users: Read Messages (optional)

### Bot Commands
- `/opencode` - Start new session
- `/opencode task <description>` - Run task
- `/opencode stop` - End session

---

## Podman (Infra Container Spawning)

The container has Podman installed to spawn infra containers:

```bash
# Inside the container:
podman run -d airflow
podman run -d kafka
podman ps  # List running containers
```

This is **Docker-in-Docker without privileged mode** using Podman's rootless capabilities.

---

## Quick Start

```bash
# 1. Setup
cp .env.example .env
# Edit .env with your Discord bot token

# 2. Build
docker build -t openclaw:local .

# 3. Run
docker run -d --name openclaw \
  --env-file .env \
  openclaw:local

# 4. Check logs
docker logs -f openclaw
```

---

## Verification Checklist

- [x] Dockerfile builds successfully
- [x] OpenClaw installed in container
- [x] Podman installed in container
- [ ] Container runs with restart policy
- [ ] Discord bot connects
- [ ] Git clone works at startup
- [ ] Judge validation works for dangerous commands

---

## Troubleshooting

### Container not starting
```bash
docker logs openclaw
docker exec openclaw sh
```

### Discord bot not connecting
```bash
docker exec openclaw openclaw gateway start
```

### Podman not working inside container
```bash
docker exec openclaw podman info
```

---

## Why Docker Instead of Kubernetes

| Aspect | Docker | Kubernetes |
|--------|--------|------------|
| Complexity | Low | High |
| Resources | Lightweight | Heavy (VM) |
| Setup time | Minutes | Hours |
| Restart handling | docker-compose | K8s native |
| Host coupling | Low (container only) | High (minikube on host) |

For local development, Docker is simpler and achieves the same sandboxing goals.