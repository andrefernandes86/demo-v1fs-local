#!/bin/bash
# Entrypoint script for Trend Vision One CLI container

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

# Function to scan a single file
scan_file() {
    local file_path="$1"
    echo "🔍 Scanning file: $file_path"
    
    if [ ! -f "$file_path" ]; then
        echo "❌ Error: File not found: $file_path"
        exit 1
    fi
    
    # Use the same format as your working command
    /app/tmfs-cli-wrapper.sh scan "file:$file_path"
}

# Function to scan a directory
scan_directory() {
    local dir_path="$1"
    echo "🔍 Scanning directory: $dir_path"
    
    if [ ! -d "$dir_path" ]; then
        echo "❌ Error: Directory not found: $dir_path"
        exit 1
    fi
    
    # For directory scanning, we'll scan each file individually
    find "$dir_path" -type f | while read -r file; do
        echo "  Scanning: $file"
        /app/tmfs-cli-wrapper.sh scan "file:$file"
    done
}

# Function to start monitoring
start_monitoring() {
    echo "🛡️ Starting real-time monitoring..."
    exec /app/realtime-monitor.sh
}

# Function to start local path mode
start_local_mode() {
    echo "📁 Starting local path mode..."
    echo "Local Path: $LOCAL_PATH"
    echo ""
    echo "To scan files:"
    echo "  docker exec <container_name> /app/tmfs-wrapper.sh scan file:$MOUNT_PATH/file.txt"
    echo ""
    echo "Container is ready. Use 'docker exec' to run commands."
    
    # Keep container running
    tail -f /dev/null
}

# Main command processing
case "$1" in
    "scan")
        if [ -z "$2" ]; then
            echo "❌ Error: File path required for scan command"
            echo "Usage: scan <file_path>"
            exit 1
        fi
        scan_file "$2"
        ;;
    "scan-dir")
        if [ -z "$2" ]; then
            echo "❌ Error: Directory path required for scan-dir command"
            echo "Usage: scan-dir <directory_path>"
            exit 1
        fi
        scan_directory "$2"
        ;;
    "monitor")
        start_monitoring
        ;;
    "local")
        start_local_mode
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        # Pass through to CLI wrapper for other commands
        /app/tmfs-wrapper.sh "$@"
        ;;
esac 