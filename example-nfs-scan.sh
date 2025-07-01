#!/bin/bash

# Example script for scanning files from NFS share
# NFS Share: 192.168.200.10/mnt/nfs_share

set -e

echo "🔍 NFS File Scanning Example"
echo "============================"
echo "NFS Share: 192.168.200.10/mnt/nfs_share"
echo ""

# Configuration
NFS_SERVER="192.168.200.10"
NFS_SHARE="/mnt/nfs_share"
CONTAINER_NAME="tmfs-nfs-scanner"
ENDPOINT="192.168.200.50:50051"

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

# Check if container is already running
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    print_warning "Container $CONTAINER_NAME is already running"
    echo "Stopping existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Start the container with NFS support
echo "🚀 Starting container with NFS support..."
docker run -d \
    --name $CONTAINER_NAME \
    --privileged \
    -e ENDPOINT=$ENDPOINT \
    -e TLS=false \
    tmfs-scanner nfs

print_status "Container started successfully"

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Mount the NFS share
echo "📁 Mounting NFS share..."
if docker exec $CONTAINER_NAME mount -t nfs $NFS_SERVER:$NFS_SHARE /mnt/nfs; then
    print_status "NFS share mounted successfully"
else
    print_error "Failed to mount NFS share"
    echo "Please check:"
    echo "1. NFS server is accessible: ping $NFS_SERVER"
    echo "2. NFS service is running on the server"
    echo "3. Firewall allows NFS traffic (port 2049)"
    echo "4. The share path exists and is exported"
    exit 1
fi

# List files in the NFS share
echo "📋 Files available in NFS share:"
docker exec $CONTAINER_NAME ls -la /mnt/nfs

echo ""
echo "🔍 Available scanning options:"
echo "1. Scan a single file:"
echo "   docker exec $CONTAINER_NAME /app/tmfs scan file:/mnt/nfs/filename.txt --tls=false --addr=$ENDPOINT"
echo ""
echo "2. Scan all files in the share:"
echo "   docker exec $CONTAINER_NAME /app/scanfiles -path=/mnt/nfs --tls=false --addr=$ENDPOINT"
echo ""
echo "3. Scan with additional options:"
echo "   docker exec $CONTAINER_NAME /app/tmfs scan file:/mnt/nfs/filename.txt --tls=false --addr=$ENDPOINT --verbose --pml"
echo ""

# Interactive mode
echo "🎯 Interactive scanning mode:"
echo "Enter a filename to scan (or 'list' to see files, 'quit' to exit):"
while true; do
    read -p "> " filename
    case $filename in
        "quit"|"exit")
            break
            ;;
        "list")
            echo "Files in /mnt/nfs:"
            docker exec $CONTAINER_NAME ls -la /mnt/nfs
            ;;
        "")
            continue
            ;;
        *)
            if docker exec $CONTAINER_NAME test -f "/mnt/nfs/$filename"; then
                echo "🔍 Scanning $filename..."
                docker exec $CONTAINER_NAME /app/tmfs scan "file:/mnt/nfs/$filename" --tls=false --addr=$ENDPOINT
            else
                print_error "File $filename not found in NFS share"
                echo "Use 'list' to see available files"
            fi
            ;;
    esac
done

# Cleanup
echo ""
echo "🧹 Cleaning up..."
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
print_status "Container stopped and removed"

echo ""
echo "📖 For more examples, see README.md" 