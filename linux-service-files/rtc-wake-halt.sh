#!/bin/bash
# Script to set RTC wake alarm and halt the Raspberry Pi 5

# Configuration
WAKE_SECONDS=${WAKE_SECONDS:-3600}  # Default: wake after 1 hour (3600 seconds)
RTC_DEVICE="/sys/class/rtc/rtc0"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | systemd-cat -t rtc-wake-halt -p info
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if RTC device exists
if [ ! -d "$RTC_DEVICE" ]; then
    log "ERROR: RTC device not found at $RTC_DEVICE"
    exit 1
fi

# Clear any existing wake alarm
log "Clearing existing wake alarm..."
echo 0 > "$RTC_DEVICE/wakealarm" 2>/dev/null || true

# Calculate wake time (current time + WAKE_SECONDS)
CURRENT_TIME=$(date +%s)
WAKE_TIME=$((CURRENT_TIME + WAKE_SECONDS))

# Set the wake alarm
log "Setting RTC wake alarm to $WAKE_SECONDS seconds from now..."
log "Current time: $(date -d @$CURRENT_TIME)"
log "Wake time: $(date -d @$WAKE_TIME)"

if echo "$WAKE_TIME" > "$RTC_DEVICE/wakealarm"; then
    log "Wake alarm set successfully"

    # Verify the alarm was set
    ALARM_SET=$(cat "$RTC_DEVICE/wakealarm" 2>/dev/null)
    if [ -n "$ALARM_SET" ]; then
        log "Verified: Wake alarm is set to $(date -d @$ALARM_SET)"
    fi
else
    log "ERROR: Failed to set wake alarm"
    exit 1
fi

# Halt the system
log "Halting system..."
sleep 2  # Give logs time to flush
systemctl halt
