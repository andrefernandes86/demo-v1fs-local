# Use Alpine Linux as base image
FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    curl \
    wget \
    bash \
    jq \
    findutils \
    nfs-utils \
    sudo \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Create a simple mock CLI for testing (you'll replace this with real CLI)
RUN echo '#!/bin/bash' > /app/tmfs && \
    echo 'echo "Mock Trend Micro CLI - Replace with real CLI"' >> /app/tmfs && \
    echo 'echo "Scanning: $1"' >> /app/tmfs && \
    echo 'echo "Result: CLEAN"' >> /app/tmfs && \
    chmod +x /app/tmfs

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Create scan directory
RUN mkdir -p /mnt/scan

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"] 