# Trend Vision One File Security Docker Container

This Docker container provides a ready-to-use environment for the Trend Vision One™ File Security Go SDK with NFS support and configurable endpoints.

## Features

- **NFS Support**: Mount and scan files from NFS shares
- **Configurable Endpoints**: Specify custom File Security service endpoints
- **TLS Support**: Configurable TLS encryption
- **Multiple Scan Modes**: Single file and batch file scanning
- **Environment Variable Configuration**: Easy configuration via environment variables
- **Security**: Runs as non-root user

## Quick Start

### Building the Container

```bash
# Build the container
docker build -t tmfs-scanner .

# Or using docker-compose
docker-compose build
```

### Basic Usage

#### 1. Scan a Single File

```bash
# Scan a local file
docker run --rm tmfs-scanner scan file:./eicar.com.txt \
  --tls=false \
  --endpoint=192.168.200.50:50051

# Using environment variables
docker run --rm \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -v $(pwd)/files:/app/files:ro \
  tmfs-scanner scan file:/app/files/eicar.com.txt
```

#### 2. Scan Multiple Files

```bash
# Scan a directory
docker run --rm \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -v $(pwd)/files:/app/files:ro \
  tmfs-scanner scanfiles -path=/app/files -good
```

#### 3. NFS Support Mode

```bash
# Start container with NFS support
docker run -d \
  --name tmfs-nfs \
  --privileged \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -v nfs-share:/mnt/nfs:shared \
  tmfs-scanner nfs

# Mount NFS share and scan files
docker exec tmfs-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs
docker exec tmfs-nfs /app/tmfs scan file:/mnt/nfs/suspicious-file.exe --tls=false --addr=192.168.200.50:50051
```

## Docker Compose Usage

### Start with NFS Support

```bash
# Start the scanner with NFS support
docker-compose up tmfs-scanner -d

# Execute scans in the running container
docker-compose exec tmfs-scanner /app/tmfs scan file:/app/files/eicar.com.txt --tls=false --addr=my-release-visionone-filesecurity-scanner:50051
```

### Run a Single Scan

```bash
# Run a single scan and exit
docker-compose run --rm tmfs-scan
```

## Configuration

### Vision One Regions and API Key

The Trend Vision One File Security service configuration depends on your deployment type:

#### **Local Deployment (No Region/API Key Required)**
For local endpoints like `192.168.200.50:50051`:
- **No API Key needed**
- **No Region needed**
- Just specify the `ENDPOINT` and set `TLS=false`

#### **Cloud Vision One Deployment (Region/API Key Required)**
For cloud-based Vision One services:
- **API Key**: A valid API key must be provided via `APIKEY` environment variable or `TM_AM_AUTH_KEY`
- **Region**: Must be one of the supported Vision One regions

#### Supported Regions:
| Region | Description |
|--------|-------------|
| `us-east-1` | US East |
| `eu-central-1` | Europe Central |
| `ap-southeast-1` | Asia Pacific Southeast 1 |
| `ap-southeast-2` | Asia Pacific Southeast 2 |
| `ap-northeast-1` | Asia Pacific Northeast 1 |
| `ap-south-1` | Asia Pacific South 1 |
| `me-central-1` | Middle East Central 1 |

### Environment Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `ENDPOINT` | File Security service endpoint | `localhost:50051` | `my-release-visionone-filesecurity-scanner:50051` |
| `TLS` | Enable/disable TLS | `true` | `false` |
| `REGION` | Service region (cloud only) | `` | `us-east-1`, `eu-central-1`, `ap-southeast-1`, `ap-southeast-2`, `ap-northeast-1`, `ap-south-1`, `me-central-1` |
| `APIKEY` | API key for authentication (cloud only) | `` | `your-api-key` |
| `PML` | Enable PML detection | `false` | `true` |
| `FEEDBACK` | Enable SPN feedback | `false` | `true` |
| `VERBOSE` | Enable verbose output | `false` | `true` |
| `ACTIVE_CONTENT` | Enable active content detection | `false` | `true` |
| `TAGS` | Comma-separated tags | `` | `prod,scan` |
| `DIGEST` | Enable digest calculation | `true` | `false` |
| `TM_AM_SCAN_TIMEOUT_SECS` | Scan timeout in seconds | `300` | `600` |
| `TM_AM_DISABLE_CERT_VERIFY` | Disable certificate verification | `0` | `1` |

