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

# Execute the command
exec /app/tmfs $ARGS $SCAN_ARGS 