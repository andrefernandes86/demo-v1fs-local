# Deployment Guide - Trend Vision One File Security Scanner

This guide will help you deploy and run the Trend Vision One File Security Scanner on any host system.

## 🚀 Quick Start (5 minutes)

### Prerequisites

1. **Docker** installed on your host
2. **Git** to clone the repository
3. **Local endpoint** running (Trend Micro Vision One File Security)

### Step 1: Clone the Repository

```bash
git clone https://github.com/andrefernandes86/demo-v1fs-local.git
cd demo-v1fs-local
```

### Step 2: Build the Docker Image

```bash
# Build the CLI-based scanner
docker build -f Dockerfile.cli -t tmfs-cli-scanner .
```

### Step 3: Test the Configuration

```bash
# Make the test script executable
chmod +x test-local-path.sh

# Run the test (this will create test files and verify everything works)
./test-local-path.sh
```

### Step 4: Start Real-time Monitoring

```bash
# Start monitoring your local path
docker run -d \
  --name tmfs-cli-monitor \
  --privileged \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -e ACTION=quarantine \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner monitor
```

## 📋 Detailed Setup Instructions

### 1. System Requirements

- **OS**: Linux, macOS, or Windows with Docker support
- **Docker**: Version 20.10 or higher
- **Memory**: Minimum 2GB RAM
- **Storage**: At least 5GB free space
- **Network**: Access to your Trend Micro endpoint

### 2. Install Docker

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### CentOS/RHEL:
```bash
sudo yum install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

#### macOS:
Download and install Docker Desktop from https://www.docker.com/products/docker-desktop

### 3. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/andrefernandes86/demo-v1fs-local.git
cd demo-v1fs-local

# Build the Docker image
docker build -f Dockerfile.cli -t tmfs-cli-scanner .

# Verify the build
docker images | grep tmfs-cli-scanner
```

### 4. Configure Your Environment

#### Option A: Local Endpoint (Recommended)

```bash
# Set environment variables for local endpoint
export TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051
export TM_TLS=false
export LOCAL_PATH=/mnt/nfs-share
export ACTION=quarantine
export SCAN_INTERVAL=30
```

#### Option B: Cloud Endpoint

Create a `.env` file:
```bash
TM_API_KEY=your_api_key_here
TM_REGION=us-1
LOCAL_PATH=/mnt/nfs-share
ACTION=quarantine
SCAN_INTERVAL=30
```

### 5. Create Your Target Directory

```bash
# Create the directory you want to monitor
sudo mkdir -p /mnt/nfs-share
sudo chmod 755 /mnt/nfs-share

# Optional: Create some test files
echo "This is a test file" > /mnt/nfs-share/test.txt
```

## 🔧 Usage Examples

### 1. Real-time Monitoring

#### Start Monitoring:
```bash
docker run -d \
  --name tmfs-cli-monitor \
  --privileged \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -e ACTION=quarantine \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner monitor
```

#### Check Status:
```bash
# View logs
docker logs -f tmfs-cli-monitor

# Check container status
docker ps | grep tmfs-cli-monitor
```

#### Stop Monitoring:
```bash
docker stop tmfs-cli-monitor
docker rm tmfs-cli-monitor
```

### 2. Single File Scan

```bash
# Scan a specific file
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner scan /mnt/nfs-share/suspicious-file.exe
```

### 3. Directory Scan

```bash
# Scan all files in a directory
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner scan-dir /mnt/nfs-share
```

### 4. Using Makefile (Easier)

```bash
# Start monitoring
make -f Makefile.cli monitor LOCAL_PATH=/mnt/nfs-share TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

# Scan a file
make -f Makefile.cli scan FILE=/mnt/nfs-share/file.txt LOCAL_PATH=/mnt/nfs-share TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

# Stop all containers
make -f Makefile.cli stop
```

## 🧪 Testing

### 1. Run the Test Suite

```bash
# Run comprehensive tests
./test-local-path.sh
```

### 2. Create Test Malware

```bash
# Create EICAR test file (safe test malware)
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /mnt/nfs-share/eicar.com.txt

# Scan it
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner scan /mnt/nfs-share/eicar.com.txt
```

## 🔍 Monitoring and Logs

