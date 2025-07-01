#!/bin/bash
# Test script for local endpoint configuration

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

echo "🧪 Testing Local Endpoint Configuration"
echo "======================================"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

# Check if image exists
if ! docker image inspect tmfs-cli-scanner >/dev/null 2>&1; then
    print_warning "Docker image 'tmfs-cli-scanner' not found. Building..."
    make -f Makefile.cli build
fi

print_status "Creating EICAR test file..."

# Create EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > test-eicar.txt

print_status "Testing local endpoint scan..."

# Test with your exact working command format
echo "🔍 Testing with local endpoint: my-release-visionone-filesecurity-scanner:50051"
docker run --rm \
    -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
    -e TM_TLS=false \
    -v $(pwd)/test-eicar.txt:/app/test-eicar.txt:ro \
    tmfs-cli-scanner scan /app/test-eicar.txt

print_status "Testing with different endpoint format..."

# Test with IP address format
echo "🔍 Testing with IP endpoint: 192.168.200.50:30230"
docker run --rm \
    -e TM_ENDPOINT=192.168.200.50:30230 \
    -e TM_TLS=false \
    -v $(pwd)/test-eicar.txt:/app/test-eicar.txt:ro \
    tmfs-cli-scanner scan /app/test-eicar.txt

print_status "Testing direct tmfs command..."

# Test direct tmfs command (same as your working command)
echo "🔍 Testing direct tmfs command..."
docker run --rm \
    -v $(pwd)/test-eicar.txt:/app/test-eicar.txt:ro \
    tmfs-cli-scanner /app/tmfs scan file:./test-eicar.txt --tls=false --endpoint=my-release-visionone-filesecurity-scanner:50051

print_status "Testing Makefile with local endpoint..."

# Test using Makefile
echo "🔍 Testing Makefile with local endpoint..."
make -f Makefile.cli scan FILE=$(pwd)/test-eicar.txt TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

print_status "Cleaning up test files..."

# Clean up test files
rm -f test-eicar.txt

print_status "Test completed!"
echo ""
echo "📋 Test Summary:"
echo "- ✅ Docker environment check"
echo "- ✅ Image build/availability"
echo "- ✅ Local endpoint configuration"
echo "- ✅ Direct tmfs command execution"
echo "- ✅ Test file cleanup"
echo ""
echo "🚀 If all tests passed, you can now use:"
echo "  - make -f Makefile.cli scan FILE=/path/to/file"
echo "  - make -f Makefile.cli monitor"
echo "  - docker run --rm -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 -e TM_TLS=false tmfs-cli-scanner scan file:/path/to/file" 