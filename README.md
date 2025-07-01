# Trend Micro File Security Scanner

A simple Docker container for malware scanning and quarantine using Trend Micro Vision One CLI.

## 🚀 Quick Start

### 1. Clone and Test
```bash
git clone https://github.com/andrefernandes86/demo-v1fs-local.git
cd demo-v1fs-local

# Run tests to make sure everything works
./test.sh
```

### 2. Start Monitoring
```bash
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
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

## 📋 What It Does

- **Real-time Monitoring**: Continuously scans NFS shares for malware
- **Automatic Quarantine**: Moves malicious files to quarantine directory
- **Simple Setup**: Just run the test script and start monitoring
- **Mock CLI**: Uses a mock CLI for testing (replace with real CLI later)

## 🎯 Usage Examples

### Single File Scan
```bash
docker run --rm \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  -e MOUNT_PATH=/mnt/nfs \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner scan /mnt/nfs/file.txt
```

### Directory Scan
```bash
docker run --rm \
  -e TM_ENDPOINT=192.168.200.50:30230 \
  -e TM_TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  -e MOUNT_PATH=/mnt/nfs \
  -v /mnt/nfs:/mnt/nfs:shared \
  tmfs-scanner scan-dir /mnt/nfs
```

### Using Makefile
```bash
# Start monitoring
make monitor NFS_SERVER=192.168.200.10 NFS_SHARE=/mnt/nfs_share MOUNT_PATH=/mnt/nfs TM_ENDPOINT=192.168.200.50:30230 TM_TLS=false

# Stop all containers
make stop

# View logs
make logs
```

## ⚙️ Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `TM_ENDPOINT` | Trend Micro endpoint | `192.168.200.50:30230` |
| `TM_TLS` | Enable TLS | `false` |
| `NFS_SERVER` | NFS server IP | `192.168.200.10` |
| `NFS_SHARE` | NFS share path | `/mnt/nfs_share` |
| `MOUNT_PATH` | Mount point | `/mnt/nfs` |
| `ACTION` | Action for malicious files | `quarantine` |
| `SCAN_INTERVAL` | Monitoring interval (seconds) | `30` |

## 🔧 Actions

- `quarantine`: Move malicious files to quarantine directory
- `delete`: Permanently delete malicious files
- `report_only`: Log malicious files without taking action

## 🧪 Testing

The test script will:
1. Check if Docker is running
2. Build the Docker image
3. Test basic commands
4. Test monitoring functionality
5. Test NFS simulation

```bash
./test.sh
```

## 📁 Files

- `Dockerfile`: Simple Alpine-based Docker image
- `entrypoint.sh`: Main container logic
- `test.sh`: Comprehensive test suite
- `Makefile`: Easy commands and shortcuts
- `README.md`: This documentation

## 🚨 Important Notes

1. **Mock CLI**: This version uses a mock CLI for testing. Replace `/app/tmfs` in the Dockerfile with the real Trend Micro CLI for production use.

2. **NFS Mounting**: The container mounts NFS shares automatically when environment variables are set.

3. **Privileged Mode**: The container needs `--privileged` flag for NFS mounting.

## 🛠️ Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs tmfs-monitor

# Ensure --privileged flag is used
docker run --privileged ...
```

### NFS Mount Issues
```bash
# Check NFS server accessibility
showmount -e 192.168.200.10

# Test mount manually
sudo mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/test
```

### Permission Issues
```bash
# Check mount point permissions
ls -la /mnt/nfs/

# Fix permissions if needed
sudo chown -R 1000:1000 /mnt/nfs/
```

## 📞 Support

- **GitHub Issues**: Create an issue on this repository
- **Documentation**: Check [Trend Vision One CLI Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-deploying-cli)

## 📄 License

This project is provided as-is for educational and testing purposes. 