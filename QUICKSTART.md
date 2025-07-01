# 🚀 Quick Start Guide

This guide will help you quickly set up and run the Trend Vision One File Security Docker Container with NFS support and quarantine/delete options.

## 📋 Prerequisites

- Docker Engine 20.10+
- NFS Server (for NFS functionality)
- Trend Vision One endpoint or API key

## 🛠️ Quick Build

### Option 1: Build Both Versions (Recommended)
```bash
# Clone the repository
git clone <your-repo-url>
cd demo-v1fs-local

# Build both versions
./build.sh --both --test
```

### Option 2: Build Specific Version

#### **Go SDK Version (Local Endpoints)**
```bash
./build.sh --go-sdk --test
```

#### **CLI Version (Cloud Vision One)**
```bash
./build.sh --cli --test
```

## 🔧 Quick Configuration

### For Local Endpoints (Go SDK Version)
```bash
# Test with your local endpoint
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/file:/app/file:ro \
  tmfs-scanner scan /app/file
```

### For Cloud Vision One (CLI Version)
```bash
# Setup environment
make -f Makefile.cli setup
# Edit .env file with your TM_API_KEY

# Test with cloud endpoint
docker run --rm \
  --env-file .env \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file
```

## 🗂️ NFS Share Mapping

### Mount and Monitor NFS Share

#### **Go SDK Version**
```bash
# Start monitoring with NFS support
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -e ACTION=quarantine \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
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
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-cli-scanner monitor

# Check logs
docker logs -f tmfs-cli-monitor
```

## 🛡️ Action Modes

### Available Actions

| Action | Description | Use Case |
|--------|-------------|----------|
| `quarantine` | Move files to quarantine directory | **Recommended** - Safe, recoverable |
| `delete` | Permanently delete files | **Production** - Permanent removal |
| `report_only` | Log only, no action | **Testing** - Safe monitoring |

### Quick Examples

#### **Quarantine Mode (Default)**
```bash
docker run -d \
  --privileged \
  -e ACTION=quarantine \
  -e QUARANTINE_DIR=malware_quarantine \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner monitor
```

#### **Delete Mode**
```bash
docker run -d \
  --privileged \
  -e ACTION=delete \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner monitor
```

#### **Report Only Mode**
```bash
docker run -d \
  --privileged \
  -e ACTION=report_only \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner monitor
```

## 🧪 Quick Testing

### Test Local Endpoint
```bash
# Test with your working command
./test-local-endpoint.sh
```

### Test CLI Version
```bash
# Test CLI functionality
./test-cli.sh
```

### Test EICAR File
```bash
# Create EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.com.txt

# Test scan
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v $(pwd)/eicar.com.txt:/app/eicar.com.txt:ro \
  tmfs-scanner scan /app/eicar.com.txt
```

## 📊 Monitoring Dashboard

The real-time monitoring provides:

- **Live Status**: Current scan status and configuration
- **File Counters**: Malicious, quarantined, deleted, clean files
- **Latest Detection**: Most recent malicious file found
- **Action Logs**: Detailed logs of all actions taken

### View Monitoring Status
```bash
# Follow logs in real-time
docker logs -f tmfs-monitor

# View action logs
docker exec tmfs-monitor cat /tmp/malicious_files_quarantined.log
docker exec tmfs-monitor cat /tmp/malicious_files_deleted.log
```

## 🔧 Common Commands

### Single File Scan
```bash
# Go SDK Version
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/file:/app/file:ro \
  tmfs-scanner scan /app/file

# CLI Version
docker run --rm \
  --env-file .env \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file
```

### Directory Scan
```bash
# Go SDK Version
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v /path/to/directory:/app/dir:ro \
  tmfs-scanner scanfiles -path=/app/dir -good

# CLI Version
docker run --rm \
  --env-file .env \
  -v /path/to/directory:/app/dir:ro \
  tmfs-cli-scanner scan-dir /app/dir
```

### NFS Mode
```bash
# Start NFS support mode
docker run -d \
  --name tmfs-nfs \
  --privileged \
  tmfs-scanner nfs

# Mount NFS share
docker exec tmfs-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs

# Scan files on NFS
docker exec tmfs-nfs /app/tmfs scan file:/mnt/nfs/suspicious-file.exe --tls=false --addr=my-release-visionone-filesecurity-scanner:50051
```

## 🚨 Troubleshooting

### Common Issues

1. **NFS Mount Fails**
   ```bash
   # Ensure --privileged flag is used
   docker run --privileged ...
   
   # Check NFS server accessibility
   docker exec container showmount -e 192.168.200.10
   ```

2. **Permission Issues**
   ```bash
   # Check file permissions
   docker exec container ls -la /mnt/nfs
   ```

3. **Endpoint Connection**
   ```bash
   # Test endpoint connectivity
   docker exec container telnet my-release-visionone-filesecurity-scanner 50051
   ```

### Debug Mode
```bash
# Enable verbose output
docker run --rm \
  -e VERBOSE=true \
  -e DEBUG=true \
  tmfs-scanner scan /path/to/file
```

## 📚 Next Steps

1. **Read Full Documentation**: See [README.md](README.md) for detailed documentation
2. **Configure Production**: Set up proper logging and monitoring
3. **Test Thoroughly**: Verify scanner accuracy before using delete mode
4. **Backup Quarantine**: Regularly backup quarantine directory
5. **Monitor Logs**: Check action logs for false positives

## 🆘 Support

- **Issues**: Check repository issues
- **Documentation**: See README.md and README-CLI.md
- **Testing**: Use provided test scripts
- **Configuration**: Check environment variables documentation 