### Command Line Options

The container supports all command line options from the original SDK:

```bash
# Available options for scan command
docker run tmfs-scanner scan file:filename.txt \
  --tls=false \
  --region=us-east-1 \
  --apikey=your-api-key \
  --pml \
  --feedback \
  --verbose \
  --active-content \
  --tag=prod,scan \
  --digest=false \
  --addr=my-release-visionone-filesecurity-scanner:50051

# Available options for scanfiles command
docker run tmfs-scanner scanfiles \
  --path=/app/files \
  --good \
  --parallel \
  --tls=false \
  --region=us-east-1 \
  --apikey=your-api-key \
  --pml \
  --feedback \
  --verbose \
  --active-content \
  --tag=prod,scan \
  --digest=false \
  --addr=my-release-visionone-filesecurity-scanner:50051

# Available Vision One regions:
# - us-east-1 (US East)
# - eu-central-1 (Europe Central)
# - ap-southeast-1 (Asia Pacific Southeast 1)
# - ap-southeast-2 (Asia Pacific Southeast 2)
# - ap-northeast-1 (Asia Pacific Northeast 1)
# - ap-south-1 (Asia Pacific South 1)
# - me-central-1 (Middle East Central 1)
```

## NFS Mounting

### Manual NFS Mount

```bash
# Start container with NFS support
docker run -d \
  --name tmfs-nfs \
  --privileged \
  tmfs-scanner nfs

# Mount NFS share
docker exec tmfs-nfs mount -t nfs nfs-server:/share /mnt/nfs

# Scan files from NFS
docker exec tmfs-nfs /app/tmfs scan file:/mnt/nfs/file.txt --tls=false --addr=my-release-visionone-filesecurity-scanner:50051
```

### Docker Compose with NFS

```yaml
version: '3.8'
services:
  tmfs-scanner:
    build: .
    privileged: true
    environment:
      - ENDPOINT=my-release-visionone-filesecurity-scanner:50051
      - TLS=false
    volumes:
      - nfs-share:/mnt/nfs:shared
    command: ["nfs"]
```

## Examples

### Example 1: Scan EICAR Test File

```bash
# Create test file
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.com.txt

# Scan the file
docker run --rm \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  -v $(pwd):/app/files:ro \
  tmfs-scanner scan file:/app/files/eicar.com.txt
```

### Example 2: Batch Scan with NFS

```bash
# Start NFS container
docker run -d --name tmfs-nfs --privileged tmfs-scanner nfs

# Mount NFS and scan directory
docker exec tmfs-nfs mount -t nfs 192.168.200.10:/mnt/nfs_share /mnt/nfs
docker exec tmfs-nfs /app/scanfiles -path=/mnt/nfs -good --tls=false --addr=my-release-visionone-filesecurity-scanner:50051
```

### Example 2.1: Interactive NFS Scanning

```bash
# Run the interactive NFS scanning script
./example-nfs-scan.sh
```

This script will:
1. Start a container with NFS support
2. Mount your NFS share (192.168.200.10/mnt/nfs_share)
3. Provide an interactive interface to scan files
4. Clean up the container when done

### Example 3: Production Configuration

```bash
docker run --rm \
  -e ENDPOINT=prod-visionone-filesecurity.company.com:50051 \
  -e TLS=true \
  -e APIKEY=your-production-api-key \
  -e REGION=us-east-1 \
  -e PML=true \
  -e VERBOSE=true \
  -e TAGS=prod,automated \
  -v /path/to/files:/app/files:ro \
  tmfs-scanner scan file:/app/files/suspicious.exe
```

### Example 4: Regional Configuration Examples

```bash
# US East Region
docker run --rm \
  -e ENDPOINT=visionone-filesecurity.us-east-1.company.com:50051 \
  -e REGION=us-east-1 \
  -e APIKEY=your-us-east-api-key \
  tmfs-scanner scan file:./test.txt

# Europe Central Region
docker run --rm \
  -e ENDPOINT=visionone-filesecurity.eu-central-1.company.com:50051 \
  -e REGION=eu-central-1 \
  -e APIKEY=your-eu-central-api-key \
  tmfs-scanner scan file:./test.txt

# Asia Pacific Southeast 1 Region
docker run --rm \
  -e ENDPOINT=visionone-filesecurity.ap-southeast-1.company.com:50051 \
  -e REGION=ap-southeast-1 \
  -e APIKEY=your-ap-southeast-1-api-key \
  tmfs-scanner scan file:./test.txt
```

