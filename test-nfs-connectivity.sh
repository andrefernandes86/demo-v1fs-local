#!/bin/bash

# Test NFS connectivity to 192.168.200.10/mnt/nfs_share

set -e

echo "🔍 Testing NFS Connectivity"
echo "==========================="
echo "NFS Server: 192.168.200.10"
echo "NFS Share: /mnt/nfs_share"
echo ""

# Configuration
NFS_SERVER="192.168.200.10"
NFS_SHARE="/mnt/nfs_share"
CONTAINER_NAME="tmfs-nfs-test"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up test container..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Test 1: Check if NFS server is reachable
echo "🧪 Test 1: NFS Server Connectivity"
if ping -c 1 $NFS_SERVER &> /dev/null; then
    print_status "NFS server is reachable"
else
    print_error "Cannot reach NFS server $NFS_SERVER"
    echo "Please check network connectivity and server status"
    exit 1
fi

# Test 2: Check if NFS port is open
echo "🧪 Test 2: NFS Port Accessibility"
if nc -z $NFS_SERVER 2049 2>/dev/null; then
    print_status "NFS port 2049 is accessible"
else
    print_warning "NFS port 2049 is not accessible"
    echo "This might be due to firewall rules or NFS service not running"
fi

# Test 3: Start container and test NFS mount
echo "🧪 Test 3: NFS Mount Test"
echo "Starting test container..."

docker run -d \
    --name $CONTAINER_NAME \
    --privileged \
    tmfs-scanner nfs

print_status "Test container started"

# Wait for container to be ready
sleep 3

# Test NFS mount
echo "Attempting to mount NFS share..."
if docker exec $CONTAINER_NAME mount -t nfs $NFS_SERVER:$NFS_SHARE /mnt/nfs; then
    print_status "NFS share mounted successfully"
    
    # List contents
    echo "📋 Contents of NFS share:"
    docker exec $CONTAINER_NAME ls -la /mnt/nfs
    
    # Test file access
    echo ""
    echo "🧪 Test 4: File Access Test"
    if docker exec $CONTAINER_NAME test -r /mnt/nfs; then
        print_status "NFS share is readable"
    else
        print_error "NFS share is not readable"
    fi
    
    # Unmount for cleanup
    docker exec $CONTAINER_NAME umount /mnt/nfs
    
else
    print_error "Failed to mount NFS share"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "1. Verify NFS server is running: ssh user@$NFS_SERVER 'systemctl status nfs-server'"
    echo "2. Check NFS exports: ssh user@$NFS_SERVER 'showmount -e'"
    echo "3. Verify firewall allows NFS: ssh user@$NFS_SERVER 'firewall-cmd --list-services'"
    echo "4. Check NFS share path exists: ssh user@$NFS_SERVER 'ls -la $NFS_SHARE'"
    echo ""
    echo "Common NFS export configuration:"
    echo "Add to /etc/exports on NFS server:"
    echo "  $NFS_SHARE *(ro,sync,no_subtree_check)"
    echo "Then run: exportfs -ra"
    exit 1
fi

echo ""
print_status "All NFS connectivity tests passed!"
echo "You can now use the container to scan files from the NFS share." 