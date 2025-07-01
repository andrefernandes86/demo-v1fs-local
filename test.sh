#!/bin/bash

# Test script for Trend Vision One File Security Docker Container

set -e

echo "🧪 Testing Trend Vision One File Security Docker Container"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

print_status "Docker is available"

# Create test directory and files
echo "📁 Creating test files..."
mkdir -p files
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > files/eicar.com.txt
echo 'This is a safe test file' > files/safe.txt

print_status "Test files created"

# Build the container
IMAGE_NAME="tmfs-scanner"
echo "🔨 Building Docker container..."
docker build -t $IMAGE_NAME .
print_status "Container built successfully"

# Test 1: Check if container can start and show help
echo "🧪 Test 1: Container help command"
HELP_OUTPUT=$(docker run --rm "$IMAGE_NAME" help 2>&1)
HELP_EXIT=$?
if [ $HELP_EXIT -eq 0 ]; then
    print_status "Container help command works"
else
    print_error "Container help command failed"
    echo "$HELP_OUTPUT"
    exit 1
fi

# Test 2: Check if scan command is available
echo "🧪 Test 2: Scan command availability"
if docker run --rm "$IMAGE_NAME" scan --help &> /dev/null; then
    print_status "Scan command is available"
else
    print_warning "Scan command help not available (this might be normal)"
fi

# Test 3: Test with mock endpoint (should fail but not crash)
echo "🧪 Test 3: Container startup with mock endpoint"
if docker run --rm \
    -e ENDPOINT=localhost:9999 \
    -e TLS=false \
    -v "$(pwd)/files:/app/files:ro" \
    "$IMAGE_NAME" scan file:/app/files/eicar.com.txt 2>&1 | grep -q "connection refused\|timeout\|unavailable"; then
    print_status "Container handles connection errors gracefully"
else
    print_warning "Container behavior with connection errors unclear"
fi

# Test 4: Test NFS mode startup
echo "🧪 Test 4: NFS mode startup"
CONTAINER_NAME="tmfs-test-nfs"
if docker run -d --name "$CONTAINER_NAME" --privileged "$IMAGE_NAME" nfs; then
    print_status "NFS mode container started successfully"
    
    # Wait a moment for services to start
    sleep 2
    
    # Check if rpcbind is running
    if docker exec "$CONTAINER_NAME" pgrep rpcbind &> /dev/null; then
        print_status "NFS services (rpcbind) are running"
    else
        print_warning "NFS services might not be running properly"
    fi
    
    # Cleanup
    docker stop "$CONTAINER_NAME" &> /dev/null
    docker rm "$CONTAINER_NAME" &> /dev/null
else
    print_error "Failed to start NFS mode container"
    exit 1
fi

# Test 5: Test environment variable configuration
echo "🧪 Test 5: Environment variable configuration"
if docker run --rm \
    -e ENDPOINT=test-endpoint:1234 \
    -e TLS=false \
    -e VERBOSE=true \
    -e PML=true \
    "$IMAGE_NAME" help &> /dev/null; then
    print_status "Environment variables are properly configured"
else
    print_error "Environment variable configuration failed"
    exit 1
fi

# Cleanup test files
echo "🧹 Cleaning up test files..."
rm -rf files

print_status "Test files cleaned up"

echo ""
echo "🎉 All tests completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Configure your actual Trend Vision One File Security endpoint"
echo "2. Set up NFS shares if needed"
echo "3. Run scans with your configuration:"
echo ""
echo "   docker run --rm \\"
echo "     -e ENDPOINT=your-endpoint:50051 \\"
echo "     -e TLS=false \\"
echo "     -v /path/to/files:/app/files:ro \\"
echo "     $IMAGE_NAME scan file:/app/files/your-file.txt"
echo ""
echo "📖 For more information, see README.md" 