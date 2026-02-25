#!/bin/bash
# Build the ClawCode agent container image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="clawcode-agent"
TAG="${1:-latest}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-docker}"

echo "Building ClawCode agent container image..."
echo "Image: ${IMAGE_NAME}:${TAG}"

# Use --network=host to bypass Docker bridge networking during builds.
# This avoids conntrack errors and DNS resolution failures that occur
# when Docker's bridge network has issues (common in Fly.io VMs).
MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
  if ${CONTAINER_RUNTIME} build --network=host -t "${IMAGE_NAME}:${TAG}" .; then
    break
  fi
  if [ "$attempt" -eq "$MAX_RETRIES" ]; then
    echo "ERROR: Build failed after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Build attempt $attempt failed, retrying in $((attempt * 5))s..."
  sleep $((attempt * 5))
done

echo ""
echo "Build complete!"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""
echo "Test with:"
echo "  echo '{\"prompt\":\"What is 2+2?\",\"groupFolder\":\"test\",\"chatJid\":\"gh:owner/repo#issue:1\",\"isMain\":false}' | ${CONTAINER_RUNTIME} run -i ${IMAGE_NAME}:${TAG}"
