# OpenCode Autonomous Agent - TODO

## Phase 1: Core Infrastructure (Priority: High)

- [ ] Verify docker-compose stack starts successfully
- [ ] Test agent can execute basic commands
- [ ] Confirm network filtering blocks disallowed domains
- [ ] Verify workspace bind mount works correctly

## Phase 2: Subagent Architecture - Judge Pattern (Priority: High)

- [ ] Create `.opencode/` directory structure
- [ ] Define main agent (executor) with full tools
- [ ] Define judge subagent for action validation
- [ ] Configure in `opencode.json`
- [ ] Implement approval/denial workflow

## Phase 3: Judge Subagent Implementation (Priority: High)

- [ ] Create judge prompt with safety rules
- [ ] Define blocked actions (destructive, privileged)
- [ ] Add requires-approval action patterns:
  - `kubectl delete *`
  - `docker rmi`, `docker stop`
  - `helm uninstall`
  - `DROP DATABASE`
  - Network to internal IPs
- [ ] Configure task_budget for judge calls
- [ ] Add model routing (use paranoid model for judge)

## Phase 4: Local K8s Integration (Priority: High)

- [ ] Install kubectl, kind, helm in container
- [ ] Add Airflow deployment config
- [ ] Add Kafka + Zookeeper deployment config
- [ ] Add Redis + Postgres deployment config
- [ ] Create data pipeline templates

## Phase 5: Tool-Level Permissions (Priority: Medium)

- [ ] Restrict main agent tools via opencode.json
- [ ] Add prohibited action patterns
- [ ] Implement timeout handling

## Phase 6: Persistence & State (Priority: Medium)

- [ ] Implement SQLite state database schema
- [ ] Add auth token persistence
- [ ] Add task history storage
- [ ] Test state survives container restart

## Phase 7: Monitoring & Observability (Priority: Low)

- [ ] Add action logging (file ops, network, commands)
- [ ] Add Prometheus metrics endpoint
- [ ] Add error alerting

## Phase 8: Advanced Features (Priority: Low)

- [ ] Add multi-judge voting (require 2/3 approval)
- [ ] Add code review/approval workflow
- [ ] Add self-healing for failed tasks

---

## Architecture: Judge Pattern

```
┌─────────────────────────────────────────────────────┐
│              Main Agent (Executor)                  │
│  - Read/Write workspace                             │
│  - Bash (within workspace)                          │
│  - Web search                                        │
│  - Task (calls judge)                                │
└─────────────────────────────────────────────────────┘
                         │
                         │ "Can I delete this pod?"
                         ▼
┌─────────────────────────────────────────────────────┐
│              Judge Subagent                          │
│  - Read-only analysis                               │
│  - Returns: APPROVED/DENIED + reasoning            │
│  - Uses paranoid model                              │
└─────────────────────────────────────────────────────┘
                         │
                         │ "APPROVED: Safe to delete test pod"
                         ▼
┌─────────────────────────────────────────────────────┐
│              Main Agent (Executes)                  │
└─────────────────────────────────────────────────────┘
```

## Judge Safety Rules

### Always DENY:
- Access to internal infrastructure (10.x, 172.16.x, 192.168.x)
- Cloud metadata endpoints (169.254.169.254)
- Deleting production databases
- Modifying security policies

### Requires APPROVAL:
- Any `kubectl delete`
- Any `docker rmi` / `docker system prune`
- Any `helm uninstall`
- Creating external network connections
- Modifying cluster-wide resources

### Always ALLOW:
- Read operations
- Web search
- Reading kubeconfig
- Listing pods/services (read-only)

---

## Research Complete

- **Container separation**: Not needed with judge pattern - main agent executes, judge validates
- **Tool-level restrictions**: Configured in opencode.json per-agent
