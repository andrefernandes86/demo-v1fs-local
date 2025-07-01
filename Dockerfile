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
RUN wget -O /app/tmfs https://github.com/trendmicro/visionone-cli/releases/latest/download/tmcli-linux-amd64 \
    && chmod +x /app/tmfs

# Copy scan and delete script
COPY scan_and_delete.sh /app/scan_and_delete.sh
RUN chmod +x /app/scan_and_delete.sh

# Copy wrapper script
COPY tmfs-wrapper.sh /app/tmfs-wrapper.sh
RUN chmod +x /app/tmfs-wrapper.sh

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy monitoring script
COPY realtime-monitor.sh /app/realtime-monitor.sh
RUN chmod +x /app/realtime-monitor.sh

# Create scan directory
RUN mkdir -p /mnt/scan

# Set entrypoint
ENTRYPOINT ["/app/scan_and_delete.sh"] 