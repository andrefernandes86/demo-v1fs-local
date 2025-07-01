# Use official Go image as base for building tmfs
FROM golang:1.23-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git make

# Set working directory
WORKDIR /app

# Clone the Trend Vision One File Security SDK
RUN git clone https://github.com/trendmicro/tm-v1-fs-golang-sdk.git .

# Build the client tools
RUN make build && \
    ls -la /app/examples/ && \
    echo "Build completed successfully" && \
    ls -la /app/examples/client && \
    ls -la /app/examples/scanfiles

# Create final runtime image
FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    curl \
    wget \
    unzip \
    bash \
    nfs-utils \
    rpcbind \
    ca-certificates \
    jq \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 tmfs && \
    adduser -D -s /bin/bash -u 1000 -G tmfs tmfs

# Set working directory
WORKDIR /app

# Use the existing tmfs binary from the Go SDK build
# This is the same binary that works with your local endpoint
COPY --from=builder /app/examples/client/client /app/tmfs
RUN chmod +x /app/tmfs

# Create mount points for NFS shares and files
RUN mkdir -p /mnt/nfs /app/files && chown tmfs:tmfs /mnt/nfs /app/files

# Copy wrapper and entrypoint scripts
COPY tmfs-cli-wrapper.sh /app/tmfs-cli-wrapper.sh
COPY entrypoint-cli.sh /app/entrypoint-cli.sh
COPY realtime-monitor-cli.sh /app/realtime-monitor-cli.sh
RUN chmod +x /app/tmfs-cli-wrapper.sh /app/entrypoint-cli.sh /app/realtime-monitor-cli.sh && \
    chown tmfs:tmfs /app/tmfs-cli-wrapper.sh /app/entrypoint-cli.sh /app/realtime-monitor-cli.sh

# Set default environment variables
ENV TM_API_KEY=""
ENV TM_REGION="us-east-1"
ENV TM_ENDPOINT="my-release-visionone-filesecurity-scanner:50051"
ENV TM_TLS="false"
ENV TM_TIMEOUT="300"

# Set entrypoint
ENTRYPOINT ["/app/entrypoint-cli.sh"]

# Default command
CMD ["help"] 