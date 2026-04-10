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

# Write Discord config from environment variables
if [ -n "$DISCORD_BOT_TOKEN" ]; then
    echo "Configuring Discord channel..."
    mkdir -p /home/node/.openclaw
    cat > /home/node/.openclaw/openclaw.json << EOF
{
  "channels": {
    "discord": {
      "enabled": true
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