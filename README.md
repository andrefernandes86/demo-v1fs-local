# Trend Vision One File Security Scanner

A Docker container for real-time malware scanning and quarantine using Trend Micro Vision One File Security CLI with NFS support.

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Docker installed
- NFS server running at `192.168.200.50:/mnt/nfs-share`
- Trend Micro Vision One endpoint accessible

### 1. Clone and Build

```bash
git clone https://github.com/andrefernandes86/demo-v1fs-local.git
cd demo-v1fs-local
docker build -t tmfs-scanner .
```

### 2. Start Real-time Monitoring

```bash
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.50 \
  -e NFS_SHARE=/mnt/nfs-share \
  -e MOUNT_PATH=/mnt/nfs \
  -e ACTION=quarantine \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner monitor
```

### 3. Check Status

```bash
# View logs
docker logs -f tmfs-monitor

# Check container status
docker ps | grep tmfs-monitor
```

## 🔧 Features

- **🛡️ Real-time Monitoring**: Continuously scan NFS shares for malware
- **📦 Automatic Quarantine**: Move malicious files to quarantine directory
- **🔍 NFS Integration**: Mount and scan files from NFS server `192.168.200.50`
- **📝 Comprehensive Logging**: Detailed logs of all scan actions
- **⚙️ Easy Configuration**: Simple environment variable setup
- **🚨 Multiple Actions**: Quarantine, delete, or report only
- **🔄 Recursive Scanning**: Scan all subdirectories automatically

## 📋 Prerequisites

1. **Docker**: Docker Engine 20.10+ installed
2. **NFS Server**: Running at `192.168.200.50:/mnt/nfs-share`
3. **Trend Micro Endpoint**: Accessible at `192.168.200.50:30230`

## 🎯 Usage Examples

### Real-time Monitoring (Recommended)

```bash
# Start real-time monitoring with NFS
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.50 \
  -e NFS_SHARE=/mnt/nfs-share \
  -e MOUNT_PATH=/mnt/nfs \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=30 \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner monitor
```

### Single File Scan

```bash
# Scan a specific file
docker run --rm \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.50 \
  -e NFS_SHARE=/mnt/nfs-share \
  -e MOUNT_PATH=/mnt/nfs \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner scan /mnt/nfs/suspicious-file.exe
```

### Directory Scan

```bash
# Scan all files in a directory
docker run --rm \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.50 \
  -e NFS_SHARE=/mnt/nfs-share \
  -e MOUNT_PATH=/mnt/nfs \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner scan-dir /mnt/nfs
```

### Using Makefile (Easier)

```bash
# Start monitoring
make monitor NFS_SERVER=192.168.200.50 NFS_SHARE=/mnt/nfs-share MOUNT_PATH=/mnt/nfs TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false

# Scan a file
make scan FILE=/mnt/nfs/file.txt NFS_SERVER=192.168.200.50 NFS_SHARE=/mnt/nfs-share MOUNT_PATH=/mnt/nfs TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false

# Stop all containers
make stop

# View logs
make logs
```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TM_ENDPOINT` | Trend Micro endpoint URL | `192.168.200.50:30230` | Yes |
| `TM_TLS` | Enable TLS | `false` | No |
| `NFS_SERVER` | NFS server IP | `192.168.200.50` | Yes |
| `NFS_SHARE` | NFS share path | `/mnt/nfs-share` | Yes |
| `MOUNT_PATH` | Mount point inside container | `/mnt/nfs` | No |
| `ACTION` | Action for malicious files | `quarantine` | No |
| `SCAN_INTERVAL` | Monitoring interval (seconds) | `30` | No |
| `QUARANTINE_DIR` | Quarantine directory name | `quarantine` | No |

### Action Modes

| Action | Description |
|--------|-------------|
| `quarantine` | Move malicious files to quarantine directory |
| `delete` | Permanently delete malicious files |
| `report_only` | Log malicious files without taking action |

## 📁 Repository Structure

```
demo-v1fs-local/
├── Dockerfile              # Main Docker image
├── Makefile               # Easy commands and shortcuts
├── entrypoint.sh          # Container entrypoint script
├── realtime-monitor.sh    # Real-time monitoring script
├── test.sh               # Comprehensive test script
├── README.md             # This documentation
├── .gitignore           # Git ignore rules
└── .dockerignore        # Docker ignore rules
```

## 🧪 Testing

### Run the Test Suite

```bash
# Make test script executable
chmod +x test.sh

# Run comprehensive tests
./test.sh
```

### Test Real-time Monitoring

```bash
# Start monitoring for 10 seconds (test mode)
docker run --rm \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.50 \
  -e NFS_SHARE=/mnt/nfs-share \
  -e MOUNT_PATH=/mnt/nfs \
  -e ACTION=report_only \
  -e SCAN_INTERVAL=5 \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner monitor
```

## 🔍 Monitoring and Logs

### View Real-time Logs

```bash
# Follow container logs
docker logs -f tmfs-monitor

# View last 100 lines
docker logs --tail 100 tmfs-monitor
```

### Check Quarantined Files

```bash
# List quarantined files
ls -la /mnt/nfs/quarantine/

# View quarantine log
docker exec tmfs-monitor cat /tmp/malicious_files_quarantined.log
```

## 🛠️ Troubleshooting

### Common Issues

1. **NFS Mount Issues**
   ```bash
   # Check NFS server accessibility
   showmount -e 192.168.200.50
   
   # Test mount manually
   mount -t nfs 192.168.200.50:/mnt/nfs-share /mnt/test
   ```

2. **Container Won't Start**
   ```bash
   # Check container logs
   docker logs tmfs-monitor
   
   # Ensure --privileged flag is used
   docker run --privileged ...
   ```

3. **Permission Issues**
   ```bash
   # Check mount point permissions
   ls -la /mnt/nfs/
   
   # Ensure proper ownership
   sudo chown -R 1000:1000 /mnt/nfs/
   ```

## 📞 Support

- **GitHub Issues**: Create an issue on this repository
- **Trend Micro Support**: Contact Trend Micro for API issues
- **Documentation**: Check [Trend Vision One CLI Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-deploying-cli)

## 📄 License

This project is provided as-is for educational and testing purposes. Please ensure compliance with Trend Micro's terms of service and your organization's security policies. 