# Setting Up Claude Code as a 24/7 Telegram Agent

> **Context**: Peter set this up with his Claude and it works great. He asked me (Claude) to write this guide so others can replicate the setup. This guide is written for Claude to follow, with clear markers for steps that need the human's involvement.
>
> **What this gets you**: You message a Telegram bot from your phone, and Claude Code responds — with full access to your codebase, files, terminal, databases, and any automated agents you've built. It's like having Claude in your pocket 24/7. You can run two separate bots (work + personal) with completely isolated contexts.

---

## Prerequisites

Before starting, the human needs to have these in place:

- **Claude Code CLI** installed and authenticated (test by running `claude` in a terminal)
- **A Claude Max or Team subscription** — the bot uses the account's API quota
- **Linux with systemd** — this guide assumes Ubuntu/Debian, but any systemd-based distro works
- **A Telegram account** on the human's phone
- **tmux** installed (`sudo apt install tmux` if not already there)

The human does NOT need to install Bun manually — Claude Code will handle that when the plugin is installed.

**Ask the human**: "Do you have Claude Code installed and working? Can you run `claude` in a terminal and get a response? And do you have tmux installed?"

---

## Step 1: The Human Creates Telegram Bots

> **This step must be done by the human on their phone.** Claude cannot create Telegram bots.

Tell the human:

"Open Telegram on your phone and do the following:

1. Search for `@BotFather` and start a chat with it
2. Send the message `/newbot`
3. BotFather will ask for a display name — pick something like `Work Ops Bot`
4. BotFather will ask for a username — pick something like `yourname_work_bot` (must end in `bot`)
5. BotFather will respond with a **token** that looks like `1234567890:AAxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
6. **Copy that token and paste it to me** — I need it for the next step
7. If you want a second bot (personal), repeat the process with a different name

Also, I need your Telegram user ID. Message `@userinfobot` on Telegram and it will reply with your numeric ID (something like `1234567890`). Paste that to me too."

**Wait for the human to provide:**
- One or two bot tokens
- Their Telegram user ID

---

## Step 2: Install the Telegram Plugin

Check if Bun is installed first:

```bash
which bun
```

If not installed:
```bash
curl -fsSL https://bun.sh/install | bash
```

Then make sure the plugin is enabled. Edit `~/.claude/settings.json` (create it if it doesn't exist) and ensure it contains:

```json
{
  "enabledPlugins": {
    "telegram@claude-plugins-official": true
  }
}
```

If the file already has content, merge the `enabledPlugins` key into the existing JSON — don't overwrite the whole file.

---

## Step 3: Create the State Directories

Each bot needs its own isolated state directory. This is where the bot token, access control list, and message inbox live. **The directory name can be anything** — it's referenced by the `TELEGRAM_STATE_DIR` environment variable in the start script.

### For a single bot:

```bash
mkdir -p ~/.claude/channels/telegram
```

### For two bots (work + personal):

```bash
mkdir -p ~/.claude/channels/telegram-work
mkdir -p ~/.claude/channels/telegram-personal
```

### Save the bot tokens

Using the tokens the human provided in Step 1:

```bash
# Single bot:
echo 'TELEGRAM_BOT_TOKEN=<paste-token-here>' > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env

# Two bots:
echo 'TELEGRAM_BOT_TOKEN=<paste-work-token>' > ~/.claude/channels/telegram-work/.env
chmod 600 ~/.claude/channels/telegram-work/.env

echo 'TELEGRAM_BOT_TOKEN=<paste-personal-token>' > ~/.claude/channels/telegram-personal/.env
chmod 600 ~/.claude/channels/telegram-personal/.env
```

The `chmod 600` is important — it prevents other users on the system from reading the token.

### Set up access control

Using the Telegram user ID the human provided in Step 1:

```bash
# For each bot state directory, create access.json:
cat > ~/.claude/channels/telegram-work/access.json << EOF
{
  "dmPolicy": "allowlist",
  "allowFrom": ["<paste-user-id-here>"],
  "groups": {},
  "pending": {}
}
EOF
```

Repeat for the personal directory if using two bots.

**What this does**: `dmPolicy: allowlist` means only Telegram users whose IDs are in `allowFrom` can message the bot. Everyone else gets ignored. This is critical — without it, anyone who discovers your bot's username could run commands on your machine.

---

## Step 4: Create the Start Scripts

Create a `~/bin/` directory if it doesn't exist:

```bash
mkdir -p ~/bin
```

### Understanding what the start script does

The start script is small but every line matters:

1. **`export PATH=...`** — Ensures `claude` and `bun` are findable. When systemd or cron launches the script, your normal shell profile doesn't run, so PATH must be set explicitly. This is the #1 cause of "it works manually but not from systemd" issues.

2. **`export HOME=...`** — Some environments (notably systemd) don't always set HOME. Be explicit.

3. **`export TELEGRAM_STATE_DIR=...`** — This is the key to running multiple bots. The Telegram plugin reads its `.env` (bot token) and `access.json` (allowlist) from this directory. Each bot points to a different directory = completely separate identity and access control.

4. **`cd /path/to/project`** — This determines what Claude "sees." It will read `CLAUDE.md` files starting from this directory and walking up. All file paths are relative to here. **This is how you give each bot a different personality/context** — the work bot starts in your work codebase, the personal bot starts in your personal projects folder.

5. **`exec claude --channels plugin:telegram@claude-plugins-official`** — Launches Claude in channel mode. The `--channels` flag tells Claude to stay running and listen for messages from the Telegram plugin. `exec` replaces the shell process with claude (cleaner process tree).

### Work bot start script

Create `~/bin/claude-work-bot-start.sh`:

```bash
#!/usr/bin/env bash

