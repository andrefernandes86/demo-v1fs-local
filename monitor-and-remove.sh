#!/bin/bash

# Real-time malicious file monitoring and removal
# NFS Share: 192.168.200.10/mnt/nfs_share
# Scanner: 192.168.200.50:50051

set -e

echo "🛡️ Real-time Malicious File Monitor"
echo "==================================="
echo "NFS Share: 192.168.200.10/mnt/nfs_share"
echo "Scanner: 192.168.200.50:50051"
echo ""

# Configuration
NFS_SERVER="192.168.200.10"
NFS_SHARE="/mnt/nfs_share"
CONTAINER_NAME="tmfs-monitor"
ENDPOINT="192.168.200.50:50051"
SCAN_INTERVAL=30  # seconds
QUARANTINE_DIR="quarantine"

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

print_alert() {
    echo -e "${RED}🚨 $1${NC}"
}

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up monitor container..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    exit 0
}

# Set trap to cleanup on exit
trap cleanup SIGINT SIGTERM

# Check if container is already running
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    print_warning "Container $CONTAINER_NAME is already running"
    echo "Stopping existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Start the container with NFS support
echo "🚀 Starting monitoring container..."
docker run -d \
    --name $CONTAINER_NAME \
    --privileged \
    -e ENDPOINT=$ENDPOINT \
    -e TLS=false \
    tmfs-scanner nfs

print_status "Container started successfully"

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 5

# Mount the NFS share
echo "📁 Mounting NFS share..."
if docker exec $CONTAINER_NAME mount -t nfs $NFS_SERVER:$NFS_SHARE /mnt/nfs; then
    print_status "NFS share mounted successfully"
else
    print_error "Failed to mount NFS share"
    cleanup
    exit 1
fi

# Create quarantine directory
echo "📦 Creating quarantine directory..."
docker exec $CONTAINER_NAME mkdir -p "/mnt/nfs/$QUARANTINE_DIR"
print_status "Quarantine directory ready"

echo ""
echo "🔍 Starting real-time monitoring..."
echo "Scanning every $SCAN_INTERVAL seconds..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Monitoring loop
while true; do
    echo "🔄 Scanning for new files... ($(date))"
    
    # Find new files to scan (focus on executable and script files)
    NEW_FILES=$(docker exec $CONTAINER_NAME find /mnt/nfs -type f \( -name "*.exe" -o -name "*.dll" -o -name "*.bat" -o -name "*.ps1" -o -name "*.vbs" -o -name "*.js" -o -name "*.jar" -o -name "*.msi" -o -name "*.com" -o -name "*.scr" \) -newer /tmp/last_scan 2>/dev/null || true)
    
    if [ -n "$NEW_FILES" ]; then
        echo "📋 Found new files to scan:"
        echo "$NEW_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                echo "  - $file"
                
                # Scan the file
                echo "    🔍 Scanning..."
                SCAN_RESULT=$(docker exec $CONTAINER_NAME /app/tmfs scan "file:$file" --tls=false --addr=$ENDPOINT 2>&1 || true)
                
                # Check if malicious
                if echo "$SCAN_RESULT" | grep -q "malicious\|threat\|virus\|malware\|suspicious"; then
                    print_alert "MALICIOUS FILE DETECTED: $file"
                    echo "    Threat details: $(echo "$SCAN_RESULT" | grep -E "(malicious|threat|virus|malware|suspicious)" | head -1)"
                    
                    # Take action - move to quarantine
                    echo "    🚨 Quarantining file..."
                    FILENAME=$(basename "$file")
                    QUARANTINE_PATH="/mnt/nfs/$QUARANTINE_DIR/${FILENAME}.quarantined_$(date +%Y%m%d_%H%M%S)"
                    
                    if docker exec $CONTAINER_NAME mv "$file" "$QUARANTINE_PATH"; then
                        print_status "File quarantined: $file → $QUARANTINE_PATH"
                        
                        # Log the quarantine
                        echo "QUARANTINED: $file -> $QUARANTINE_PATH at $(date)" >> /tmp/malicious_files_quarantined.log
                    else
                        print_error "Failed to quarantine: $file"
                    fi
                else
                    print_status "File is clean: $file"
                fi
            fi
        done
    else
        echo "  No new files to scan"
    fi
    
    # Update last scan timestamp
    docker exec $CONTAINER_NAME touch /tmp/last_scan
    
    # Wait before next scan
    echo "⏳ Waiting $SCAN_INTERVAL seconds before next scan..."
    sleep $SCAN_INTERVAL
done 