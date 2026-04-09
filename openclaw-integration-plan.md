# OpenClaw Integration Plan

## Overview

Run OpenClaw (orchestration) + OpenCode (inference) in a sandboxed local Kubernetes cluster with Discord as the messaging interface.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Local Kubernetes (minikube)                     │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ OpenClaw Pod                                                  │ │
│  │  ┌─────────────────┐    ┌─────────────────────────────────┐  │ │
│  │  │ OpenClaw        │    │     opencode/                     │  │ │
│  │  │ Gateway         │───▶│  ├─ coder.md (main agent)        │  │ │
│  │  │ (Discord bot)   │    │  └─ subagents/judge.md           │  │ │
│  │  └─────────────────┘    └─────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              ▼                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Workspace Volume (HostPath)                                     │ │
│  │  openclaw-assets/workspace                                     │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              ▼                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Proxy Pod (Squid)                                              │ │
│  │  Network filtering                                            │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
         │
         Discord User
```

---

## Component Roles

| Component | Role |
|-----------|------|
| **OpenClaw Gateway** | Discord bot, message handling, session management |
| **OpenCode (coder)** | Code inference, tool execution |
| **Judge Subagent** | Validates dangerous actions before execution |
| **Squid Proxy** | Network filtering for safety |
| **Workspace PV** | Persistent storage for code files |

---

## Sandbox Strategy (4 Layers)

### Layer 1: Container Security
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

### Layer 2: Kubernetes Pod Security
```yaml
securityContext:
  runAsNonRoot: true
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### Layer 3: Network Policy
- Egress only through Squid proxy (port 3128)
- Block internal IPs (10.x, 172.16.x, 192.168.x)
- Allow only HTTPS (443) for external API calls

### Layer 4: Judge Subagent
- All destructive commands validated before execution
- Rules defined in `configs/.opencode/subagents/judge.md`

---

## Implementation Steps

### Step 1: Create Discord Bot
See: `discord/bot-setup.md`

### Step 2: Set Up Minikube
```bash
# Start minikube with sufficient resources
minikube start --cpus=4 --memory=8g --disk-size=20g

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### Step 3: Deploy OpenClaw
```bash
kubectl apply -f k8s/
```

### Step 4: Configure Discord
1. Invite bot to server
2. Bot joins designated channel
3. Send `/opencode` to start session

---

## File Structure

```
.
├── openclaw-integration-plan.md    # This file
├── k8s/
│   ├── openclaw-deployment.yaml    # Main deployment
│   ├── openclaw-service.yaml       # ClusterIP service
│   ├── workspace-pv.yaml           # HostPath volume
│   ├── configmap.yaml              # Config files
│   ├── network-policy.yaml         # Network restrictions
│   └── squid-deployment.yaml       # Proxy
├── configs/
│   ├── openclaw.json               # OpenClaw config (Discord + ACP)
│   ├── opencode-coder.json         # Coder agent config
│   ├── opencode-judge.json        # Judge agent config
│   └── squid.conf                  # Proxy config
├── discord/
│   └── bot-setup.md                # Discord bot setup guide
└── openclaw-assets/
    └── workspace/                  # Bind mount for code
```

---

## Configuration Details

### OpenClaw (configs/openclaw.json)
- Discord bot token from environment
- ACP enabled for OpenCode integration
- Model: configured via OpenCode

### OpenCode Coder (configs/opencode-coder.json)
- Model: `opencode/minimax-m2.5-free`
- Tools: read, write, edit, bash, task
- Permissions scoped to workspace

### OpenCode Judge (configs/opencode-judge.json)
- Model: `opencode/minimax-m2.5-free`
- Tools: read-only (no bash, write, edit)
- Safety rules from judge.md

### Judge Safety Rules
- **ALWAYS DENY**: Internal IPs, cloud metadata, destructive commands
- **REQUIRES APPROVAL**: kubectl delete, docker rm, helm uninstall, DROP DATABASE

---

## Discord Channel Setup

### Dedicated Channel Creation
1. Create a new channel: `#opencode-agent`
2. Set channel permissions:
   - Bot: Read Messages, Send Messages
   - Users: Read Messages (optional)
3. (Optional) Create separate channels:
   - `#opencode-logs` - For execution logs
   - `#opencode-sandbox` - For isolated testing

### Bot Commands
- `/opencode` - Start new session
- `/opencode task <description>` - Run task
- `/opencode stop` - End session
- `/opencode status` - Check status

---

## Storage

### Workspace Location
```
openclaw-assets/
├── workspace/           # Main code workspace
│   ├── src/
│   ├── tests/
│   └── README.md
├── data/                # OpenClaw data (SQLite)
│   ├── database.sqlite
│   └── sessions/
└── cache/               # Cache files
```

---

## Verification Checklist

- [ ] Discord bot created and token saved
- [ ] Minikube started with 4 CPU, 8GB RAM
- [ ] OpenClaw pod running
- [ ] Squid proxy pod running
- [ ] Network policy applied
- [ ] Workspace volume mounted
- [ ] Bot responds to /opencode command
- [ ] Judge validation works for dangerous commands
- [ ] Files persist after pod restart

---

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod openclaw-0
kubectl logs openclaw-0
```

### Bot not responding
```bash
kubectl logs openclaw-0 | grep -i discord
```

### Network issues
```bash
kubectl exec -it squid-0 -- tail -f /var/log/squid/access.log
```

### Workspace not persisting
```bash
kubectl describe pv openclaw-workspace
```
