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
    
    # Check if already a git repo (cloned previously)
    if [ -d ".git" ]; then
        echo "Workspace repo exists, pulling latest..."
        git fetch origin
        git reset --hard origin/main || true
    else
        # Clean workspace directory except for OpenClaw system files
        # Keep: configs/ .opencode/ scripts/ (from agent repo build)
        ls -A /workspace | grep -v "^configs$" | grep -v "^\.opencode$" | grep -v "^scripts$" | xargs -r rm -rf 2>/dev/null || true
        
        # Clone workspace repo
        echo "Cloning $GIT_WORKSPACE_URL..."
        git clone "$GIT_WORKSPACE_URL" .
    fi
    
    # Configure git for workspace repo commits
    if [ -n "$GIT_WORKSPACE_USERNAME" ] && [ -n "$GIT_WORKSPACE_TOKEN" ]; then
        echo "Configuring git for workspace repo..."
        git config user.name "$GIT_WORKSPACE_USERNAME"
        git config user.email "${GIT_WORKSPACE_EMAIL:-github-actions@users.noreply.github.com}"
        
        # Configure git to use token for authentication
        git remote set-url origin "https://${GIT_WORKSPACE_USERNAME}:${GIT_WORKSPACE_TOKEN}@$(echo $GIT_WORKSPACE_URL | sed 's|https://||')"
    fi
    
    # Set git to auto-commit
    git config --global push.default simple
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
elif [ -n "$DISCORD_BOT_TOKEN" ]; then
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