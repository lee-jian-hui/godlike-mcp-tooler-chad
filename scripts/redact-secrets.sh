#!/bin/bash
# Redact secrets - shows only last 5 characters of sensitive values

echo "=== Environment Variables (Redacted) ==="
echo ""

# Show known secret env vars with redacted values
for var in DISCORD_BOT_TOKEN OPENCODE_API_KEY GIT_WORKSPACE_TOKEN MINIMAX_API_KEY; do
    value="${!var}"
    if [ -n "$value" ]; then
        # Show last 5 characters
        redacted="••••••${value: -5}"
        echo "$var=$redacted"
    else
        echo "$var= (not set)"
    fi
done

echo ""
echo "=== Non-Secret Environment Variables ==="
# Show key non-secret env vars
for var in GIT_WORKSPACE_URL GIT_WORKSPACE_USERNAME OPENCODE_MODEL; do
    value="${!var}"
    if [ -n "$value" ]; then
        echo "$var=$value"
    fi
done