# Full PATH — must include claude's location and bun's location.
# Adjust these paths to match where claude and bun are installed on this system.
# Common locations:
#   claude: ~/.local/bin/claude or ~/.claude/bin/claude
#   bun:    ~/.bun/bin/bun
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"

export HOME="/home/yourusername"    # <-- CHANGE THIS to the actual username

# Points to the state directory created in Step 3.
# This is what makes multi-bot isolation work.
export TELEGRAM_STATE_DIR="$HOME/.claude/channels/telegram-work"

# The working directory determines:
#   - Which CLAUDE.md instructions Claude reads
#   - Which files/codebase Claude can access
#   - Which agents Claude knows about
cd ~/src/my-work-project      # <-- CHANGE THIS to the actual work project path

exec claude --channels plugin:telegram@claude-plugins-official
```

```bash
chmod +x ~/bin/claude-work-bot-start.sh
```

### Personal bot start script (if using two bots)

Create `~/bin/claude-personal-bot-start.sh`:

```bash
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
export HOME="/home/yourusername"    # <-- CHANGE THIS
export TELEGRAM_STATE_DIR="$HOME/.claude/channels/telegram-personal"

cd ~/personal-projects        # <-- CHANGE THIS

exec claude --channels plugin:telegram@claude-plugins-official
```

```bash
chmod +x ~/bin/claude-personal-bot-start.sh
```

**Ask the human**: "What directory should the work bot start in? This is the project folder where your main codebase lives — Claude will be able to see and edit files there. And if you want a personal bot, what directory for that one?"

---

## Step 5: Test It Manually First

Before setting up auto-start, test that the bot actually works:

```bash
# Run the start script directly (not in background — you want to see errors)
~/bin/claude-work-bot-start.sh
```

You should see Claude start up. Then tell the human:

"Open Telegram on your phone and send a message to your bot (the @username you created with BotFather). Say something like 'hello'. You should get a response within a few seconds."

**If it works**: Great, Ctrl+C to stop it and move on to Step 6.

**If it doesn't work**, check these common issues:

1. **"bun: not found"** — Bun isn't on PATH. Run `which bun` to find it, then update the PATH export in the start script.
2. **"claude: not found"** — Same thing. Run `which claude` to find the actual path.
3. **Claude starts but no response on Telegram** — Check that the `.env` file has the correct token and `TELEGRAM_STATE_DIR` points to the right directory.
4. **"access denied" or message ignored** — Check `access.json` has the human's Telegram user ID in `allowFrom`.

---

## Step 6: Run It With tmux

tmux keeps the bot running after you close the terminal. Each bot gets its own tmux session AND its own tmux socket for full isolation.

```bash
# Start work bot in a detached tmux session
tmux -L claude-work new-session -d -s claude-work-bot ~/bin/claude-work-bot-start.sh

# Start personal bot (if using two bots)
tmux -L claude-personal new-session -d -s claude-personal-bot ~/bin/claude-personal-bot-start.sh
```

### Why `-L` (separate sockets) matters

Without `-L`, both tmux sessions share a single tmux server process. If that server crashes, BOTH bots die. With `-L claude-work` and `-L claude-personal`, each bot has its own tmux server. They can't affect each other.

This also matters for systemd (Step 8) — systemd tracks the tmux server process, and separate sockets prevent PID tracking confusion.

### Attaching to see what a bot is doing

```bash
# See the work bot's live Claude session
tmux -L claude-work attach -t claude-work-bot

# Detach without stopping: press Ctrl+B, then D

# See the personal bot
tmux -L claude-personal attach -t claude-personal-bot
```

---

## Step 7: Management Script

This is optional but very handy. See [examples/management/claude-bot](../examples/management/claude-bot) for a full management script that provides:

```bash
claude-bot status           # Check both bots
claude-bot start work       # Start work bot only
claude-bot stop all         # Stop both
claude-bot restart personal # Restart personal bot
claude-bot logs work        # Attach to work bot's live tmux session
```

---

## Step 8: Auto-Start on Boot with systemd

This makes the bots start automatically when the machine boots (or reboots). Without this, the human would have to manually run the start commands after every reboot.

### Create the service files

```bash
mkdir -p ~/.config/systemd/user
```

Create `~/.config/systemd/user/claude-work-bot.service`:

```ini
[Unit]
Description=Claude Code Telegram Bot - Work
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=forking
ExecStart=/usr/bin/tmux -L claude-work new-session -d -s claude-work-bot %h/bin/claude-work-bot-start.sh
ExecStop=/usr/bin/tmux -L claude-work kill-session -t claude-work-bot
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

