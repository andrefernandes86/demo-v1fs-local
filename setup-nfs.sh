#!/bin/bash

echo "=== NFS Setup Helper ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run as root (use sudo)"
    exit 1
fi

# Default values
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs-share"}
MOUNT_PATH=${MOUNT_PATH:-"/mnt/nfs"}

echo "NFS Server: $NFS_SERVER"
echo "NFS Share: $NFS_SHARE"
echo "Mount Path: $MOUNT_PATH"
echo ""

# Check if NFS server is accessible
echo "Checking NFS server accessibility..."
if ping -c 1 "$NFS_SERVER" > /dev/null 2>&1; then
    echo "✅ NFS server is reachable"
else
    echo "❌ NFS server is not reachable"
    echo "Please check your network connection and NFS server status"
    exit 1
fi

# Check if NFS share is exported
echo "Checking NFS share availability..."
if showmount -e "$NFS_SERVER" | grep -q "$NFS_SHARE"; then
    echo "✅ NFS share is available"
else
    echo "❌ NFS share is not available"
    echo "Available shares:"
    showmount -e "$NFS_SERVER" || echo "Cannot list shares"
    exit 1
fi

# Create mount point
echo "Creating mount point..."
mkdir -p "$MOUNT_PATH"
chmod 755 "$MOUNT_PATH"

# Try to mount NFS
echo "Mounting NFS share..."
if mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH"; then
    echo "✅ NFS mounted successfully"
    
    # Test write access
    if touch "$MOUNT_PATH/test_write" 2>/dev/null; then
        echo "✅ Write access confirmed"
        rm -f "$MOUNT_PATH/test_write"
    else
        echo "⚠️  Write access may be restricted"
    fi
    
    # Create quarantine directory
    mkdir -p "$MOUNT_PATH/quarantine"
    echo "✅ Quarantine directory created"
    
    echo ""
    echo "NFS is ready! You can now run the scanner:"
    echo "  docker run -d --name tmfs-monitor --privileged \\"
    echo "    -e TM_ENDPOINT=192.168.200.50:30230 \\"
    echo "    -e TM_TLS=false \\"
    echo "    -e NFS_SERVER=$NFS_SERVER \\"
    echo "    -e NFS_SHARE=$NFS_SHARE \\"
    echo "    -e MOUNT_PATH=$MOUNT_PATH \\"
    echo "    -e ACTION=quarantine \\"
    echo "    -v $MOUNT_PATH:$MOUNT_PATH:shared \\"
    echo "    tmfs-scanner monitor"
    
else
    echo "❌ Failed to mount NFS"
    echo "You can try mounting manually:"
    echo "  mount -t nfs -o nolock $NFS_SERVER:$NFS_SHARE $MOUNT_PATH"
    exit 1
fi 