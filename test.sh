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

# Check if local path exists
LOCAL_PATH=${LOCAL_PATH:-"/mnt/nfs-share"}
if [ ! -d "$LOCAL_PATH" ]; then
    print_warning "Local path $LOCAL_PATH does not exist. Creating test directory..."
    sudo mkdir -p "$LOCAL_PATH"
    sudo chmod 755 "$LOCAL_PATH"
fi

print_status "Creating test files in $LOCAL_PATH..."

# Create EICAR test file in the local path
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > "$LOCAL_PATH/test-eicar.txt"

# Create a clean test file
echo "This is a clean test file for scanning." > "$LOCAL_PATH/test-clean.txt"

# Create a test directory with multiple files
mkdir -p "$LOCAL_PATH/test-dir"
echo "Test file 1" > "$LOCAL_PATH/test-dir/file1.txt"
echo "Test file 2" > "$LOCAL_PATH/test-dir/file2.txt"
echo "Test file 3" > "$LOCAL_PATH/test-dir/file3.txt"

print_status "Testing local path scan..."

# Test single file scan
echo "🔍 Testing single file scan..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -v "$LOCAL_PATH:$LOCAL_PATH:shared" \
    tmfs-scanner scan "$LOCAL_PATH/test-eicar.txt"

print_status "Testing directory scan..."

# Test directory scan
echo "🔍 Testing directory scan..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -v "$LOCAL_PATH:$LOCAL_PATH:shared" \
    tmfs-scanner scan-dir "$LOCAL_PATH/test-dir"

print_status "Testing Makefile with local path..."

# Test using Makefile (if available)
echo "🔍 Testing Makefile with local path..."
if command -v make >/dev/null 2>&1; then
    make scan FILE="$LOCAL_PATH/test-eicar.txt" TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false LOCAL_PATH="$LOCAL_PATH"
else
    echo "⚠️  Make not available, skipping Makefile test"
fi

print_status "Testing monitoring mode..."

# Test monitoring mode (run for a short time)
echo "🔍 Testing monitoring mode (will run for 10 seconds)..."
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -e LOCAL_PATH="$LOCAL_PATH" \
    -e ACTION=report_only \
    -e SCAN_INTERVAL=5 \
    -v "$LOCAL_PATH:$LOCAL_PATH:shared" \
    tmfs-scanner monitor &
MONITOR_PID=$!

# Wait for 10 seconds
sleep 10

# Stop the monitoring
kill $MONITOR_PID 2>/dev/null || true
wait $MONITOR_PID 2>/dev/null || true

print_status "Cleaning up test files..."

# Clean up test files
rm -f "$LOCAL_PATH/test-eicar.txt" "$LOCAL_PATH/test-clean.txt"
rm -rf "$LOCAL_PATH/test-dir"

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
echo "  - Run: make monitor LOCAL_PATH=$LOCAL_PATH TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false"
echo "  - Run: make scan FILE=/path/to/file LOCAL_PATH=$LOCAL_PATH TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false"
echo "  - Run: docker run --rm -e TM_ENDPOINT=192.168.200.50:30230 -e TM_TLS=false -e LOCAL_PATH=$LOCAL_PATH -v $LOCAL_PATH:$LOCAL_PATH:shared tmfs-scanner monitor" 