### View Real-time Logs

```bash
# Follow container logs
docker logs -f tmfs-cli-monitor

# View last 100 lines
docker logs --tail 100 tmfs-cli-monitor
```

### Check Quarantined Files

```bash
# List quarantined files
ls -la /mnt/nfs-share/quarantine/

# View quarantine log
docker exec tmfs-cli-monitor cat /tmp/malicious_files_quarantined.log
```

### Monitor System Resources

```bash
# Check container resource usage
docker stats tmfs-cli-monitor

# Check disk usage
du -sh /mnt/nfs-share/
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Docker Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

#### 2. Container Can't Access Host Path
```bash
# Check if path exists and has correct permissions
ls -la /mnt/nfs-share/

# Ensure Docker has access
sudo chmod 755 /mnt/nfs-share/
```

#### 3. Endpoint Connection Issues
```bash
# Test endpoint connectivity
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  tmfs-cli-scanner help
```

#### 4. Container Won't Start
```bash
# Check container logs
docker logs tmfs-cli-monitor

# Check if port is in use
docker ps -a | grep tmfs-cli-monitor
```

### Debug Mode

```bash
# Run with debug output
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e DEBUG=true \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner monitor
```

## 📊 Performance Tuning

### Optimize Scan Performance

```bash
# Reduce scan interval for faster response
export SCAN_INTERVAL=10

# Use report_only mode for testing
export ACTION=report_only

# Start with optimized settings
docker run -d \
  --name tmfs-cli-monitor \
  --privileged \
  --memory=1g \
  --cpus=1.0 \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=10 \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner monitor
```

### Monitor Resource Usage

```bash
# Check memory and CPU usage
docker stats tmfs-cli-monitor

# Monitor disk I/O
iostat -x 1

# Check network usage
iftop
```

## 🔒 Security Considerations

### 1. Network Security
- Use TLS when possible
- Restrict network access to the endpoint
- Use VPN if scanning remote files

### 2. File Permissions
- Run container as non-root user
- Restrict file access permissions
- Use read-only mounts when possible

### 3. API Key Security
- Never commit API keys to version control
- Use environment variables or secrets management
- Rotate API keys regularly

## 📈 Production Deployment

### 1. Docker Compose Setup

Create `docker-compose.prod.yml`:
```yaml
version: '3.8'
services:
  tmfs-scanner:
    build:
      context: .
      dockerfile: Dockerfile.cli
    container_name: tmfs-cli-monitor
    restart: unless-stopped
    privileged: true
    environment:
      - TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051
      - TM_TLS=false
      - LOCAL_PATH=/mnt/nfs-share
      - ACTION=quarantine
      - SCAN_INTERVAL=30
    volumes:
      - /mnt/nfs-share:/mnt/nfs-share:shared
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### 2. Systemd Service

Create `/etc/systemd/system/tmfs-scanner.service`:
```ini
[Unit]
Description=Trend Micro File Security Scanner
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/demo-v1fs-local
ExecStart=/usr/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### 3. Log Rotation

Create `/etc/logrotate.d/tmfs-scanner`:
```
/var/lib/docker/containers/*/tmfs-cli-monitor-json.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

## 📞 Support

### Getting Help

1. **Check the logs**: `docker logs tmfs-cli-monitor`
2. **Run tests**: `./test-local-path.sh`
3. **Check documentation**: `README-CLI.md`
4. **GitHub Issues**: Create an issue on the repository

### Useful Commands

```bash
# Quick status check
docker ps | grep tmfs

# View all logs
docker logs tmfs-cli-monitor

# Restart the service
docker restart tmfs-cli-monitor

# Check disk usage
df -h /mnt/nfs-share/

# Monitor real-time
watch -n 1 'docker stats tmfs-cli-monitor'
```

## 🎯 Next Steps

1. **Test thoroughly** with your specific files and environment
2. **Monitor performance** and adjust settings as needed
3. **Set up alerts** for when malicious files are detected
4. **Integrate with your security tools** for centralized monitoring
5. **Document your specific configuration** for your team

---

**Repository**: https://github.com/andrefernandes86/demo-v1fs-local  
**Documentation**: See `README-CLI.md` for detailed technical information 