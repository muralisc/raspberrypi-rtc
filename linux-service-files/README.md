# RTC Wake Halt Service

This systemd service sets the Raspberry Pi 5 RTC wake alarm and halts the system on a schedule.

## Files

- `rtc-wake-halt.sh` - Script that sets the RTC wake alarm and halts the system
- `rtc-wake-halt.service` - Systemd service unit
- `rtc-wake-halt.timer` - Systemd timer unit (runs every 30 minutes, excluding 8pm-midnight)

## Installation

1. Copy the script to `/usr/local/bin/`:
   ```bash
   sudo cp rtc-wake-halt.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/rtc-wake-halt.sh
   ```

2. Copy the service and timer files to systemd directory:
   ```bash
   sudo cp rtc-wake-halt.service /etc/systemd/system/
   sudo cp rtc-wake-halt.timer /etc/systemd/system/
   ```

3. Reload systemd daemon:
   ```bash
   sudo systemctl daemon-reload
   ```

4. Enable and start the timer:
   ```bash
   sudo systemctl enable rtc-wake-halt.timer
   sudo systemctl start rtc-wake-halt.timer
   ```

## Configuration

### Wake Duration

Edit the `WAKE_SECONDS` environment variable in `rtc-wake-halt.service`:
```ini
Environment="WAKE_SECONDS=3600"
```

Or override it without editing the file:
```bash
sudo systemctl edit rtc-wake-halt.service
```
Add:
```ini
[Service]
Environment="WAKE_SECONDS=7200"
```

### Schedule

The timer is currently set to run every 30 minutes from midnight to 8pm (not between 8pm and midnight). To change the schedule, edit `rtc-wake-halt.timer`:

- Every 30 minutes excluding 8pm-midnight (current): `OnCalendar=*-*-* 00..19:00,30:00`
- Every 30 minutes (all day): `OnCalendar=*:0/30`
- Every hour: `OnCalendar=hourly`
- Every 15 minutes: `OnCalendar=*:0/15`
- Daily at specific time: `OnCalendar=*-*-* 23:00:00`
- Every 6 hours: `OnCalendar=*-*-* 00,06,12,18:00:00`
- Weekly on Sunday: `OnCalendar=Sun *-*-* 23:00:00`
- Business hours only (9am-5pm, every 30 min): `OnCalendar=*-*-* 09..17:00,30:00`

After changing, reload:
```bash
sudo systemctl daemon-reload
sudo systemctl restart rtc-wake-halt.timer
```

## Usage

### Manual Trigger
Run the service immediately without waiting for the timer:
```bash
sudo systemctl start rtc-wake-halt.service
```

### Check Timer Status
```bash
sudo systemctl status rtc-wake-halt.timer
sudo systemctl list-timers rtc-wake-halt.timer
```

### View Logs

Logs are written to `/var/log/rtc-wake-halt.log`:

```bash
# View all logs
sudo cat /var/log/rtc-wake-halt.log

# Follow logs in real-time
sudo tail -f /var/log/rtc-wake-halt.log

# View last 50 lines
sudo tail -n 50 /var/log/rtc-wake-halt.log
```

You can also view via journalctl:
```bash
journalctl -u rtc-wake-halt.service -f
```

### Stop/Disable Timer
```bash
sudo systemctl stop rtc-wake-halt.timer
sudo systemctl disable rtc-wake-halt.timer
```

## Testing

Test the wake alarm without halting:
```bash
# Set a 60-second wake alarm
echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm
echo $(date -d '60 seconds' +%s) | sudo tee /sys/class/rtc/rtc0/wakealarm

# Check if alarm is set
cat /sys/class/rtc/rtc0/wakealarm
date -d @$(cat /sys/class/rtc/rtc0/wakealarm)
```

## How It Works

1. The timer triggers every 30 minutes from midnight to 8pm (skips 8pm-midnight)
2. The service runs the script which:
   - Clears any existing RTC wake alarm
   - Calculates wake time (current time + WAKE_SECONDS)
   - Sets the RTC wake alarm
   - Halts the system
3. The RTC wakes the Pi after the specified duration
4. On boot, the timer resumes and the cycle repeats

## Troubleshooting

### Check RTC device
```bash
ls -l /sys/class/rtc/
cat /sys/class/rtc/rtc0/name
```

### Verify RTC is working
```bash
sudo hwclock -r
```

### Check service logs
```bash
# Check the log file
sudo tail -f /var/log/rtc-wake-halt.log

# Or use journalctl
journalctl -u rtc-wake-halt.service
journalctl -u rtc-wake-halt.timer
```

### Verify timer is active
```bash
systemctl is-active rtc-wake-halt.timer
systemctl is-enabled rtc-wake-halt.timer
```

### Check next scheduled run
```bash
systemctl list-timers rtc-wake-halt.timer --all
```

### Common Issues

**Permission denied on RTC device or log file:**
- The service runs with `ReadWritePaths=/sys/class/rtc/rtc0 /var/log/rtc-wake-halt.log` to allow access
- Ensure the RTC device exists at `/sys/class/rtc/rtc0`
- Create the log file if it doesn't exist: `sudo touch /var/log/rtc-wake-halt.log`

**Wake alarm not triggering:**
- Verify RTC supports wake alarms: `cat /sys/class/rtc/rtc0/wakealarm`
- Check system power settings allow RTC wake
- Ensure the Pi is properly powered down (not in standby)

**Timer not running:**
- Check timer is enabled: `systemctl is-enabled rtc-wake-halt.timer`
- Verify timers.target is active: `systemctl is-active timers.target`
