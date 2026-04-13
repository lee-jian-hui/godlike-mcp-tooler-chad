#!/bin/bash
set -e

echo "=== OpenClaw Container Startup ==="

# ============================================================================
# AGENT REPO SETUP (This repo - for OpenClaw configs)
# ============================================================================

# Setup git config for agent repo
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_EMAIL" ]; then
    echo "Configuring git for agent repo..."
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
fi

# ============================================================================
# WORKSPACE SETUP (Separate project repo - for the actual project)
# ============================================================================

cd /workspace

# Clone workspace repository if GIT_WORKSPACE_URL is provided
if [ -n "$GIT_WORKSPACE_URL" ]; then
    echo "Cloning workspace repository..."
    
    # Check if workspace already has a git repo (from previous clone)
    if [ -d "/workspace/.git" ]; then
        echo "Workspace repo exists, pulling latest..."
        cd /workspace
        git fetch origin
        git reset --hard origin/main || true
    else
        # Workspace has files from Docker build (configs, .opencode)
        # Move them to temp location
        mkdir -p /tmp/openclaw-configs
        [ -d /workspace/configs ] && mv /workspace/configs /tmp/openclaw-configs/
        [ -d /workspace/.opencode ] && mv /workspace/.opencode /tmp/openclaw-configs/
        
        # Clean workspace for clone
        cd /workspace
        rm -rf * .git 2>/dev/null || true
        
# Clone workspace repo with auth
        echo "Cloning $GIT_WORKSPACE_URL..."
        CLONE_SUCCESS=false
        if [ -n "$GIT_WORKSPACE_TOKEN" ]; then
            # Clone with token for auth
            git clone "https://${GIT_WORKSPACE_USERNAME}:${GIT_WORKSPACE_TOKEN}@$(echo $GIT_WORKSPACE_URL | sed 's|https://||')" . 2>/dev/null && CLONE_SUCCESS=true
        else
            git clone "$GIT_WORKSPACE_URL" . 2>/dev/null && CLONE_SUCCESS=true
        fi
        
        if [ "$CLONE_SUCCESS" = "false" ]; then
            echo "Warning: Could not clone workspace repo (may be empty), using existing files"
        fi
        
        # Restore OpenClaw config files if clone failed or repo is empty
        [ -d /tmp/openclaw-configs/configs ] && mv /tmp/openclaw-configs/configs /workspace/
        [ -d /tmp/openclaw-configs/.opencode ] && mv /tmp/openclaw-configs/.opencode /workspace/
        rm -rf /tmp/openclaw-configs 2>/dev/null || true
        
        # If workspace is empty after clone, restore agent repo files
        if [ "$(ls -A /workspace 2>/dev/null | wc -l)" -lt "2" ]; then
            echo "Warning: Workspace repo appears empty, restoring from agent repo"
            [ -d /workspace/configs ] || mv /tmp/openclaw-configs/configs /workspace/ 2>/dev/null || true
            [ -d /workspace/.opencode ] || mv /tmp/openclaw-configs/.opencode /workspace/ 2>/dev/null || true
        fi
    fi
    
    # Configure git for workspace repo commits (only if git directory exists)
    if [ -d "/workspace/.git" ] && [ -n "$GIT_WORKSPACE_USERNAME" ] && [ -n "$GIT_WORKSPACE_TOKEN" ]; then
        echo "Configuring git for workspace repo..."
        git config user.name "$GIT_WORKSPACE_USERNAME"
        git config user.email "${GIT_WORKSPACE_EMAIL:-github-actions@users.noreply.github.com}"
        
        # Configure git to use token for authentication
        git remote set-url origin "https://${GIT_WORKSPACE_USERNAME}:${GIT_WORKSPACE_TOKEN}@$(echo $GIT_WORKSPACE_URL | sed 's|https://||')"
        
        # Set git to auto-commit
        git config --global push.default simple
    fi
fi

# ============================================================================
# WORKSPACE INITIALIZATION
# ============================================================================

# Create workspace directories
echo "Setting up workspace directories..."
mkdir -p /workspace/todos /workspace/memory /workspace/skills /workspace/mcp-tools /workspace/src

# Copy .env.example template to .env if not exists
if [ -f "/workspace/.env.example" ] && [ ! -f "/workspace/.env" ]; then
    echo "Creating .env from template (edit with actual values)..."
    cp /workspace/.env.example /workspace/.env
fi

# Copy DIRECTIVE.md template if not exists
if [ ! -f "/workspace/DIRECTIVE.md" ] && [ -f "/workspace/configs/DIRECTIVE.md" ]; then
    echo "Copying DIRECTIVE.md template..."
    cp /workspace/configs/DIRECTIVE.md /workspace/DIRECTIVE.md
fi

# Copy MEMORY.md template if not exists
if [ ! -f "/workspace/MEMORY.md" ] && [ -f "/workspace/configs/MEMORY.md" ]; then
    echo "Copying MEMORY.md template..."
    cp /workspace/configs/MEMORY.md /workspace/MEMORY.md
fi

# ============================================================================
# OPENCLAW CONFIGURATION
# ============================================================================

# Copy .opencode config if exists in workspace
if [ -d "/workspace/.opencode" ]; then
    echo "Using .opencode config from workspace..."
fi

# Copy OpenClaw config
if [ -f "/workspace/configs/openclaw.json" ]; then
    echo "Using OpenClaw config from workspace..."
    mkdir -p /home/node/.openclaw
    cp /workspace/configs/openclaw.json /home/node/.openclaw/openclaw.json
fi

# Use OpenClaw's default workspace (no symlink)
# OpenClaw will create its files in /home/node/.openclaw/workspace/

# Copy project files to OpenClaw's workspace at startup
echo "Copying project files to OpenClaw workspace..."
mkdir -p /home/node/.openclaw/workspace
# Copy everything EXCEPT .git (don't copy git repo - agent uses /workspace for git)
for item in /workspace/*; do
    [ "$(basename "$item")" = ".git" ] && continue
    cp -r "$item" /home/node/.openclaw/workspace/ 2>/dev/null || true
done

if [ -n "$DISCORD_BOT_TOKEN" ]; then
    echo "Configuring Discord channel..."
    mkdir -p /home/node/.openclaw
    cat > /home/node/.openclaw/openclaw.json << EOF
{
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "allowlist",
      "guilds": {
        "*": {
          "requireMention": false,
          "channels": {
            "*": {
              "allow": true
            }
          }
        }
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "opencode/minimax-m2.5-free"
      }
    }
  },
  "gateway": {
    "controlUi": {
      "allowedOrigins": ["http://localhost:18789", "http://127.0.0.1:18789"]
    }
  }
}
EOF
    echo "Discord configured from env vars"
fi

# ============================================================================
# START OPENCLAW GATEWAY
# ============================================================================

echo "=== Starting OpenClaw Gateway ==="

# Start OpenClaw gateway in background with --allow-unconfigured
openclaw gateway --allow-unconfigured &

# Wait for gateway to start
sleep 5

echo "=== OpenClaw Gateway Started ==="
echo "Container will keep running..."
echo "Gateway: http://localhost:18789"
echo "Workspace repo: $GIT_WORKSPACE_URL"
echo "To interact: docker exec -it openclaw bash"

# Keep container alive indefinitely
tail -f /dev/null