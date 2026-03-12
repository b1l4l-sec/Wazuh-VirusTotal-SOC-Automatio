#!/bin/bash
# remove-threat.sh - Quarantine malicious files detected by VirusTotal
# Created for Wazuh SOC Lab Project

# Configuration
QUARANTINE_DIR="/var/ossec/quarantine"
LOG_FILE="/var/ossec/logs/active-responses.log"

# Read Wazuh alert JSON from stdin
read INPUT_JSON

# Extract file path from the alert
FILE_PATH=$(echo $INPUT_JSON | jq -r '.parameters.alert.syscheck.path')

# Generate timestamp
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Log the detection
echo "$(date '+%Y/%m/%d %H:%M:%S') remove-threat.sh: VirusTotal malware detected - File: $FILE_PATH" >> $LOG_FILE

# Check if file exists
if [ -f "$FILE_PATH" ]; then
    # Create quarantine directory if needed
    mkdir -p "$QUARANTINE_DIR"
    
    # Create quarantine filename with timestamp
    FILENAME=$(basename "$FILE_PATH")
    QUARANTINE_FILE="$QUARANTINE_DIR/${FILENAME}_${TIMESTAMP}_malware"
    
    # Move file to quarantine (safer than delete)
    mv "$FILE_PATH" "$QUARANTINE_FILE"
    
    # Set restrictive permissions (file cannot be executed)
    chmod 000 "$QUARANTINE_FILE"
    
    # Create metadata file for investigation
    cat > "${QUARANTINE_FILE}.info" << EOF
=== QUARANTINED FILE METADATA ===
Original Path: $FILE_PATH
Original Filename: $FILENAME
Quarantined At: $(date)
Quarantined By: Wazuh Active Response (VirusTotal Detection)
Timestamp: $TIMESTAMP

Alert Details:
$INPUT_JSON

===================================
For investigation or false positive recovery, contact SOC team.
EOF
    
    # Log successful quarantine
    echo "$(date '+%Y/%m/%d %H:%M:%S') remove-threat.sh: SUCCESS - File quarantined to: $QUARANTINE_FILE" >> $LOG_FILE
    
else
    # File not found (already deleted or moved)
    echo "$(date '+%Y/%m/%d %H:%M:%S') remove-threat.sh: WARNING - File not found: $FILE_PATH" >> $LOG_FILE
fi

exit 0
