#!/bin/bash
# Wrapper script for Trend Vision One CLI with authentication and configuration

# Default values
TM_API_KEY=${TM_API_KEY:-""}
TM_REGION=${TM_REGION:-"us-east-1"}
TM_ENDPOINT=${TM_ENDPOINT:-""}
TM_TLS=${TM_TLS:-"true"}
TM_TIMEOUT=${TM_TIMEOUT:-"300"}

# Parse command line arguments
SCAN_ARGS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --apikey=*)
            TM_API_KEY="${1#*=}"
            shift
            ;;
        --region=*)
            TM_REGION="${1#*=}"
            shift
            ;;
        --endpoint=*)
            TM_ENDPOINT="${1#*=}"
            shift
            ;;
        --tls=*)
            TM_TLS="${1#*=}"
            shift
            ;;
        --timeout=*)
            TM_TIMEOUT="${1#*=}"
            shift
            ;;
        *)
            SCAN_ARGS="$SCAN_ARGS $1"
            shift
            ;;
    esac
done

# Validate required parameters
if [ -z "$TM_API_KEY" ] && [ -z "$TM_ENDPOINT" ]; then
    echo "Error: Either TM_API_KEY (for cloud) or TM_ENDPOINT (for local) is required"
    echo ""
    echo "For Local Endpoint:"
    echo "  Usage: $0 --endpoint=LOCAL_ENDPOINT [--tls=true|false] [--timeout=SECONDS] <cli_command>"
    echo "  Example: $0 --endpoint=my-release-visionone-filesecurity-scanner:50051 --tls=false scan file:./test.txt"
    echo ""
    echo "For Cloud Vision One:"
    echo "  Usage: $0 --apikey=YOUR_API_KEY [--region=REGION] [--tls=true|false] [--timeout=SECONDS] <cli_command>"
    echo "  Example: $0 --apikey=your-api-key --region=us-east-1 scan file:./test.txt"
    exit 1
fi

# Build CLI command arguments
CLI_ARGS=""

# For local endpoints, use the same format as your working command
if [ -n "$TM_ENDPOINT" ]; then
    # Local endpoint mode - no API key or region needed
    CLI_ARGS="$CLI_ARGS --endpoint=$TM_ENDPOINT"
    
    # Set TLS configuration for local endpoint
    if [ "$TM_TLS" = "false" ]; then
        CLI_ARGS="$CLI_ARGS --tls=false"
    fi
else
    # Cloud mode - requires API key and region
    if [ -n "$TM_API_KEY" ]; then
        CLI_ARGS="$CLI_ARGS --api-key=$TM_API_KEY"
    fi
    
    if [ -n "$TM_REGION" ]; then
        CLI_ARGS="$CLI_ARGS --region=$TM_REGION"
    fi
    
    # Set TLS configuration for cloud endpoint
    if [ "$TM_TLS" = "false" ]; then
        CLI_ARGS="$CLI_ARGS --tls=false"
    fi
fi

# Set timeout
if [ -n "$TM_TIMEOUT" ]; then
    CLI_ARGS="$CLI_ARGS --timeout=$TM_TIMEOUT"
fi

# Debug: Show what we're executing
echo "Debug: Executing /app/tmfs $CLI_ARGS $SCAN_ARGS"

# Check if file exists (for file scan commands)
FILE_PATH=$(echo "$SCAN_ARGS" | grep -o 'file:[^[:space:]]*' | sed 's/file://')
if [ -n "$FILE_PATH" ]; then
    echo "Debug: Checking if file exists: $FILE_PATH"
    if [ -f "$FILE_PATH" ]; then
        echo "Debug: File exists and is readable"
        ls -la "$FILE_PATH"
    else
        echo "Debug: File does not exist or is not readable"
        echo "Debug: Current directory: $(pwd)"
        echo "Debug: Directory contents:"
        ls -la
    fi
fi

# Execute the tmfs command
echo "Debug: Final command: /app/tmfs $CLI_ARGS $SCAN_ARGS"
exec /app/tmfs $CLI_ARGS $SCAN_ARGS 