**Note about `%h`**: This is systemd's variable for the user's home directory. It replaces the need to hardcode `/home/username`.

**Note about `Type=forking`**: This is critical. The `tmux ... -d` command forks (creates a background process) and exits. Without `Type=forking`, systemd thinks the service crashed immediately.

### Enable and start the services

```bash
# Reload systemd to pick up the new service files
systemctl --user daemon-reload

# Enable = start on boot. Start = start right now.
systemctl --user enable claude-work-bot.service
systemctl --user start claude-work-bot.service
```

### CRITICAL: Enable lingering

```bash
loginctl enable-linger $USER
```

**Why this matters**: By default, systemd kills all user services when the user logs out. `enable-linger` tells systemd to keep your services running even when you're not logged in. Without this, the bots die every time the human closes their SSH session or logs out of the desktop.

### Verify it's running

```bash
systemctl --user status claude-work-bot.service
```

You should see `Active: active (running)`. If it says `failed`, check the logs:

```bash
journalctl --user -u claude-work-bot.service -n 50
```

---

## Step 9: Giving the Bot Access to Your Agents and Tools

The Telegram bot is a full Claude Code session. It can do anything you could do at the terminal — read files, run commands, query databases, call APIs. The key is the **working directory** and **CLAUDE.md**.

### How it works

When the bot starts in `~/src/my-project/`, Claude reads:
- `~/src/my-project/CLAUDE.md` (if it exists)
- `~/src/CLAUDE.md` (if it exists)
- `~/CLAUDE.md` (if it exists)

These files tell Claude about your project, your conventions, your agents, your APIs. The more context you put in CLAUDE.md, the more useful the bot becomes.

### What to put in CLAUDE.md

At minimum, document:
- Where important files/logs/configs live
- Database connection strings (if applicable)
- API endpoints and how to authenticate
- Paths to agent scripts and their state files
- Any conventions the bot should follow

---

## Troubleshooting

### Bot doesn't respond to Telegram messages

1. **Is the claude process running?** `claude-bot status` or `ps aux | grep claude`
2. **Is the token correct?** Check the `.env` file in your state directory
3. **Is the user allowlisted?** Check `access.json` has the right Telegram user ID
4. **Is Bun on PATH?** The Telegram plugin runs as a Bun MCP server. If Bun isn't findable, the plugin silently fails. Attach to the tmux session and look for errors.

### "bun: not found" in the tmux session

Your start script's PATH doesn't include Bun's location. Find it:
```bash
which bun    # or: find ~ -name bun -type f 2>/dev/null
```
Then add that directory to the PATH export in your start script.

### systemd service fails immediately

Check the journal:
```bash
journalctl --user -u claude-work-bot.service -n 50
```

Common causes:
- **Missing `Type=forking`** — systemd thinks tmux crashed because it exits after forking
- **Wrong path in ExecStart** — verify `which tmux` and that the start script path is correct
- **tmux socket collision** — if a previous session didn't clean up, kill stale tmux servers: `tmux -L claude-work kill-server 2>/dev/null`

### Bot dies when I log out

You forgot `loginctl enable-linger $USER`. Run it and restart the services.

### Bot works but responds slowly

The bot uses your Claude API quota. If you're running other Claude sessions simultaneously (or automated agents via cron), they share the same quota. Slow responses usually mean API rate limiting.

### I want to update the bot's instructions without restarting

Edit the `CLAUDE.md` file in the working directory. The bot reads it fresh at the start of each conversation thread (not each message — each new thread). To force a re-read, restart the bot: `claude-bot restart work`.

### The bot can't find files I expect it to see

The bot can only see files relative to the working directory set in the start script (`cd` line). If you need it to see files outside that tree, either:
- Change the working directory to a parent that encompasses everything
- Add `--add-dir /path/to/other/dir` to the claude command in the start script

---

## Quick Reference

| Task | Command |
|------|---------|
| Start both bots | `claude-bot start all` |
| Stop both bots | `claude-bot stop all` |
| Check status | `claude-bot status` |
| See live bot session | `claude-bot logs work` |
| Detach from live session | `Ctrl+B` then `D` |
| Restart after config change | `claude-bot restart work` |
| Check systemd status | `systemctl --user status claude-work-bot` |
| View systemd logs | `journalctl --user -u claude-work-bot -n 50` |
| Find your Telegram user ID | Message `@userinfobot` on Telegram |
| Create a new bot | Message `@BotFather` on Telegram, send `/newbot` |

---

*Original guide by Peter Steinberger*
