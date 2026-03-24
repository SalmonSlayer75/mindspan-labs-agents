# WSL-Specific: Auto-Start on Windows Boot

If you're running Claude Code bots in WSL2, there's an extra step: WSL doesn't "boot" like a normal Linux system. It starts when you open a terminal or when Windows triggers it.

## The Setup

### 1. systemd services (same as native Linux)

Follow the base guide's Step 8 to create systemd user services. This works in WSL2 with systemd enabled.

### 2. Enable lingering (critical)

```bash
loginctl enable-linger $USER
```

Even more important in WSL than on native Linux — WSL sessions are more transient.

### 3. Windows Scheduled Task

Create a Windows Scheduled Task that runs on login to ensure WSL starts:

1. Open **Task Scheduler** on Windows
2. Create a new task:
   - **Trigger**: At log on
   - **Action**: Start a program
   - **Program**: `wsl`
   - **Arguments**: `-d Ubuntu -u yourusername -- systemctl --user start claude-work-bot.service`
3. Repeat for each bot service

Alternatively, create a simple batch script:

```bat
@echo off
wsl -d Ubuntu -u yourusername -- systemctl --user start claude-work-bot.service
wsl -d Ubuntu -u yourusername -- systemctl --user start claude-personal-bot.service
```

Save as `start-claude-bots.bat` and add it to Task Scheduler or your Windows Startup folder.

### 4. Keep WSL alive

By default, WSL may shut down after all terminals are closed. To prevent this:

```powershell
# In Windows Terminal or PowerShell:
wsl --update
```

Then create or edit `%UserProfile%\.wslconfig`:

```ini
[wsl2]
vmIdleTimeout=-1
```

This prevents WSL from auto-shutting down when idle.

## Troubleshooting

- **Bots not starting after Windows reboot**: Check that the WSL Scheduled Task ran (`Task Scheduler > History`)
- **systemd not available in WSL**: Make sure you have a recent WSL2 version with systemd enabled in `/etc/wsl.conf`:
  ```ini
  [boot]
  systemd=true
  ```
- **WSL shutting down unexpectedly**: Check `.wslconfig` for `vmIdleTimeout` setting
