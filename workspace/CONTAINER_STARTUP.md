# OpenClaw Container Startup Guide

## Debugging and Startup Steps

### Prerequisites

1. Podman machine running:
   ```bash
   podman machine start
   ```

2. `.env` file with required variables:
   - `DISCORD_BOT_TOKEN`
   - `DISCORD_APPLICATION_ID`
   - `OPENCODE_API_KEY`
   - `GIT_WORKSPACE_URL` (optional)
   - `GIT_WORKSPACE_TOKEN` (optional for private repos)

### Build the Image

```bash
podman compose build
```

### Start the Container

```bash
podman compose up -d
```

### Check Container Status

```bash
podman ps
```

### Check Logs

```bash
podman logs openclaw
podman logs openclaw --tail 50
```

### Access Container Shell (for debugging)

```bash
podman exec -it openclaw bash
```

### Stop the Container

```bash
podman compose down
```

### Restart the Container

```bash
podman compose down && podman compose up -d
```

---

## Gateway Access

- **Gateway URL:** http://localhost:18789
- **Health check:** http://localhost:18789/health
- **Canvas:** http://localhost:18789/__openclaw__/canvas/

---

## Troubleshooting

### Container not starting

Check logs:
```bash
podman logs openclaw
```

### Podman connection issues

Ensure Podman machine is running:
```bash
podman machine list
podman machine start
```

### Plugin initialization failures

Check plugin logs:
```bash
podman logs openclaw 2>&1 | grep -i "plugin"
```

### Health check failing

Check if gateway is ready:
```bash
curl http://localhost:18789/health
```

---

## Container Structure

- **Image:** `openclaw:local` (built from Dockerfile)
- **Container name:** `openclaw`
- **Working dir:** `/workspace`
- **OpenClaw workspace:** `/home/node/.openclaw/workspace/`
- **Data volume:** `openclaw-data` mounted at `/data`

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DISCORD_BOT_TOKEN` | Yes | Discord bot token |
| `DISCORD_APPLICATION_ID` | Yes | Discord application ID |
| `OPENCODE_API_KEY` | Yes | OpenCode API key |
| `OPENCLAW_GATEWAY_TOKEN` | No | Gateway token (default: opencode-agent-secret-token) |
| `GIT_WORKSPACE_URL` | No | Workspace repo URL |
| `GIT_WORKSPACE_TOKEN` | No | GitHub token for workspace |

---

## Dockerfile Fix for Plugin Permissions

The original issue was that plugins with runtime dependencies (like `discord`, `browser`, `amazon-bedrock`) couldn't install their npm dependencies because `/usr/local/lib/node_modules/` was owned by root while the container runs as non-root user `node`.

**Fix applied to Dockerfile:**

```dockerfile
# Install OpenClaw globally (as root, then switch to node user)
RUN npm install -g openclaw

# Pre-install runtime dependencies for plugins that need them (as root)
RUN npm install -g @openclaw/discord @openclaw/browser @openclaw/amazon-bedrock @openclaw/amazon-bedrock-mantle @openclaw/microsoft @openclaw/acpx @openclaw/validation 2>/dev/null || true

# Allow node user to write to global node_modules for plugin runtime dependency installation
RUN chown -R node:node /usr/local/lib/node_modules /usr/local/bin

# Switch to non-root user after npm install
USER node
```

---

## Last Updated

- Date: 2026-04-22
- Container ID: See `podman ps`
- Gateway: http://localhost:18789