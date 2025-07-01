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

# Download and install Trend Vision One CLI
# Note: You need to download the CLI manually from Trend Micro Vision One console
# and place it in the build context as 'tmfs' file
COPY tmfs /app/tmfs
RUN chmod +x /app/tmfs

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy monitoring script
COPY realtime-monitor.sh /app/realtime-monitor.sh
RUN chmod +x /app/realtime-monitor.sh

# Create scan directory
RUN mkdir -p /mnt/scan

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"] 