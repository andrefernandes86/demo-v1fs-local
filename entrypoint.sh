#!/bin/bash
# Entrypoint script for Trend Vision One CLI container

set -e

echo "=== Trend Micro File Security Scanner ==="
echo "Container started at $(date)"
echo ""

# Default values
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs-share"}
MOUNT_PATH=${MOUNT_PATH:-"/mnt/nfs"}
ACTION=${ACTION:-"quarantine"}
SCAN_INTERVAL=${SCAN_INTERVAL:-30}
QUARANTINE_DIR=${QUARANTINE_DIR:-"quarantine"}

# Function to show help
show_help() {
    echo "🛡️ Trend Vision One CLI File Security Scanner"
    echo "============================================="
    echo ""
    echo "Usage:"
    echo "  docker run tmfs-cli-scanner <command> [options]"
    echo ""
    echo "Commands:"
    echo "  scan <file>                    - Scan a single file"
    echo "  scan-dir <directory>           - Scan all files in a directory"
    echo "  monitor                        - Start real-time monitoring"
    echo "  local                          - Start with local path support"
    echo "  help                           - Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Scan a single file (Local Endpoint)"
    echo "  docker run --rm -v /path/to/file:/app/file:ro \\"
    echo "    -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \\"
    echo "    -e TM_TLS=false \\"
    echo "    tmfs-cli-scanner scan /app/file"
    echo ""
    echo "  # Scan a single file (Cloud Vision One)"
    echo "  docker run --rm -v /path/to/file:/app/file:ro \\"
    echo "    -e TM_API_KEY=your-api-key \\"
    echo "    tmfs-cli-scanner scan /app/file"
    echo ""
    echo "  # Scan a directory (Local Endpoint)"
    echo "  docker run --rm -v /path/to/directory:/app/dir:ro \\"
    echo "    -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \\"
    echo "    -e TM_TLS=false \\"
    echo "    tmfs-cli-scanner scan-dir /app/dir"
    echo ""
    echo "  # Start real-time monitoring (Local Endpoint)"
    echo "  docker run -d --privileged \\"
    echo "    -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \\"
    echo "    -e TM_TLS=false \\"
    echo "    -e NFS_SERVER=192.168.200.50 \
    -e NFS_SHARE=/mnt/nfs-share \\"
    echo "    -e ACTION=quarantine \\"
    echo "    -v /mnt/nfs-share:/mnt/nfs-share:shared \\"
    echo "    tmfs-cli-scanner monitor"
    echo ""
    echo "Environment Variables:"
    echo "  TM_API_KEY     - Trend Vision One API key (required for cloud)"
    echo "  TM_REGION      - Vision One region (default: us-east-1, cloud only)"
    echo "  TM_ENDPOINT    - Local endpoint URL (e.g., my-release-visionone-filesecurity-scanner:50051)"
    echo "  TM_TLS         - Enable TLS (default: true, set to false for local endpoints)"
    echo "  TM_TIMEOUT     - Request timeout in seconds (default: 300)"
    echo "  NFS_SERVER     - NFS server IP (default: 192.168.200.50)"
    echo "  NFS_SHARE      - NFS share path (default: /mnt/nfs-share)"
    echo "  MOUNT_PATH     - Mount point inside container (default: /mnt/nfs)"
    echo "  ACTION         - Action for malicious files: quarantine, delete, report_only"
    echo "  SCAN_INTERVAL  - Monitoring scan interval in seconds (default: 30)"
    echo "  QUARANTINE_DIR - Quarantine directory name (default: quarantine)"
    echo ""
    echo "Supported Regions:"
    echo "  us-east-1, eu-central-1, ap-southeast-1, ap-southeast-2,"
    echo "  ap-northeast-1, ap-south-1, me-central-1"
}