## Troubleshooting

### Common Issues

1. **NFS Mount Fails**: Ensure the container is running with `--privileged` flag
2. **Connection Refused**: Check if the endpoint is correct and accessible
3. **TLS Errors**: Set `TLS=false` for testing or configure proper certificates
4. **Permission Denied**: Ensure files are readable by the container user

### Debug Mode

```bash
# Run with verbose logging
docker run --rm \
  -e VERBOSE=true \
  -e ENDPOINT=my-release-visionone-filesecurity-scanner:50051 \
  -e TLS=false \
  tmfs-scanner scan file:./test.txt
```

### Container Shell Access

```bash
# Access container shell for debugging
docker run -it --rm tmfs-scanner /bin/sh
```

## Security Considerations

- The container runs as a non-root user (`tmfs`)
- TLS is enabled by default for secure communication
- Use `--privileged` only when NFS mounting is required
- API keys should be provided via environment variables, not command line
- Consider using Docker secrets for sensitive configuration

## Real-time Malicious File Monitoring with Action Parameters

The container includes real-time monitoring capabilities that automatically detect and handle malicious files. You can specify the action as a Docker parameter:

### Monitor Command with Action Parameters

```bash
# Monitor with quarantine action (default)
docker run -d \
  --name tmfs-monitor \
  --privileged \
  --network host \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  tmfs-scanner:latest \
  monitor

# Monitor with specific action parameter
docker run -d \
  --name tmfs-monitor \
  --privileged \
  --network host \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  tmfs-scanner:latest \
  monitor --action=quarantine

# Monitor with delete action
docker run -d \
  --name tmfs-monitor \
  --privileged \
  --network host \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  tmfs-scanner:latest \
  monitor --action=delete

# Monitor with report only (no action taken)
docker run -d \
  --name tmfs-monitor \
  --privileged \
  --network host \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  tmfs-scanner:latest \
  monitor --action=report_only

# Monitor with custom parameters
docker run -d \
  --name tmfs-monitor \
  --privileged \
  --network host \
  -e ENDPOINT=192.168.200.50:50051 \
  -e TLS=false \
  -e NFS_SERVER=192.168.200.10 \
  -e NFS_SHARE=/mnt/nfs_share \
  tmfs-scanner:latest \
  monitor \
  --action=quarantine \
  --scan-interval=60 \
  --quarantine-dir=malware_quarantine
```

### Available Actions

#### **`quarantine`** (Default Action)
- **What it does**: Moves malicious files to a designated quarantine directory
- **File handling**: Files are renamed with timestamp and moved to quarantine folder
- **Recovery**: Quarantined files can be restored if they're false positives
- **Safety**: Files are isolated but not permanently lost
- **Logging**: All quarantine actions are logged with timestamps
- **Example**: `malware.exe` → `quarantine/malware.exe.quarantined_20241220_143022`

#### **`delete`** (Permanent Removal)
- **What it does**: Permanently deletes malicious files from the file system
- **File handling**: Files are immediately removed using `rm -f`
- **Recovery**: **Files cannot be recovered** - deletion is permanent
- **Safety**: Use with caution - ensure your scanner is accurate
- **Logging**: All deletion actions are logged for audit purposes
- **Example**: `malware.exe` → **permanently deleted**

#### **`report_only`** (Monitoring Only)
- **What it does**: Only reports malicious files without taking any action
- **File handling**: Files remain untouched in their original location
- **Recovery**: Files are never moved or deleted
- **Safety**: Safest option for testing and monitoring
- **Logging**: All detections are logged for analysis
- **Example**: `malware.exe` → **reported but left in place**

### Monitor Parameters

- **`--action=<action>`**: Specify the action (quarantine, delete, report_only)
- **`--nfs-server=<ip>`**: NFS server IP address
- **`--nfs-share=<path>`**: NFS share path
- **`--scan-interval=<seconds>`**: Scan interval in seconds (default: 30)
- **`--quarantine-dir=<dir>`**: Quarantine directory name (default: quarantine)

