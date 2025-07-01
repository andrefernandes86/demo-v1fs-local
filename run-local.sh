#!/bin/bash

set -e

echo "=== Local Scanner Setup ==="
echo ""

# Default values
LOCAL_PATH=${LOCAL_PATH:-"/mnt/nfs"}
CONTAINER_NAME=${CONTAINER_NAME:-"tmfs-monitor"}

echo "Local Path: $LOCAL_PATH"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run as root (use sudo)"
    exit 1
fi

# Stop existing container
echo "Stopping existing container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Create local directory
echo "Creating local directory..."
mkdir -p "$LOCAL_PATH"

# Create quarantine directory
mkdir -p "$LOCAL_PATH/quarantine"
echo "✅ Quarantine directory ready: $LOCAL_PATH/quarantine"

# Create some test files
echo "Creating test files..."
echo "clean content" > "$LOCAL_PATH/clean-file.txt"
echo "test content" > "$LOCAL_PATH/test-file.txt"
echo "another test" > "$LOCAL_PATH/another-test.txt"
echo "✅ Test files created"

# Show directory contents
echo ""
echo "Directory contents:"
ls -la "$LOCAL_PATH"
echo ""

# Run the container
echo "Starting scanner container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e MOUNT_PATH=/mnt/nfs \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=10 \
  -v "$LOCAL_PATH:/mnt/nfs:shared" \
  tmfs-scanner monitor

echo "✅ Container started: $CONTAINER_NAME"
echo ""
echo "View logs with: docker logs -f $CONTAINER_NAME"
echo "Stop with: docker stop $CONTAINER_NAME"
echo ""
echo "The scanner will detect files with 'test' in the name and move them to quarantine."
echo "Check the logs to see the scanning in action!" 