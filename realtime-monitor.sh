#!/bin/bash
# Real-time malicious file monitoring using Trend Vision One CLI
# Supports: quarantine, delete, report_only
# Recursive scanning of all subdirectories

# Default values
NFS_SERVER=${NFS_SERVER:-"192.168.200.50"}
NFS_SHARE=${NFS_SHARE:-"/mnt/nfs-share"}
MOUNT_PATH=${MOUNT_PATH:-"/mnt/nfs"}
ACTION=${ACTION:-"quarantine"}
SCAN_INTERVAL=${SCAN_INTERVAL:-30}
QUARANTINE_DIR=${QUARANTINE_DIR:-"quarantine"}

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

echo "🛡️ Real-time Malicious File Monitor (CLI Version)"
echo "=================================================="
echo "NFS Server: $NFS_SERVER"
echo "NFS Share: $NFS_SHARE"
echo "Mount Path: $MOUNT_PATH"
echo "Action: $ACTION"
echo "Scan Interval: ${SCAN_INTERVAL}s"
echo "Recursive: Enabled (all subdirectories)"
echo ""

# Validate action parameter
case "$ACTION" in
    "quarantine"|"delete"|"report_only")
        print_status "Action mode: $ACTION"
        ;;
    *)
        print_error "Invalid action: $ACTION. Use: quarantine, delete, or report_only"
        exit 1
        ;;
esac

# Mount NFS share if not already mounted
if ! mountpoint -q "$MOUNT_PATH"; then
    echo "📁 Mounting NFS share..."
    if mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$MOUNT_PATH"; then
        print_status "NFS share mounted successfully"
    else
        print_error "Failed to mount NFS share"
        print_error "Note: Container needs to run with --privileged flag"
        exit 1
    fi
fi

print_status "NFS share is accessible: $MOUNT_PATH"

# Create quarantine directory if needed
if [ "$ACTION" = "quarantine" ]; then
    echo "📦 Creating quarantine directory..."
    mkdir -p "$MOUNT_PATH/$QUARANTINE_DIR"
    print_status "Quarantine directory ready: $MOUNT_PATH/$QUARANTINE_DIR"
fi

echo ""
echo "🔍 Starting real-time monitoring..."
echo "Scanning every ${SCAN_INTERVAL} seconds..."
echo "Recursive scanning enabled for all subdirectories"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Initialize last scan timestamp
touch /tmp/last_scan

# Monitoring loop
while true; do
    clear
    echo "🛡️ Real-time Malicious File Monitor (CLI Version)"
    echo "=================================================="
    echo "NFS Server: $NFS_SERVER"
    echo "NFS Share: $NFS_SHARE"
    echo "Mount Path: $MOUNT_PATH"
    echo "Action: $ACTION"
    echo "Scan Interval: ${SCAN_INTERVAL}s"
    echo "Recursive: Enabled (all subdirectories)"
    echo ""
    
    LATEST_MALICIOUS=""
    MALICIOUS_COUNT=0
    CLEAN_COUNT=0
    QUARANTINED_COUNT=0
    DELETED_COUNT=0
    REPORTED_COUNT=0
    
    echo "🔄 Scanning for files... ($(date))"
    # Scan every file, regardless of extension and modification time
    NEW_FILES=$(find "$MOUNT_PATH" -type f 2>/dev/null || true)
    if [ -n "$NEW_FILES" ]; then
        echo "📋 Found files to scan:"
        echo "$NEW_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                echo "  - $file"
                # Skip quarantine directory
                if echo "$file" | grep -q "/$QUARANTINE_DIR/"; then
                    echo "    ⏭️  Skipping (quarantine directory)"
                    continue
                fi
                # Scan the file using CLI
                echo "    🔍 Scanning..."
                SCAN_RESULT=$(/app/tmfs scan "$file" 2>&1 || true)
                
                # Parse CLI scan result for malicious detection
                # CLI typically returns JSON or structured output
                if echo "$SCAN_RESULT" | grep -q '"status":"malicious"\|"threat_level":"high"\|"malicious":true\|"risk":"high"' || \
                   echo "$SCAN_RESULT" | grep -q "MALICIOUS\|THREAT\|VIRUS\|MALWARE\|SUSPICIOUS" || \
                   echo "$SCAN_RESULT" | grep -q "Risk Level: High\|Risk Level: Critical"; then
                    
                    print_alert "MALICIOUS FILE DETECTED: $file"
                    echo "    Scan result: $SCAN_RESULT"
                    MALICIOUS_COUNT=$((MALICIOUS_COUNT+1))
                    LATEST_MALICIOUS="$file"
                    
                    case "$ACTION" in
                        "quarantine")
                            echo "    🚨 Quarantining file..."
                            FILENAME=$(basename "$file")
                            QUARANTINE_PATH="$MOUNT_PATH/$QUARANTINE_DIR/${FILENAME}.quarantined_$(date +%Y%m%d_%H%M%S)"
                            if mv "$file" "$QUARANTINE_PATH"; then
                                print_status "File quarantined: $file → $QUARANTINE_PATH"
                                echo "QUARANTINED: $file -> $QUARANTINE_PATH at $(date)" >> /tmp/malicious_files_quarantined.log
                                QUARANTINED_COUNT=$((QUARANTINED_COUNT+1))
                            else
                                print_error "Failed to quarantine: $file"
                            fi
                            ;;
                        "delete")
                            echo "    🗑️ Deleting malicious file..."
                            if rm -f "$file"; then
                                print_status "File deleted: $file"
                                echo "DELETED: $file at $(date)" >> /tmp/malicious_files_deleted.log
                                DELETED_COUNT=$((DELETED_COUNT+1))
                            else
                                print_error "Failed to delete: $file"
                            fi
                            ;;
                        "report_only")
                            echo "    📊 Reporting malicious file (no action taken)"
                            echo "REPORTED: $file at $(date)" >> /tmp/malicious_files_reported.log
                            REPORTED_COUNT=$((REPORTED_COUNT+1))
                            ;;
                    esac
                else
                    print_status "File is clean: $file"
                    CLEAN_COUNT=$((CLEAN_COUNT+1))
                fi
            fi
        done
    else
        echo "  No files to scan"
    fi
    echo ""
    echo "===== Scan Status ====="
    if [ -n "$LATEST_MALICIOUS" ]; then
        echo "🚨 Latest malicious file: $LATEST_MALICIOUS"
    else
        echo "No malicious files detected in last scan."
    fi
    echo "Malicious: $MALICIOUS_COUNT | Quarantined: $QUARANTINED_COUNT | Deleted: $DELETED_COUNT | Reported: $REPORTED_COUNT | Clean: $CLEAN_COUNT"
    echo "========================"
    
    # Update last scan timestamp
    touch /tmp/last_scan
    
    # Wait before next scan
    echo "⏳ Waiting ${SCAN_INTERVAL} seconds before next scan..."
    sleep "$SCAN_INTERVAL"
done 