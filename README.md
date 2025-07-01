# Trend Vision One File Security Docker Container

This Docker container provides a ready-to-use environment for the Trend Vision One™ File Security with NFS support and configurable endpoints. **Two versions available:**

- **Go SDK Version** (Original): For local endpoints and custom deployments
- **CLI Version** (New): For cloud Vision One services with official CLI

## 🚀 Quick Start

### Choose Your Version

#### **Option 1: Go SDK Version (Local Endpoints)**
```bash
# Build and test
make build
make test

# Run with local endpoint
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/file:/app/file:ro \
  tmfs-scanner scan /app/file
```

#### **Option 2: CLI Version (Cloud Vision One)**
```bash
# Setup environment
make -f Makefile.cli setup
# Edit .env file with your TM_API_KEY

# Build and test
make -f Makefile.cli build
make -f Makefile.cli test-local

# Run with cloud endpoint
docker run --rm \
  --env-file .env \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file
```

## 📋 Features

- **NFS Support**: Mount and scan files from NFS shares
- **Configurable Endpoints**: Specify custom File Security service endpoints
- **TLS Support**: Configurable TLS encryption
- **Multiple Scan Modes**: Single file, directory, and real-time monitoring
- **Action Modes**: Quarantine, delete, or report malicious files
- **Environment Variable Configuration**: Easy configuration via environment variables
- **Security**: Runs as non-root user
- **Real-time Monitoring**: Continuous file monitoring with configurable actions

## 🛠️ Building the Application

### Prerequisites
- Docker Engine 20.10+
- Docker Compose (optional)
- NFS Server (for NFS functionality)

### Build Commands

#### **Go SDK Version (Local Endpoints)**
```bash
# Build the container
docker build -t tmfs-scanner .

# Or using docker-compose
docker-compose build

# Or using Makefile
make build
```

#### **CLI Version (Cloud Vision One)**
```bash
# Build the CLI container
docker build -f Dockerfile.cli -t tmfs-cli-scanner .

# Or using docker-compose
docker-compose -f docker-compose.cli.yml build

# Or using Makefile
make -f Makefile.cli build
```

## 🔧 Configuration

### Environment Variables

#### **Go SDK Version**
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `ENDPOINT` | File Security service endpoint | `localhost:50051` | `my-release-visionone-filesecurity-scanner:50051` |
| `TLS` | Enable/disable TLS | `true` | `false` |
| `REGION` | Service region (cloud only) | `` | `us-east-1` |
| `APIKEY` | API key for authentication (cloud only) | `` | `your-api-key` |
| `ACTION` | Action for malicious files | `quarantine` | `delete`, `report_only` |
| `SCAN_INTERVAL` | Monitoring interval (seconds) | `30` | `60` |
| `QUARANTINE_DIR` | Quarantine directory name | `quarantine` | `malware_quarantine` |

#### **CLI Version**
| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TM_API_KEY` | Trend Vision One API key | - | **Yes** (for cloud) |
| `TM_REGION` | Vision One region | `us-east-1` | No |
| `TM_ENDPOINT` | Custom endpoint URL | - | No |
| `TM_TLS` | Enable TLS | `true` | No |
| `TM_TIMEOUT` | Request timeout (seconds) | `300` | No |
| `ACTION` | Action for malicious files | `quarantine` | No |
| `SCAN_INTERVAL` | Monitoring interval (seconds) | `30` | No |
| `QUARANTINE_DIR` | Quarantine directory name | `quarantine` | No |

## 🗂️ NFS Share Mapping

### Mounting NFS Shares

#### **Go SDK Version**
```bash
# Start container with NFS support
docker run -d \
  --name tmfs-nfs \
  --privileged \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner nfs

# Mount NFS share
docker exec tmfs-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs

# Scan files on NFS
docker exec tmfs-nfs /app/tmfs scan file:/mnt/nfs/suspicious-file.exe --tls=false --addr=my-release-visionone-filesecurity-scanner:50051
```

#### **CLI Version**
```bash
# Start container with NFS support
docker run -d \
  --name tmfs-cli-nfs \
  --privileged \
  --env-file .env \
  tmfs-cli-scanner nfs

# Mount NFS share
docker exec tmfs-cli-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs

# Scan files on NFS
docker exec tmfs-cli-nfs /app/tmfs-cli-wrapper.sh scan file:/mnt/nfs/suspicious-file.exe
```

### NFS Configuration
```bash
# NFS Server settings
NFS_SERVER=192.168.200.10
NFS_SHARE=/mnt/nfs_share

