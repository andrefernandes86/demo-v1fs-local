#!/bin/sh
# Entrypoint script for the container

if [ "$1" = "help" ]; then
    echo "Usage:"
    echo "  docker run <image> nfs                    # Start container with NFS support"
    echo "  docker run <image> scan <file> [options]  # Scan a single file"
    echo "  docker run <image> scanfiles [options]    # Scan multiple files"
    echo "  docker run <image> monitor [options]      # Real-time monitoring with action"
    echo "  docker run <image> quarantine             # Start monitoring with quarantine action"
    echo "  docker run <image> delete                 # Start monitoring with delete action"
    echo "  docker run <image> report                 # Start monitoring with report only"
    echo ""
    echo "Real-time Monitoring:"
    echo "  docker run <image> monitor                # Start monitoring with default settings"
    echo "  docker run <image> monitor --action=quarantine    # Quarantine malicious files"
    echo "  docker run <image> monitor --action=delete        # Delete malicious files"
    echo "  docker run <image> monitor --action=report_only   # Report only, no action"
    echo "  docker run <image> quarantine             # Direct quarantine action"
    echo "  docker run <image> delete                 # Direct delete action"
    echo "  docker run <image> report                 # Direct report only"
    echo ""
    echo "Environment variables:"
    echo "  ENDPOINT=<host:port>     # File Security service endpoint (default: localhost:50051)"
    echo "  TLS=<true|false>         # Enable/disable TLS (default: true)"
    echo "  REGION=<region>          # Service region"
    echo "  APIKEY=<key>             # API key for authentication"
    echo "  PML=<true|false>         # Enable PML detection (default: false)"
    echo "  FEEDBACK=<true|false>    # Enable SPN feedback (default: false)"
    echo "  VERBOSE=<true|false>     # Enable verbose output (default: false)"
    echo "  ACTIVE_CONTENT=<true|false> # Enable active content detection (default: false)"
    echo "  TAGS=<tags>              # Comma-separated tags"
    echo "  DIGEST=<true|false>      # Enable digest calculation (default: true)"
    echo "  ACTION=<action>          # Monitor action: quarantine, delete, report_only"
    echo "  NFS_SERVER=<ip>          # NFS server IP (default: 192.168.200.10)"
    echo "  NFS_SHARE=<path>         # NFS share path (default: /mnt/nfs_share)"
    echo "  SCAN_INTERVAL=<seconds>  # Scan interval in seconds (default: 30)"
    echo "  QUARANTINE_DIR=<dir>     # Quarantine directory name (default: quarantine)"
    exit 0
fi

# Start rpcbind for NFS support
if [ "$1" = "nfs" ]; then
    echo "Starting NFS client services..."
    rpcbind
    echo "NFS client services started. Container ready for NFS mounts."
    # Keep container running
    tail -f /dev/null
elif [ "$1" = "scan" ]; then
    shift
    exec /app/tmfs-wrapper.sh scan "$@"
elif [ "$1" = "scanfiles" ]; then
    shift
    exec /app/scanfiles "$@"
elif [ "$1" = "monitor" ]; then
    shift
    # Parse monitor options
    while [ $# -gt 0 ]; do
        case "$1" in
            --action=*)
                ACTION="${1#*=}"
                shift
                ;;
            --nfs-server=*)
                NFS_SERVER="${1#*=}"
                shift
                ;;
            --nfs-share=*)
                NFS_SHARE="${1#*=}"
                shift
                ;;
            --scan-interval=*)
                SCAN_INTERVAL="${1#*=}"
                shift
                ;;
            --quarantine-dir=*)
                QUARANTINE_DIR="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown monitor option: $1"
                exit 1
                ;;
        esac
    done
    exec /app/realtime-monitor.sh
elif [ "$1" = "quarantine" ]; then
    shift
    ACTION=quarantine
    exec /app/realtime-monitor.sh
elif [ "$1" = "delete" ]; then
    shift
    ACTION=delete
    exec /app/realtime-monitor.sh
elif [ "$1" = "report" ]; then
    shift
    ACTION=report_only
    exec /app/realtime-monitor.sh
else
    echo "Usage:"
    echo "  docker run <image> nfs                    # Start container with NFS support"
    echo "  docker run <image> scan <file> [options]  # Scan a single file"
    echo "  docker run <image> scanfiles [options]    # Scan multiple files"
    echo "  docker run <image> monitor [options]      # Real-time monitoring with action"
    echo ""
    echo "Environment variables:"
    echo "  ENDPOINT=<host:port>     # File Security service endpoint (default: localhost:50051)"
    echo "  TLS=<true|false>         # Enable/disable TLS (default: true)"
    echo "  REGION=<region>          # Service region"
    echo "  APIKEY=<key>             # API key for authentication"
    echo "  PML=<true|false>         # Enable PML detection (default: false)"
    echo "  FEEDBACK=<true|false>    # Enable SPN feedback (default: false)"
    echo "  VERBOSE=<true|false>     # Enable verbose output (default: false)"
    echo "  ACTIVE_CONTENT=<true|false> # Enable active content detection (default: false)"
    echo "  TAGS=<tags>              # Comma-separated tags"
    echo "  DIGEST=<true|false>      # Enable digest calculation (default: true)"
    echo "  ACTION=<action>          # Monitor action: quarantine, delete, report_only"
    echo "  NFS_SERVER=<ip>          # NFS server IP (default: 192.168.200.10)"
    echo "  NFS_SHARE=<path>         # NFS share path (default: /mnt/nfs_share)"
    echo "  SCAN_INTERVAL=<seconds>  # Scan interval in seconds (default: 30)"
    echo "  QUARANTINE_DIR=<dir>     # Quarantine directory name (default: quarantine)"
    exit 1
fi 