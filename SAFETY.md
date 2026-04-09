# Safety & Sandbox Configuration - Quick Reference

This document maps all safety/sandbox settings to their configuration locations.

---

## 1. Docker Container Hardening

**File:** `docker-compose.yml`
**Purpose:** Container-level security (isolation, resource limits)

| Setting | Value | Purpose |
|---------|-------|---------|
| `--cap-drop=ALL` | All caps dropped | No Linux capabilities |
| `--security-opt no-new-privileges` | Enabled | Blocks privilege escalation |
| `--pids-limit=100` | 100 processes | Prevents fork bombs |
| `--memory=1g` | 1GB RAM | Resource limits |
| `--cpus: 2` | 2 CPUs | CPU limits |
| `--user 1000:1000` | Non-root | Not running as root |
| `--read-only` | Filesystem read-only | Prevents FS modification |

---

## 2. Agent Tool Permissions (OpenCode Level)

**File:** `.opencode/opencode.json`
**Purpose:** Control what tools the agent can use and where

```json
{
  "permission": {
    "bash": {
      "workspace/*": "allow",   // Only in workspace
      "*": "ask"                 // Everything else requires approval
    },
    "write": {
      "workspace/*": "allow",    // Only in workspace
      "*": "deny"                // Everything else denied
    },
    "read": {
      "workspace/**": "allow",   // Only workspace + opencode
      ".opencode/**": "allow"
    }
  }
}
```

---

## 3. Agent Definition & Tool Access

**File:** `.opencode/opencode.json`
**Purpose:** Define which tools each agent can access

```json
{
  "agent": {
    "coder": {
      "tools": {
        "read": true,
        "write": true,
        "edit": true,
        "bash": true,
        "task": true
      }
    },
    "judge": {
      "tools": {
        "read": true,
        "write": false,
        "edit": false,
        "bash": false,
        "task": false
      }
    }
  }
}
```

---

## 4. Judge Subagent Safety Rules

**File:** `.opencode/subagents/judge.md`
**Purpose:** Define what actions are approved/denied

### Always DENY:
- Internal IPs: `10.x`, `172.16.x`, `192.168.x`, `127.0.0.1`
- Cloud metadata: `169.254.169.254`
- Destructive: `rm -rf /`, `dd`, fork bombs
- Database: `DROP DATABASE`, `DROP TABLE`

### Requires Approval:
- `kubectl delete` (cluster changes)
- `docker system prune`, `docker rmi`
- `helm uninstall`
- Network to internal services

---

## 5. Coder Agent Safety Workflow

**File:** `.opencode/agents/coder.md`
**Purpose:** Instructs main agent to consult judge before risky actions

Key instruction:
```
Before executing any command that could be destructive or access 
sensitive resources, you MUST call the judge subagent using 
the Task tool.
```

---

## 6. Network Proxy / Domain Whitelist

**File:** `squid.conf`
**Purpose:** Filter outbound network traffic

### Allowed Domains:
- `api.duckduckgo.com`
- `serpapi.com`
- `exa.ai`
- `api.github.com`

### Blocked Networks:
- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`
- `169.254.169.254`

---

## Configuration Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    DOCKER COMPOSE                           │
│  (container hardening, network isolation, resources)       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                .opencode/opencode.json                      │
│  (tool permissions, agent definitions, subagent config)     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              .opencode/subagents/judge.md                   │
│  (action validation rules)                                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              .opencode/agents/coder.md                      │
│  (agent instructions, when to call judge)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Start Checklist

- [ ] Docker hardening: Check `docker-compose.yml`
- [ ] Tool permissions: Check `.opencode/opencode.json` → `permission`
- [ ] Agent tools: Check `.opencode/opencode.json` → `agent.coder.tools`
- [ ] Judge rules: Check `.opencode/subagents/judge.md`
- [ ] Coder workflow: Check `.opencode/agents/coder.md`
- [ ] Network filtering: Check `squid.conf`
