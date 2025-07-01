# Trend Vision One File Security Scanner

This Docker container provides a ready-to-use environment for the Trend Vision One™ CLI with local path support and configurable endpoints.



## Features

- **CLI-based**: Uses official Trend Vision One CLI instead of Go SDK
- **Local Path Support**: Monitor local host paths directly without NFS
- **Configurable Endpoints**: Specify custom Vision One regions or endpoints
- **TLS Support**: Configurable TLS encryption
- **Multiple Scan Modes**: Single file, directory, and real-time monitoring
- **Environment Variable Configuration**: Easy configuration via environment variables
- **Security**: Runs as non-root user
- **Real-time Monitoring**: Continuous file monitoring with configurable actions

## Prerequisites

1. **Trend Vision One API Key**: You need a valid API key from your Trend Vision One console
2. **Docker**: Docker Engine 20.10+ with docker-compose support
3. **Local endpoint** (optional): For local Trend Micro Vision One File Security

## Quick Start

### 1. Configure Your Environment

#### **For Cloud Vision One (API Key Required)**
Create a `.env` file in the project directory:

```bash
# Required: Your Trend Vision One API Key
TM_API_KEY=your-api-key-here

# Optional: Vision One Configuration
TM_REGION=us-east-1
TM_ENDPOINT=
TM_TLS=true
TM_TIMEOUT=300

# NFS Configuration (if using NFS)
NFS_SERVER=192.168.200.10
NFS_SHARE=/mnt/nfs_share

# Monitoring Configuration
ACTION=quarantine
SCAN_INTERVAL=30
QUARANTINE_DIR=quarantine
```

#### **For Local Endpoints (No API Key Required)**
No `.env` file needed. Use environment variables directly:

```bash
# Local endpoint configuration
TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051
TM_TLS=false
TM_TIMEOUT=300

# NFS Configuration (if using NFS)
NFS_SERVER=192.168.200.10
NFS_SHARE=/mnt/nfs_share

# Monitoring Configuration
ACTION=quarantine
SCAN_INTERVAL=30
QUARANTINE_DIR=quarantine
```

### 2. Build the Container

```bash
# Build using the Dockerfile
docker build -t tmfs-scanner .

# Or using docker-compose
docker-compose build
```

### 3. Basic Usage

#### Scan a Single File

```bash
# Scan a local file (Cloud Vision One)
docker run --rm \
  -e TM_API_KEY=your-api-key \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file

# Scan a local file (Local Endpoint)
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -v /path/to/file:/app/file:ro \
  tmfs-scanner scan /app/file

# Using environment file (Cloud Vision One)
docker run --rm \
  --env-file .env \
  -v /path/to/file:/app/file:ro \
  tmfs-cli-scanner scan /app/file
```

#### Scan a Directory

```bash
# Scan all files in a directory
docker run --rm \
  -e TM_API_KEY=your-api-key \
  -v /path/to/directory:/app/dir:ro \
  tmfs-cli-scanner scan-dir /app/dir
```

#### Start Real-time Monitoring

##### Using Local Host Path (Recommended)
```bash
# Start monitoring with local host path
docker run -d \
  --name tmfs-cli-monitor \
  --privileged \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-cli-scanner monitor

# Check logs
docker logs -f tmfs-cli-monitor
```

##### Using NFS Support
```bash
# Start monitoring with local path
docker run -d \
  --name tmfs-monitor \
  --privileged \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -e LOCAL_PATH=/mnt/nfs-share \
  -v /mnt/nfs-share:/mnt/nfs-share:shared \
  tmfs-scanner monitor

# Check logs
docker logs -f tmfs-cli-monitor
```

## Docker Compose Usage

### Start Monitoring Service

```bash
# Start the monitoring service
docker-compose -f docker-compose.cli.yml up -d

# Check service status
docker-compose -f docker-compose.cli.yml ps

# View logs
docker-compose -f docker-compose.cli.yml logs -f tmfs-cli-scanner
```

### Run a Single Scan

```bash
# Run a single scan and exit
docker-compose -f docker-compose.cli.yml --profile scan run --rm tmfs-cli-scan scan /app/files/eicar.com.txt
```

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TM_API_KEY` | Trend Vision One API key | - | **Yes** (for cloud) |
| `TM_REGION` | Vision One region | `us-east-1` | No (cloud only) |
| `TM_ENDPOINT` | Local endpoint URL | - | **Yes** (for local) |
| `TM_TLS` | Enable TLS | `true` | No (set to `false` for local) |
| `TM_TIMEOUT` | Request timeout (seconds) | `300` | No |
| `LOCAL_PATH` | Local host path to monitor | `/mnt/nfs-share` | No |
| `NFS_SERVER` | NFS server IP | `192.168.200.10` | No |
| `NFS_SHARE` | NFS share path | `/mnt/nfs_share` | No |
| `ACTION` | Action for malicious files | `quarantine` | No |
| `SCAN_INTERVAL` | Monitoring interval (seconds) | `30` | No |
| `QUARANTINE_DIR` | Quarantine directory name | `quarantine` | No |

### Supported Regions

| Region | Description |
|--------|-------------|
| `us-east-1` | US East |
| `eu-central-1` | Europe Central |
| `ap-southeast-1` | Asia Pacific Southeast 1 |
| `ap-southeast-2` | Asia Pacific Southeast 2 |
| `ap-northeast-1` | Asia Pacific Northeast 1 |
| `ap-south-1` | Asia Pacific South 1 |
| `me-central-1` | Middle East Central 1 |

### Action Modes

| Action | Description |
|--------|-------------|
| `quarantine` | Move malicious files to quarantine directory |
| `delete` | Permanently delete malicious files |
| `report_only` | Log malicious files without taking action |

## CLI Commands

The container supports all Trend Vision One CLI commands:

```bash
# Get CLI help
docker run --rm tmfs-cli-scanner help