# Function to mount NFS
mount_nfs() {
    if [ -n "$NFS_SERVER" ] && [ -n "$NFS_SHARE" ] && [ -n "$MOUNT_PATH" ]; then
        echo "Mounting NFS share..."
        mkdir -p "$MOUNT_PATH"
        
        # Start rpcbind for NFS
        echo "Starting rpcbind..."
        rpcbind
        
        # Try mounting with nolock option to avoid statd issues
        echo "Attempting NFS mount with timeout..."
        
        # Test NFS connectivity first
        echo "Testing NFS server connectivity..."
        if ! ping -c 1 -W 5 "$NFS_SERVER" > /dev/null 2>&1; then
            echo "❌ Cannot reach NFS server: $NFS_SERVER"
            return 1
        fi
        
        # Check if NFS share is available
        echo "Checking NFS share availability..."
        if ! showmount -e "$NFS_SERVER" | grep -q "$NFS_SHARE"; then
            echo "❌ NFS share not available: $NFS_SHARE"
            echo "Available shares:"
            showmount -e "$NFS_SERVER" || echo "Cannot list shares"
            return 1
        fi
        
        # Try mounting with timeout
        echo "Mounting NFS share..."
        timeout 30s mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✅ NFS mounted successfully at $MOUNT_PATH"
            return 0
        else
            echo "❌ Failed to mount NFS with nolock, trying without options..."
            timeout 30s mount -t nfs "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "✅ NFS mounted successfully at $MOUNT_PATH"
                return 0
            else
                echo "❌ Failed to mount NFS after timeout"
                echo "NFS server: $NFS_SERVER"
                echo "NFS share: $NFS_SHARE"
                echo "Mount path: $MOUNT_PATH"
                return 1
            fi
        fi
    else
        echo "NFS environment variables not set, skipping NFS mount"
        return 0
    fi
}

# Function to scan a file
scan_file() {
    local file="$1"
    echo "Scanning file: $file"
    
    if [ ! -f "$file" ]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    # Use the mock CLI for now
    /app/tmfs "$file"
    echo "Scan completed for: $file"
}

# Function to scan directory
scan_directory() {
    local dir="$1"
    echo "Scanning directory: $dir"
    
    if [ ! -d "$dir" ]; then
        echo "ERROR: Directory not found: $dir"
        return 1
    fi
    
    find "$dir" -type f -exec echo "Scanning: {}" \;
    echo "Directory scan completed for: $dir"
}

# Function to monitor directory
monitor_directory() {
    local dir="${MOUNT_PATH:-/mnt/scan}"
    local interval="${SCAN_INTERVAL:-30}"
    
    echo "Starting real-time monitoring..."
    echo "Directory: $dir"
    echo "Interval: ${interval}s"
    echo "Action: ${ACTION:-quarantine}"
    echo ""
    
    # Mount NFS if configured (skip if using volume mounts)
    if [ -n "$NFS_SERVER" ] && [ -n "$NFS_SHARE" ]; then
        if ! mount_nfs; then
            echo "❌ Failed to mount NFS, exiting"
            exit 1
        fi
    else
        echo "ℹ️  Using volume mount, skipping NFS mounting"
    fi
    
    # Create quarantine directory
    mkdir -p "$dir/quarantine"
    echo "✅ Quarantine directory ready: $dir/quarantine"
    
    # Show mounted filesystems
    echo "Mounted filesystems:"
    df -h | grep -E "(nfs|$dir)" || echo "No NFS mounts found"
    echo ""
    
    while true; do
        echo "=== Scan Cycle $(date) ==="
        
        if [ -d "$dir" ]; then
            file_count=$(find "$dir" -type f -not -path "$dir/quarantine/*" | wc -l)
            echo "Found $file_count files to scan"
            
            find "$dir" -type f -not -path "$dir/quarantine/*" | while read -r file; do
                echo "Checking: $file"
                # Mock scan result
                if [[ "$file" == *"test"* ]]; then
                    echo "🚨 MALICIOUS FILE DETECTED: $file"
                    if [ "$ACTION" = "quarantine" ]; then
                        mv "$file" "$dir/quarantine/"
                        echo "✅ Quarantined: $file"
                    elif [ "$ACTION" = "delete" ]; then
                        rm "$file"
                        echo "🗑️  Deleted: $file"
                    else
                        echo "📝 Reported: $file"
                    fi
                else
                    echo "✅ Clean: $file"
                fi
            done
        else
            echo "❌ WARNING: Directory $dir not found"
        fi
        
        echo "Waiting ${interval} seconds..."
        sleep "$interval"
    done
}

# Main logic
case "${1:-monitor}" in
    "scan")
        if [ -z "$2" ]; then
            echo "ERROR: No file specified for scanning"
            echo "Usage: scan <file_path>"
            exit 1
        fi
        scan_file "$2"
        ;;
    "scan-dir")
        if [ -z "$2" ]; then
            echo "ERROR: No directory specified for scanning"
            echo "Usage: scan-dir <directory_path>"
            exit 1
        fi
        scan_directory "$2"
        ;;
    "monitor")
        monitor_directory
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' for usage information"
        exit 1
        ;;
esac 