#!/bin/bash

set -e

echo "=== Trend Micro File Security Scanner Test ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to check if Docker is running
check_docker() {
    echo "Checking Docker..."
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}ERROR: Docker is not running${NC}"
        echo "Please start Docker and try again"
        exit 1
    fi
    echo -e "${GREEN}Docker is running${NC}"
    echo ""
}

# Function to build image
build_image() {
    echo "Building Docker image..."
    if docker build -t tmfs-scanner . > /dev/null 2>&1; then
        echo -e "${GREEN}Image built successfully${NC}"
    else
        echo -e "${RED}Failed to build image${NC}"
        exit 1
    fi
    echo ""
}

# Function to test basic commands
test_basic_commands() {
    echo "Testing basic commands..."
    
    # Test help command
    run_test "Help command" "docker run --rm tmfs-scanner help"
    
    # Test scan command with non-existent file
    run_test "Scan non-existent file" "docker run --rm tmfs-scanner scan /nonexistent"
    
    # Test scan-dir command with non-existent directory
    run_test "Scan non-existent directory" "docker run --rm tmfs-scanner scan-dir /nonexistent"
    
    echo ""
}

# Function to test monitoring
test_monitoring() {
    echo "Testing monitoring functionality..."
    
    # Create test directory
    mkdir -p /tmp/test-scan
    
    # Create test files
    echo "clean file" > /tmp/test-scan/clean.txt
    echo "test file" > /tmp/test-scan/test.txt
    
    # Start monitoring in background
    echo "Starting monitoring (will run for 10 seconds)..."
    timeout 10s docker run --rm \
        -e ACTION=quarantine \
        -e SCAN_INTERVAL=2 \
        -v /tmp/test-scan:/mnt/scan:shared \
        tmfs-scanner monitor || true
    
    # Check if quarantine directory was created
    if [ -d "/tmp/test-scan/quarantine" ]; then
        echo -e "${GREEN}Quarantine directory created${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}Quarantine directory not created${NC}"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -rf /tmp/test-scan
    echo ""
}

# Function to test NFS simulation
test_nfs_simulation() {
    echo "Testing NFS simulation..."
    
    # Create local directory to simulate NFS
    mkdir -p /tmp/nfs-sim
    
    # Test with NFS environment variables
    run_test "NFS mount simulation" "docker run --rm \
        -e NFS_SERVER=localhost \
        -e NFS_SHARE=/tmp \
        -e MOUNT_PATH=/mnt/nfs \
        -v /tmp/nfs-sim:/mnt/nfs:shared \
        tmfs-scanner scan-dir /mnt/nfs"
    
    # Cleanup
    rm -rf /tmp/nfs-sim
    echo ""
}

# Function to show results
show_results() {
    echo "=== Test Results ==="
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        echo ""
        echo "You can now use the scanner:"
        echo "  docker run -d --name tmfs-monitor --privileged \\"
        echo "    -e TM_ENDPOINT=192.168.200.50:30230 \\"
        echo "    -e TM_TLS=false \\"
        echo "    -e NFS_SERVER=192.168.200.50 \\"
        echo "    -e NFS_SHARE=/mnt/nfs-share \\"
        echo "    -e MOUNT_PATH=/mnt/nfs \\"
        echo "    -e ACTION=quarantine \\"
        echo "    -v /mnt/nfs:/mnt/nfs:shared \\"
        echo "    tmfs-scanner monitor"
    else
        echo -e "${RED}Some tests failed. Please check the output above.${NC}"
        exit 1
    fi
}

# Main test execution
main() {
    check_docker
    build_image
    test_basic_commands
    test_monitoring
    test_nfs_simulation
    show_results
}

# Run tests
main 