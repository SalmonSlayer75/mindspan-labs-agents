#!/bin/bash
# WSL boot script — called by Windows Scheduled Task or Startup folder on logon
# Optionally starts local model server, then verifies systemd brought up the bots.

set -e

LOG="$HOME/.claude/channels/wsl-boot.log"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') WSL boot script started" >> "$LOG"

# Optional: Start local model server (e.g., Qwen, llama.cpp)
# Uncomment if you run a local model alongside your bots.
# "$HOME/bin/start-local-model.sh" >> "$LOG" 2>&1
# echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') Local model server ready" >> "$LOG"

# systemd services are enabled and start automatically via default.target.
# Give them a moment, then verify they're running:
sleep 5
for svc in claude-work-bot claude-personal-bot; do
  if systemctl --user is-active --quiet "$svc"; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') $svc: running" >> "$LOG"
  else
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') $svc: NOT running — attempting start" >> "$LOG"
    systemctl --user start "$svc" >> "$LOG" 2>&1
  fi
done

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') WSL boot complete" >> "$LOG"
