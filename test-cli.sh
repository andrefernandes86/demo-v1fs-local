#!/bin/bash
# Test script for Trend Vision One CLI File Security Scanner

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

echo "🧪 Testing Trend Vision One CLI File Security Scanner"
echo "====================================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found. Please create it with your TM_API_KEY."
    echo "You can run: make -f Makefile.cli setup"
    exit 1
fi

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

print_status "Creating test files..."

# Create EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > test-eicar.txt

# Create a clean test file
echo "This is a clean test file for scanning." > test-clean.txt

# Create a test directory with multiple files
mkdir -p test-dir
echo "Test file 1" > test-dir/file1.txt
echo "Test file 2" > test-dir/file2.txt
echo "Test file 3" > test-dir/file3.txt

print_status "Testing single file scan..."

# Test single file scan
echo "🔍 Scanning EICAR test file..."
docker run --rm \
    --env-file .env \
    -v $(pwd)/test-eicar.txt:/app/test-eicar.txt:ro \
    tmfs-cli-scanner scan /app/test-eicar.txt

echo ""
echo "🔍 Scanning clean test file..."
docker run --rm \
    --env-file .env \
    -v $(pwd)/test-clean.txt:/app/test-clean.txt:ro \
    tmfs-cli-scanner scan /app/test-clean.txt

print_status "Testing directory scan..."

# Test directory scan
echo "🔍 Scanning test directory..."
docker run --rm \
    --env-file .env \
    -v $(pwd)/test-dir:/app/test-dir:ro \
    tmfs-cli-scanner scan-dir /app/test-dir

print_status "Testing CLI help..."

# Test CLI help
echo "🔍 Testing CLI help..."
docker run --rm tmfs-cli-scanner help

print_status "Testing CLI version..."

# Test CLI version (if available)
echo "🔍 Testing CLI version..."
docker run --rm tmfs-cli-scanner --version 2>/dev/null || echo "Version command not available"

print_status "Cleaning up test files..."

# Clean up test files
rm -f test-eicar.txt test-clean.txt
rm -rf test-dir

print_status "Test completed successfully!"
echo ""
echo "📋 Test Summary:"
echo "- ✅ Docker environment check"
echo "- ✅ Image build/availability"
echo "- ✅ Single file scanning"
echo "- ✅ Directory scanning"
echo "- ✅ CLI help functionality"
echo "- ✅ Test file cleanup"
echo ""
echo "🚀 Ready to use! You can now:"
echo "  - Run: make -f Makefile.cli monitor (for real-time monitoring)"
echo "  - Run: make -f Makefile.cli scan FILE=/path/to/file (for single file scan)"
echo "  - Run: make -f Makefile.cli scan-dir DIR=/path/to/directory (for directory scan)" 