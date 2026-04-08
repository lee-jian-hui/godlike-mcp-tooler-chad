#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== OpenCode Autonomous Agent Setup ==="

echo "[1/4] Creating workspace directory..."
mkdir -p workspace
echo "  Workspace created at: $SCRIPT_DIR/workspace"

echo "[2/4] Building agent image..."
docker build -t opencode-agent:latest -f Dockerfile.agent .
echo "  Image built: opencode-agent:latest"

echo "[3/4] Starting services..."
docker-compose up -d
echo "  Services started (proxy + agent)"

echo "[4/4] Checking status..."
sleep 2
docker-compose ps

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To run a task:"
echo "  docker exec opencode-agent opencode --task 'Your task here'"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f agent"
echo ""
echo "To stop:"
echo "  docker-compose down"
