# WSL-Specific: Auto-Start on Windows Boot

If you're running Claude Code bots in WSL2, there's an extra step: WSL doesn't "boot" like a normal Linux system. It starts when you open a terminal or when Windows triggers it.

## The Setup

### 1. systemd services (same as native Linux)

Follow the base guide's Step 8 to create systemd user services. This works in WSL2 with systemd enabled.

### 2. Enable lingering (critical)

```bash
loginctl enable-linger $USER
```

Even more important in WSL than on native Linux -- WSL sessions are more transient.

### 3. Boot script

Create a boot script that verifies services are running after WSL starts. See [examples/wsl-autostart/wsl-boot.sh](../examples/wsl-autostart/wsl-boot.sh).

The boot script:
- Optionally starts any local model servers you run alongside your bots
- Waits a moment for systemd to bring up services
- Checks each bot service and starts any that didn't come up automatically
- Logs everything to `~/.claude/channels/wsl-boot.log`

### 4. Trigger the boot script from Windows

You have two options:

#### Option A: Windows Startup folder (simplest)

Copy [examples/wsl-autostart/wsl-claude-bots.bat](../examples/wsl-autostart/wsl-claude-bots.bat) into your Windows Startup folder:

```
%AppData%\Microsoft\Windows\Start Menu\Programs\Startup\
```

The `start /min` flag launches WSL minimized so it doesn't pop up a terminal window on login. This runs every time you log in to Windows.

#### Option B: Windows Scheduled Task (more control)

1. Open **Task Scheduler** on Windows
2. Create a new task:
   - **Trigger**: At log on (or At startup if you want it even before login)
   - **Action**: Start a program
   - **Program**: `wsl.exe`
   - **Arguments**: `-d Ubuntu -e /home/yourusername/bin/wsl-boot.sh`
3. Under **Conditions**, uncheck "Start only if on AC power" (important for laptops)
4. Under **Settings**, check "Run task as soon as possible after a scheduled start is missed"

The Scheduled Task approach gives you more control (run at startup vs login, run whether or not user is logged on, etc.) but is more setup. The Startup folder approach is simpler and works well for most cases.

### 5. Keep WSL alive

By default, WSL may shut down after all terminals are closed. To prevent this:

Create or edit `%UserProfile%\.wslconfig`:

```ini
[wsl2]
vmIdleTimeout=-1
```

This prevents WSL from auto-shutting down when idle.

## Troubleshooting

- **Bots not starting after Windows reboot**: Check `~/.claude/channels/wsl-boot.log` for errors. Also check Task Scheduler History if using that approach.
- **systemd not available in WSL**: Make sure you have a recent WSL2 version with systemd enabled in `/etc/wsl.conf`:
  ```ini
  [boot]
  systemd=true
  ```
- **WSL shutting down unexpectedly**: Check `.wslconfig` for `vmIdleTimeout` setting
- **Boot script not found**: Make sure the path in the `.bat` file matches where you put `wsl-boot.sh`, and that it's executable (`chmod +x`)
