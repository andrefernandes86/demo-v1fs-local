#!/bin/bash

set -e

echo "=== NFS Scanner Setup ==="
echo ""

# Default values
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs_share"}
MOUNT_PATH=${MOUNT_PATH:-"/mnt/nfs"}
CONTAINER_NAME=${CONTAINER_NAME:-"tmfs-monitor"}

echo "NFS Server: $NFS_SERVER"
echo "NFS Share: $NFS_SHARE"
echo "Local Mount: $MOUNT_PATH"
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

# Create mount point
echo "Creating mount point..."
mkdir -p "$MOUNT_PATH"

# Check if already mounted
if mountpoint -q "$MOUNT_PATH"; then
    echo "✅ NFS already mounted at $MOUNT_PATH"
else
    echo "Mounting NFS share..."
    
    # Try different mount options
    if mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH" 2>/dev/null; then
        echo "✅ NFS mounted successfully with nolock"
    elif mount -t nfs "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH" 2>/dev/null; then
        echo "✅ NFS mounted successfully"
    else
        echo "❌ Failed to mount NFS"
        echo "Trying alternative approach..."
        
        # Try with different NFS versions
        if mount -t nfs4 "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH" 2>/dev/null; then
            echo "✅ NFS4 mounted successfully"
        else
            echo "❌ All NFS mount attempts failed"
            echo "Please check:"
            echo "1. NFS server is running: $NFS_SERVER"
            echo "2. NFS share exists: $NFS_SHARE"
            echo "3. Network connectivity"
            exit 1
        fi
    fi
fi

# Create quarantine directory
mkdir -p "$MOUNT_PATH/quarantine"
echo "✅ Quarantine directory ready: $MOUNT_PATH/quarantine"

# Show mount info
echo ""
echo "Mount information:"
df -h | grep "$MOUNT_PATH" || echo "Mount not found in df output"
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
  -e SCAN_INTERVAL=30 \
  -v "$MOUNT_PATH:/mnt/nfs:shared" \
  tmfs-scanner monitor

echo "✅ Container started: $CONTAINER_NAME"
echo ""
echo "View logs with: docker logs -f $CONTAINER_NAME"
echo "Stop with: docker stop $CONTAINER_NAME"
echo "Unmount NFS with: umount $MOUNT_PATH" 