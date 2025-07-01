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
echo "Debug: Executing /app/tmfs $ARGS $@"

# Execute the command
exec /app/tmfs $ARGS "$@" 