#!/bin/sh
# Entrypoint script for the container

if [ "$1" = "help" ]; then
    echo "Usage:"
    echo "  docker run <image> nfs                    # Start container with NFS support"
    echo "  docker run <image> scan <file> [options]  # Scan a single file"
    echo "  docker run <image> scanfiles [options]    # Scan multiple files"
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
else
    echo "Usage:"
    echo "  docker run <image> nfs                    # Start container with NFS support"
    echo "  docker run <image> scan <file> [options]  # Scan a single file"
    echo "  docker run <image> scanfiles [options]    # Scan multiple files"
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
    exit 1
fi 