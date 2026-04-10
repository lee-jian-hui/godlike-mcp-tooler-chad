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

# Create non-root user
RUN useradd -m -u 1000 openclaw

# Create workspace directory
RUN mkdir -p /workspace /data && \
    chown -R openclaw:openclaw /workspace /data

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY --chown=openclaw:openclaw scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER openclaw

# Install OpenClaw globally
RUN npm install -g openclaw

# Default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]