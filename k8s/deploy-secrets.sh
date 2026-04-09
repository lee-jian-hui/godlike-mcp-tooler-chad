#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Creating OpenClaw K8s Secrets ==="

# Check if .env exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and fill in your values:"
    echo "  cp .env.example .env"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace openclaw &> /dev/null; then
    echo "Creating namespace 'openclaw'..."
    kubectl create namespace openclaw
fi

# Delete existing secret if it exists
echo "Removing old secret (if any)..."
kubectl delete secret openclaw-secrets -n openclaw --ignore-not-found=true

# Create secret from .env file
echo "Creating secret from .env..."
kubectl create secret generic openclaw-secrets \
    --from-env-file="$PROJECT_ROOT/.env" \
    -n openclaw

echo ""
echo "=== Secrets created successfully! ==="
echo ""
echo "To verify:"
echo "  kubectl get secret openclaw-secrets -n openclaw"
echo ""
echo "To delete:"
echo "  kubectl delete secret openclaw-secrets -n openclaw"