# File scanning
docker run --rm tmfs-cli-scanner file scan /path/to/file
docker run --rm tmfs-cli-scanner file scan-dir /path/to/directory

# Other CLI commands
docker run --rm tmfs-cli-scanner <command> [options]
```

## Local Path Support

### Using Local Host Paths

The container can monitor local host paths directly without requiring NFS mounting. This is the recommended approach for most use cases.

#### Quick Start with Local Path

```bash
# Start monitoring a local host path
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

#### Using Makefile with Local Path

```bash
# Start monitoring with Makefile
make -f Makefile.cli monitor LOCAL_PATH=/mnt/nfs-share TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false

# Scan a single file
make -f Makefile.cli scan FILE=/mnt/nfs-share/suspicious-file.exe LOCAL_PATH=/mnt/nfs-share TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 TM_TLS=false
```

#### Test Local Path Configuration

```bash
# Run the test script
./test-local-path.sh
```

### Local Path Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `LOCAL_PATH` | Local host path to monitor | `/mnt/nfs-share` | No |

## NFS Support

### Mounting NFS Shares

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
docker exec tmfs-cli-nfs /app/tmfs-cli-wrapper.sh file scan /mnt/nfs/suspicious-file.exe
```

### NFS Troubleshooting

1. **Permission Issues**: Ensure container runs with `--privileged` flag
2. **Network Issues**: Verify NFS server is accessible from container
3. **Mount Failures**: Check NFS server configuration and exports

## Real-time Monitoring

### Features

- **Continuous Scanning**: Scans all files every configured interval
- **Recursive Scanning**: Scans all subdirectories
- **Configurable Actions**: Quarantine, delete, or report malicious files
- **Real-time Status**: Live status display with counters
- **Logging**: Detailed logs of all actions taken

### Monitoring Dashboard

The monitoring script provides a real-time dashboard showing:

- Current scan status
- Latest malicious file detected
- Counters for malicious, quarantined, deleted, and clean files
- Scan interval and configuration

### Log Files

Monitoring creates log files for tracking:

- `/tmp/malicious_files_quarantined.log` - Quarantined files
- `/tmp/malicious_files_deleted.log` - Deleted files  
- `/tmp/malicious_files_reported.log` - Reported files

## Security Considerations

1. **API Key Protection**: Never commit API keys to version control
2. **Network Security**: Use TLS when possible for API communication
3. **File Permissions**: Container runs as non-root user for security
4. **NFS Security**: Ensure NFS server has proper access controls

## Troubleshooting

### Common Issues

1. **API Key Errors**
   ```bash
   # Verify API key is set
   echo $TM_API_KEY
   
   # Test API key validity
   docker run --rm -e TM_API_KEY=your-key tmfs-cli-scanner file scan /dev/null
   ```

2. **Network Connectivity**
   ```bash
   # Test connectivity to Vision One
   docker run --rm tmfs-cli-scanner ping api.trendmicro.com
   ```

3. **NFS Mount Issues**
   ```bash
   # Check NFS server accessibility
   docker exec tmfs-cli-scanner showmount -e 192.168.200.10
   ```

4. **Permission Issues**
   ```bash
   # Check file permissions
   docker exec tmfs-cli-scanner ls -la /mnt/nfs
   ```

### Debug Mode

Enable debug output by setting environment variables:

```bash
# Enable verbose CLI output
TM_VERBOSE=true

# Enable debug logging
DEBUG=true
```

## Examples

### Example 1: Scan EICAR Test File

```bash
# Create EICAR test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.com.txt

# Scan the file (Cloud Vision One)
docker run --rm \
  -e TM_API_KEY=your-api-key \
  -v $(pwd)/eicar.com.txt:/app/eicar.com.txt:ro \
  tmfs-cli-scanner scan /app/eicar.com.txt

# Scan the file (Local Endpoint)
docker run --rm \
  -e TM_ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TM_TLS=false \
  -v $(pwd)/eicar.com.txt:/app/eicar.com.txt:ro \
  tmfs-cli-scanner scan /app/eicar.com.txt
```

### Example 2: Monitor Directory for Malware

```bash
# Start monitoring a directory
docker run -d \
  --name malware-monitor \
  --privileged \
  -e TM_API_KEY=your-api-key \
  -e ACTION=quarantine \
  -e SCAN_INTERVAL=60 \
  -v /shared/documents:/mnt/nfs:shared \
  tmfs-cli-scanner monitor

# Check status
docker logs malware-monitor
```

### Example 3: Batch Scan with Custom Region

```bash
# Scan multiple files in EU region
docker run --rm \
  -e TM_API_KEY=your-api-key \
  -e TM_REGION=eu-central-1 \
  -v /path/to/files:/app/files:ro \
  tmfs-cli-scanner scan-dir /app/files
```

## Support

For issues related to:

- **Trend Vision One API**: Contact Trend Micro Support
- **CLI Tool**: Check [Trend Vision One CLI Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-deploying-cli)
- **Docker Container**: Check this repository's issues

## License

This project is provided as-is for educational and testing purposes. Please ensure compliance with Trend Micro's terms of service and your organization's security policies. 