### How Real-time Monitoring Works

The monitoring system operates continuously with the following workflow:

#### **1. File Detection**
- **Scan Interval**: Checks for new files every 30 seconds (configurable)
- **File Types**: Monitors executable and script files that are commonly used for malware
- **Recursive Scanning**: Automatically scans all subdirectories in the NFS share
- **New File Detection**: Uses file timestamps to identify newly added files

#### **2. File Types Monitored**
The system focuses on these potentially malicious file types:
- **Executables**: `.exe`, `.dll`, `.com`, `.scr`, `.pif`, `.msi`
- **Scripts**: `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js`, `.wsf`, `.hta`
- **Java**: `.jar`
- **Registry**: `.reg`
- **Shortcuts**: `.lnk`

#### **3. Scanning Process**
1. **Mount NFS**: Automatically mounts the NFS share if not already mounted
2. **Find New Files**: Uses `find` command to locate new files with monitored extensions
3. **Scan Each File**: Sends each file to the Trend Vision One scanner
4. **Analyze Results**: Checks scan results for malicious indicators
5. **Take Action**: Executes the specified action (quarantine/delete/report)
6. **Log Actions**: Records all activities for audit purposes

#### **4. Action Execution**
- **Quarantine**: Moves file to quarantine directory with timestamp
- **Delete**: Permanently removes file from file system
- **Report**: Logs detection without modifying the file

#### **5. Logging and Audit**
- **Action Logs**: All actions are logged to `/tmp/malicious_files_*.log`
- **Console Output**: Real-time status updates with colored output
- **Error Handling**: Graceful handling of mount failures and scan errors

### Using Docker Compose
```bash
# Start monitoring with quarantine action
docker-compose up tmfs-scanner

# Start monitoring with delete action
docker-compose up tmfs-scanner-delete

# Start monitoring with report only
docker-compose up tmfs-scanner-report
```

### Monitoring Features
- **Real-time Detection**: Scans every 30 seconds for new files (configurable)
- **Recursive Scanning**: Automatically scans all subdirectories
- **File Types Monitored**: Executable and script files (.exe, .dll, .bat, .ps1, .vbs, .js, .jar, .msi, .com, .scr, .pif, .cmd, .reg, .wsf, .hta, .lnk)
- **Automatic Action**: Quarantine, delete, or report malicious files immediately
- **Logging**: All actions are logged for audit purposes
- **NFS Integration**: Works with your NFS share (192.168.200.10/mnt/nfs_share)
- **Scanner Integration**: Uses your scanner endpoint (192.168.200.50:50051)

### Monitoring Logs and Troubleshooting

#### **Viewing Monitoring Logs**
```bash
# View real-time monitoring logs
docker logs tmfs-monitor

# Follow logs in real-time
docker logs -f tmfs-monitor

# View specific action logs
docker exec tmfs-monitor cat /tmp/malicious_files_quarantined.log
docker exec tmfs-monitor cat /tmp/malicious_files_deleted.log
docker exec tmfs-monitor cat /tmp/malicious_files_reported.log
```

#### **Monitoring Status Indicators**
- 🟢 **Green**: File is clean
- 🟡 **Yellow**: Warning or skipped file
- 🔴 **Red**: Malicious file detected
- 🚨 **Alert**: Action taken (quarantine/delete)

#### **Common Monitoring Issues**
1. **NFS Mount Fails**: Check NFS server connectivity and permissions
2. **Scanner Connection**: Verify endpoint is accessible and scanner is running
3. **Permission Denied**: Ensure container has proper NFS mount permissions
4. **No Files Detected**: Check if files have monitored extensions

#### **Monitoring Best Practices**
- **Start with `report_only`**: Test monitoring without taking action
- **Monitor logs**: Regularly check action logs for false positives
- **Adjust scan interval**: Increase interval for large file systems
- **Backup quarantine**: Regularly backup quarantine directory
- **Test scanner**: Verify scanner accuracy before using delete action

## License

This project is based on the [Trend Vision One File Security Go SDK](https://github.com/trendmicro/tm-v1-fs-golang-sdk) which is licensed under MIT. 