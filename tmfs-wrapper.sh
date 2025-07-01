#!/bin/sh
# Wrapper script for tmfs with endpoint configuration

# Default values
ENDPOINT=${ENDPOINT:-"localhost:50051"}
TLS=${TLS:-"true"}
REGION=${REGION:-""}
APIKEY=${APIKEY:-""}
PML=${PML:-"false"}
FEEDBACK=${FEEDBACK:-"false"}
VERBOSE=${VERBOSE:-"false"}
ACTIVE_CONTENT=${ACTIVE_CONTENT:-"false"}
TAGS=${TAGS:-""}
DIGEST=${DIGEST:-"true"}

# Parse command line arguments
SCAN_ARGS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --endpoint=*)
            ENDPOINT="${1#*=}"
            shift
            ;;
        --tls=*)
            TLS="${1#*=}"
            shift
            ;;
        --region=*)
            REGION="${1#*=}"
            shift
            ;;
        --apikey=*)
            APIKEY="${1#*=}"
            shift
            ;;
        --pml)
            PML="true"
            shift
            ;;
        --feedback)
            FEEDBACK="true"
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        --active-content)
            ACTIVE_CONTENT="true"
            shift
            ;;
        --tag=*)
            TAGS="${1#*=}"
            shift
            ;;
        --digest=*)
            DIGEST="${1#*=}"
            shift
            ;;
        *)
            SCAN_ARGS="$SCAN_ARGS $1"
            shift
            ;;
    esac
done

# Build command arguments
ARGS=""

if [ "$TLS" = "false" ]; then
    ARGS="$ARGS -tls=false"
fi

if [ -n "$REGION" ]; then
    ARGS="$ARGS -region=$REGION"
fi

if [ -n "$APIKEY" ]; then
    ARGS="$ARGS -apikey=$APIKEY"
fi

if [ "$PML" = "true" ]; then
    ARGS="$ARGS -pml"
fi

if [ "$FEEDBACK" = "true" ]; then
    ARGS="$ARGS -feedback"
fi

if [ "$VERBOSE" = "true" ]; then
    ARGS="$ARGS -verbose"
fi

if [ "$ACTIVE_CONTENT" = "true" ]; then
    ARGS="$ARGS -active-content"
fi

if [ -n "$TAGS" ]; then
    ARGS="$ARGS -tag=$TAGS"
fi

if [ "$DIGEST" = "false" ]; then
    ARGS="$ARGS -digest=false"
fi

# Add endpoint
ARGS="$ARGS -addr=$ENDPOINT"

# Debug: Show what we're executing
echo "Debug: Executing /app/tmfs $ARGS $SCAN_ARGS"

# Debug: Check if file exists (extract file path from scan args)
FILE_PATH=$(echo "$SCAN_ARGS" | grep -o 'file:[^[:space:]]*' | sed 's/file://')
if [ -n "$FILE_PATH" ]; then
    echo "Debug: Checking if file exists: $FILE_PATH"
    if [ -f "$FILE_PATH" ]; then
        echo "Debug: File exists and is readable"
        ls -la "$FILE_PATH"
        echo "Debug: File content (first 10 bytes):"
        head -c 10 "$FILE_PATH" | hexdump -C
    else
        echo "Debug: File does not exist or is not readable"
        echo "Debug: Current directory: $(pwd)"
        echo "Debug: Directory contents:"
        ls -la
    fi
fi

# Try different file path formats if the original fails
echo "Debug: Original scan args: $SCAN_ARGS"
if echo "$SCAN_ARGS" | grep -q 'file:'; then
    # Try without file: prefix
    SCAN_ARGS_ALT=$(echo "$SCAN_ARGS" | sed 's/file://')
    echo "Debug: Alternative scan args (without file:): $SCAN_ARGS_ALT"
fi

# Execute the command
echo "Debug: Final command: /app/tmfs $ARGS $SCAN_ARGS"
exec /app/tmfs $ARGS $SCAN_ARGS 