FROM node:22-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    curl \
    wget \
    ca-certificates \
    podman \
    && rm -rf /var/lib/apt/lists/*

# Note: node:22-bookworm already has 'node' user with UID 1000
# We use that user instead of creating a new one

# Create workspace directory
RUN mkdir -p /workspace /data && \
    chown -R node:node /workspace /data

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY --chown=node:node scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy secret redaction script
COPY --chown=node:node scripts/redact-secrets.sh /usr/local/bin/redact-secrets.sh
RUN chmod +x /usr/local/bin/redact-secrets.sh

# Copy OpenCode configuration
COPY --chown=node:node .opencode/ /workspace/.opencode/

# Copy OpenClaw config
COPY --chown=node:node configs/ /workspace/configs/

# Install OpenClaw globally (as root, then switch to node user)
# OpenCode is bundled with OpenClaw's ACP
RUN npm install -g openclaw

# Pre-install runtime dependencies for plugins that need them (as root)
# These plugins have "bundle": { "stageRuntimeDependencies": true }
# and need to install their npm deps at runtime, but can't write to global node_modules as non-root
RUN npm install -g @openclaw/discord @openclaw/browser @openclaw/amazon-bedrock @openclaw/amazon-bedrock-mantle @openclaw/microsoft @openclaw/acpx @openclaw/validation 2>/dev/null || true

# Allow node user to write to global node_modules for plugin runtime dependency installation
# This is needed because some plugins try to install additional deps at runtime
RUN chown -R node:node /usr/local/lib/node_modules /usr/local/bin

# Switch to non-root user after npm install
USER node

# Default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]