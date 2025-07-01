#!/bin/bash

set -e

echo "=== Real NFS Scanner Setup ==="
echo ""

# Default values
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs_share"}
LOCAL_MOUNT=${LOCAL_MOUNT:-"/mnt/nfs-share"}
CONTAINER_NAME=${CONTAINER_NAME:-"tmfs-monitor"}

echo "NFS Server: $NFS_SERVER"
echo "NFS Share: $NFS_SHARE"
echo "Local Mount: $LOCAL_MOUNT"
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

# Check if NFS share is already mounted
if mountpoint -q "$LOCAL_MOUNT"; then
    echo "✅ NFS share already mounted at $LOCAL_MOUNT"
else
    echo "❌ NFS share not mounted at $LOCAL_MOUNT"
    echo "Please mount it manually first:"
    echo "  mount -t nfs -o nolock $NFS_SERVER:$NFS_SHARE $LOCAL_MOUNT"
    echo ""
    echo "Or create a local copy:"
    echo "  cp -r /mnt/nfs-share /tmp/nfs-copy"
    echo "  LOCAL_MOUNT=/tmp/nfs-copy ./run-real-nfs.sh"
    exit 1
fi

# Create quarantine directory
mkdir -p "$LOCAL_MOUNT/quarantine"
echo "✅ Quarantine directory ready: $LOCAL_MOUNT/quarantine"

# Show current files
echo ""
echo "Files to be scanned:"
ls -la "$LOCAL_MOUNT"
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
  -e SCAN_INTERVAL=15 \
  -v "$LOCAL_MOUNT:/mnt/nfs:shared" \
  tmfs-scanner monitor

echo "✅ Container started: $CONTAINER_NAME"
echo ""
echo "View logs with: docker logs -f $CONTAINER_NAME"
echo "Stop with: docker stop $CONTAINER_NAME"
echo ""
echo "The scanner will detect malware files and move them to quarantine."
echo "Check the logs to see the scanning in action!" 