# Docker run with NFS support
docker run --privileged \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner monitor
```

## 🛡️ Action Modes (Quarantine/Delete)

### Available Actions

| Action | Description | Behavior |
|--------|-------------|----------|
| `quarantine` | Move malicious files to quarantine | Files moved to quarantine directory with timestamp |
| `delete` | Permanently delete malicious files | Files permanently removed from system |
| `report_only` | Log malicious files without action | Files logged but no action taken |

### Configuration Examples

#### **Quarantine Mode (Default)**
```bash
# Go SDK Version
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -e ACTION=quarantine \
  -e QUARANTINE_DIR=malware_quarantine \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-scanner monitor

# CLI Version
docker run --rm \
  --env-file .env \
  -e ACTION=quarantine \
  -e QUARANTINE_DIR=malware_quarantine \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-cli-scanner monitor
```

#### **Delete Mode**
```bash
# Go SDK Version
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -e ACTION=delete \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-scanner monitor

# CLI Version
docker run --rm \
  --env-file .env \
  -e ACTION=delete \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-cli-scanner monitor
```

#### **Report Only Mode**
```bash
# Go SDK Version
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -e ACTION=report_only \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-scanner monitor

# CLI Version
docker run --rm \
  --env-file .env \
  -e ACTION=report_only \
  -v /shared/files:/mnt/nfs:shared \
  tmfs-cli-scanner monitor
```

## 🔍 Usage Examples

### Single File Scanning

#### **Go SDK Version**
```bash
# Scan a local file
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/file:/app/file:ro \
  tmfs-scanner scan /app/file

# Using Makefile
make scan FILE=/path/to/file ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TLS=false
```

#### **CLI Version**
```bash
# Scan a local file
docker run --rm \
  --env-file .env \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file

# Using Makefile
make -f Makefile.cli scan FILE=/path/to/file
```

### Directory Scanning

#### **Go SDK Version**
```bash
# Scan a directory
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/directory:/app/dir:ro \
  tmfs-scanner scanfiles -path=/app/dir -good

# Using Makefile
make scan-dir DIR=/path/to/directory ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TLS=false
```

#### **CLI Version**
```bash
# Scan a directory
docker run --rm \
  --env-file .env \
  -v /path/to/directory:/app/dir:ro \
  tmfs-cli-scanner scan-dir /app/dir

# Using Makefile
make -f Makefile.cli scan-dir DIR=/path/to/directory
```

### Real-time Monitoring

#### **Go SDK Version**
```bash
# Start monitoring with NFS support
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=60 \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner monitor

# Check logs
docker logs -f tmfs-monitor
```

#### **CLI Version**
```bash
# Start monitoring with NFS support
docker run -d \
  --name tmfs-cli-monitor \
  --privileged \
  --env-file .env \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=60 \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-cli-scanner monitor

# Check logs
docker logs -f tmfs-cli-monitor
```

## 🧪 Testing

### Test Commands

#### **Go SDK Version**
```bash
# Run tests
make test

# Test NFS connectivity
./test-nfs-connectivity.sh

# Test with EICAR file
./test.sh
```

#### **CLI Version**
```bash
# Run tests
make -f Makefile.cli test

# Test local endpoint
make -f Makefile.cli test-local

# Test with CLI
./test-cli.sh
```

## 📊 Monitoring Dashboard

Both versions provide a real-time monitoring dashboard showing:

- Current scan status
- Latest malicious file detected
- Counters for malicious, quarantined, deleted, and clean files
- Scan interval and configuration
- Action mode (quarantine/delete/report)

## 📝 Log Files

Monitoring creates log files for tracking:

- `/tmp/malicious_files_quarantined.log` - Quarantined files
- `/tmp/malicious_files_deleted.log` - Deleted files  
- `/tmp/malicious_files_reported.log` - Reported files

## 🔧 Troubleshooting

### Common Issues

1. **NFS Mount Issues**
   ```bash
   # Ensure container runs with --privileged flag
   docker run --privileged ...
   
   # Check NFS server accessibility
   docker exec container showmount -e 192.168.200.10
   ```

2. **Permission Issues**
   ```bash
   # Check file permissions
   docker exec container ls -la /mnt/nfs
   
   # Ensure proper ownership
   docker exec container chown -R tmfs:tmfs /mnt/nfs
   ```

3. **Endpoint Connectivity**
   ```bash
   # Test endpoint connectivity
   docker exec container telnet my-release-visionone-filesecurity-scanner 50051
   ```

### Debug Mode

Enable debug output by setting environment variables:

```bash
# Enable verbose output
VERBOSE=true

# Enable debug logging
DEBUG=true
```

## 📚 Documentation

- **Go SDK Version**: See [README.md](README.md) for detailed documentation
- **CLI Version**: See [README-CLI.md](README-CLI.md) for CLI-specific documentation

## 🤝 Support

For issues related to:
- **Trend Vision One API**: Contact Trend Micro Support
- **Docker Container**: Check this repository's issues
- **NFS Configuration**: Check your NFS server configuration

## 📄 License

This project is provided as-is for educational and testing purposes. Please ensure compliance with Trend Micro's terms of service and your organization's security policies. 