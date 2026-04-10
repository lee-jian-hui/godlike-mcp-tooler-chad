#!/bin/bash
set -e

echo "=== OpenClaw Container Startup ==="

# Setup git config if provided
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_EMAIL" ]; then
    echo "Configuring git..."
    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
fi

# Clone git repo if GIT_REPO_URL is provided
if [ -n "$GIT_REPO_URL" ]; then
    echo "Cloning git repository..."
    cd /workspace
    
    # Check if already a git repo
    if [ -d ".git" ]; then
        echo "Git repo already exists, pulling latest..."
        git pull origin main || git pull origin master || true
    else
        echo "Cloning $GIT_REPO_URL..."
        git clone "$GIT_REPO_URL" .
    fi
    
    # Set git to auto-commit
    git config --global push.default simple
fi

# Copy .opencode config if exists in workspace
if [ -d "/workspace/.opencode" ]; then
    echo "Using .opencode config from workspace..."
fi

# Copy workspace templates if they don't exist
echo "Setting up workspace directories..."
mkdir -p /workspace/todos /workspace/memory /workspace/skills /workspace/mcp-tools

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

echo "=== Starting OpenClaw Gateway ==="

# Start OpenClaw gateway in background with --allow-unconfigured
openclaw gateway --allow-unconfigured &

# Wait for gateway to start
sleep 5

echo "=== OpenClaw Gateway Started ==="
echo "Container will keep running..."
echo "Gateway: http://localhost:18789"
echo "To interact: docker exec -it openclaw bash"

# Keep container alive indefinitely
tail -f /dev/null