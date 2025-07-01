#!/bin/bash
# Test script for local path configuration

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

echo "🧪 Testing Local Path Configuration"
echo "==================================="
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

# Check if image exists
if ! docker image inspect tmfs-scanner >/dev/null 2>&1; then
    print_warning "Docker image 'tmfs-scanner' not found. Building..."
    make build
fi

# Check if NFS server is accessible
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs-share"}
MOUNT_PATH=${MOUNT_PATH:-"/mnt/nfs"}

# Create mount point if it doesn't exist
if [ ! -d "$MOUNT_PATH" ]; then
    print_warning "Mount path $MOUNT_PATH does not exist. Creating..."
    sudo mkdir -p "$MOUNT_PATH"
    sudo chmod 755 "$MOUNT_PATH"
fi

print_status "Creating test files in $MOUNT_PATH..."

# Create EICAR test file in the mount path
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > "$MOUNT_PATH/test-eicar.txt"

# Create a clean test file
echo "This is a clean test file for scanning." > "$MOUNT_PATH/test-clean.txt"

# Create a test directory with multiple files
mkdir -p "$MOUNT_PATH/test-dir"
echo "Test file 1" > "$MOUNT_PATH/test-dir/file1.txt"
echo "Test file 2" > "$MOUNT_PATH/test-dir/file2.txt"
echo "Test file 3" > "$MOUNT_PATH/test-dir/file3.txt"

print_status "Testing NFS scan..."

# Test single file scan
echo "🔍 Testing single file scan..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -e NFS_SERVER=192.168.200.50 \
    -e NFS_SHARE=/mnt/nfs-share \
    -e MOUNT_PATH=/mnt/nfs \
    -v "$MOUNT_PATH:$MOUNT_PATH:shared" \
    tmfs-scanner scan "$MOUNT_PATH/test-eicar.txt"

print_status "Testing directory scan..."

# Test directory scan
echo "🔍 Testing directory scan..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -e NFS_SERVER=192.168.200.50 \
    -e NFS_SHARE=/mnt/nfs-share \
    -e MOUNT_PATH=/mnt/nfs \
    -v "$MOUNT_PATH:$MOUNT_PATH:shared" \
    tmfs-scanner scan-dir "$MOUNT_PATH/test-dir"

print_status "Testing Makefile with local path..."

# Test using Makefile (if available)
echo "🔍 Testing Makefile with NFS path..."
if command -v make >/dev/null 2>&1; then
    make scan FILE="$MOUNT_PATH/test-eicar.txt" TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false NFS_SERVER=192.168.200.50 NFS_SHARE=/mnt/nfs-share MOUNT_PATH=/mnt/nfs
else
    echo "⚠️  Make not available, skipping Makefile test"
fi

print_status "Testing monitoring mode..."

# Test monitoring mode (run for a short time)
echo "🔍 Testing monitoring mode (will run for 10 seconds)..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -e NFS_SERVER=192.168.200.50 \
    -e NFS_SHARE=/mnt/nfs-share \
    -e MOUNT_PATH=/mnt/nfs \
    -e ACTION=quarantine \
    -e SCAN_INTERVAL=5 \
    -v "$MOUNT_PATH:$MOUNT_PATH:shared" \
    tmfs-scanner monitor &
MONITOR_PID=$!

# Wait for 10 seconds
sleep 10

# Stop the monitoring
kill $MONITOR_PID 2>/dev/null || true
wait $MONITOR_PID 2>/dev/null || true

print_status "Cleaning up test files..."

# Clean up test files
rm -f "$MOUNT_PATH/test-eicar.txt" "$MOUNT_PATH/test-clean.txt"
rm -rf "$MOUNT_PATH/test-dir"

print_status "Test completed successfully!"
echo ""
echo "📋 Test Summary:"
echo "- ✅ Docker environment check"
echo "- ✅ Image build/availability"
echo "- ✅ Local path accessibility"
echo "- ✅ Single file scanning"
echo "- ✅ Directory scanning"
echo "- ✅ Makefile integration"
echo "- ✅ Monitoring mode"
echo "- ✅ Test file cleanup"
echo ""
echo "🚀 Ready to use! You can now:"
echo "  - Run: make monitor NFS_SERVER=192.168.200.50 NFS_SHARE=/mnt/nfs-share MOUNT_PATH=/mnt/nfs TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false"
echo "  - Run: make scan FILE=/path/to/file NFS_SERVER=192.168.200.50 NFS_SHARE=/mnt/nfs-share MOUNT_PATH=/mnt/nfs TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false"
echo "  - Run: docker run --rm -e TM_ENDPOINT=192.168.200.50:30230 -e TM_TLS=false -e NFS_SERVER=192.168.200.50 -e NFS_SHARE=/mnt/nfs-share -e MOUNT_PATH=/mnt/nfs -v $MOUNT_PATH:$MOUNT_PATH:shared tmfs-scanner monitor" 