# Use official Go image as base
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

# Install runtime dependencies for NFS support
RUN apk add --no-cache \
    nfs-utils \
    rpcbind \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1000 tmfs && \
    adduser -D -s /bin/sh -u 1000 -G tmfs tmfs

# Set working directory
WORKDIR /app

# Copy built binaries from builder stage
COPY --from=builder /app/examples/client/client /app/tmfs
COPY --from=builder /app/examples/scanfiles/scanfiles /app/scanfiles

# Make binaries executable and set proper ownership
RUN chmod +x /app/tmfs /app/scanfiles && \
    chown tmfs:tmfs /app/tmfs /app/scanfiles && \
    ls -la /app/tmfs /app/scanfiles

# Create mount points for NFS shares and files
RUN mkdir -p /mnt/nfs /app/files && chown tmfs:tmfs /mnt/nfs /app/files

# Copy wrapper and entrypoint scripts
COPY tmfs-wrapper.sh /app/tmfs-wrapper.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY realtime-monitor.sh /app/realtime-monitor.sh
RUN chmod +x /app/tmfs-wrapper.sh /app/entrypoint.sh /app/realtime-monitor.sh && \
    chown tmfs:tmfs /app/tmfs-wrapper.sh /app/entrypoint.sh /app/realtime-monitor.sh

# Switch to non-root user
USER tmfs

# Set default environment variables
ENV TM_AM_SCAN_TIMEOUT_SECS=300
ENV TM_AM_DISABLE_CERT_VERIFY=0

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Default command
CMD ["help"] 