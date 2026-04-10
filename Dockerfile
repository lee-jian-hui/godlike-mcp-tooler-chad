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

# Copy OpenCode configuration
COPY --chown=node:node .opencode/ /workspace/.opencode/

# Copy OpenClaw config
COPY --chown=node:node configs/ /workspace/configs/

# Install OpenClaw globally (as root, then switch to node user)
RUN npm install -g openclaw

# Switch to non-root user after npm install
USER node

# Default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]