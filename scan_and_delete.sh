#!/bin/bash
# Trend Micro Vision One File Security – NFS Malware Cleaner
# Based on working implementation from tools-v1fs-scanner

# Default configuration
TMFS_API_KEY=${TMFS_API_KEY:-""}
NFS_SERVER=${NFS_SERVER:-"192.168.200.200"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nas/malicious-files"}
SCAN_PATH=${SCAN_PATH:-"/mnt/scan"}
LOG_FILE=${LOG_FILE:-"/tmp/deletion_log.txt"}
SCAN_OUTPUT=${SCAN_OUTPUT:-"/tmp/scan_output.txt"}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_alert() {
    echo -e "${RED}🚨 $1${NC}"
}

# Log function
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

echo "🧹 Trend Micro Vision One File Security – NFS Malware Cleaner"
echo "=============================================================="
echo "NFS Server: $NFS_SERVER"
echo "NFS Share: $NFS_SHARE"
echo "Scan Path: $SCAN_PATH"
echo "Log File: $LOG_FILE"
echo ""

# Check if API key is provided
if [ -z "$TMFS_API_KEY" ]; then
    print_error "TMFS_API_KEY environment variable is required"
    exit 1
fi

# Mount NFS share
log_action "Mounting NFS share $NFS_SERVER:$NFS_SHARE to $SCAN_PATH..."
if mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$SCAN_PATH"; then
    print_status "NFS share mounted successfully"
else
    print_error "Failed to mount NFS share"
    exit 1
fi

# Check if scan path exists and is accessible
if [ ! -d "$SCAN_PATH" ]; then
    print_error "Scan path does not exist: $SCAN_PATH"
    exit 1
fi

print_status "Scan path is accessible: $SCAN_PATH"

# Initialize log file
echo "=== Trend Micro Vision One File Security Scan Log ===" > "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"
echo "NFS Server: $NFS_SERVER" >> "$LOG_FILE"
echo "NFS Share: $NFS_SHARE" >> "$LOG_FILE"
echo "Scan Path: $SCAN_PATH" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Run TMFS scan
log_action "Running TMFS scan on $SCAN_PATH..."

# Find all files in the scan path
find "$SCAN_PATH" -type f | while read -r file; do
    if [ -f "$file" ]; then
        echo "Scanning: $file"
        log_action "Scanning: $file"
        
        # Run TMFS scan on the file
        scan_result=$(/app/tmfs scan "$file" 2>&1)
        echo "$scan_result" >> "$SCAN_OUTPUT"
        
        # Check if file is malicious
        if echo "$scan_result" | grep -q "malicious\|threat\|virus\|malware\|suspicious" || \
           echo "$scan_result" | grep -q "Risk Level: High\|Risk Level: Critical" || \
           echo "$scan_result" | grep -q "Status: malicious\|Status: threat"; then
            
            print_alert "MALICIOUS: $file"
            log_action "Malicious: $file"
            
            # Delete the malicious file
            if rm -f "$file"; then
                print_status "Deleted: $file"
                log_action "Deleted: $file"
            else
                print_error "Failed to delete: $file"
                log_action "Failed to delete: $file"
            fi
        else
            print_status "Clean: $file"
            log_action "Clean: $file"
        fi
    fi
done

log_action "Scan complete."
print_status "Scan completed. Check $LOG_FILE for details."

# Unmount NFS share
log_action "Unmounting NFS share..."
if umount "$SCAN_PATH"; then
    print_status "NFS share unmounted successfully"
else
    print_warning "Failed to unmount NFS share"
fi

echo ""
echo "📋 Summary:"
echo "Log file: $LOG_FILE"
echo "Scan output: $SCAN_OUTPUT"
echo "NFS share: $NFS_SERVER:$NFS_SHARE" 