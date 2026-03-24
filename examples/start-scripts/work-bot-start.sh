#!/usr/bin/env bash

# Full PATH — must include claude's location and bun's location.
# Adjust these paths to match where claude and bun are installed on this system.
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"

# Be explicit about HOME — systemd doesn't always set it
export HOME="/home/yourusername"    # <-- CHANGE THIS

# Points to the state directory with .env (bot token) and access.json (allowlist)
export TELEGRAM_STATE_DIR="$HOME/.claude/channels/telegram-work"

# Working directory = bot's identity (CLAUDE.md, state file, settings)
cd ~/src/my-work-project            # <-- CHANGE THIS

# --add-dir grants access to additional directories without changing working dir
# Add as many as needed for your use case
exec claude --channels plugin:telegram@claude-plugins-official \
  --add-dir ~/other-repo \
  --add-dir ~/shared-docs
