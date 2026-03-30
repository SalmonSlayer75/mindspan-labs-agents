#!/usr/bin/env bash
# Template for a scheduled Claude one-shot task
#
# This runs as a SEPARATE process from the channel bot.
# It uses `claude -p` (one-shot prompt mode) to run a task,
# then sends results to Telegram via the Bot API.
#
# Add to crontab:
#   */15 7-22 * * * ~/bin/my-scheduled-task.sh >> ~/.claude/channels/my-task.log 2>&1

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
export HOME="/home/yourusername"    # <-- CHANGE THIS

# Source credentials from env file (keeps tokens out of scripts)
source "$HOME/.claude/bot-credentials.env"
BOT_TOKEN="$BOT_TOKEN_1"           # <-- Use the right bot's token
CHAT_ID="$TELEGRAM_CHAT_ID"

# --- Concurrency control ---
# Prevents overlapping runs if a previous invocation is still running
# (e.g., Claude takes longer than the cron interval)
LOCKFILE="/tmp/$(basename "$0" .sh).lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "Already running — skipping"; exit 0; }

send_telegram() {
    local text="$1"
    # Telegram messages have a 4096 character limit
    if [ ${#text} -gt 4000 ]; then
        text="${text:0:3997}..."
    fi
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${text}" \
        -d parse_mode="Markdown" \
        > /dev/null 2>&1
}

# Run Claude one-shot with your task prompt
# --mcp-config: path to MCP server config (for Gmail, Calendar, etc.)
# --permission-mode dontAsk: auto-approve tool calls (safe for automated tasks)
# --max-turns 30: allow multi-step tool use (default is low for -p mode)
#
# Stderr is captured to a temp file for diagnostics (NOT sent to /dev/null)
ERRLOG=$(mktemp)
RESULT=$(cd ~/AgentWorkspace && claude -p \
    --max-turns 30 \
    --mcp-config .mcp.json \
    --permission-mode dontAsk \
    "Your task prompt here. Be specific about what to check and how to format the response." 2>"$ERRLOG")
EXIT_CODE=$?

# Send result to Telegram, with error diagnostics
if [ $EXIT_CODE -ne 0 ] || [ -z "$RESULT" ]; then
    echo "Exit code: $EXIT_CODE"
    echo "Stderr: $(cat "$ERRLOG")"
    echo "Result length: ${#RESULT}"
    send_telegram "Scheduled task failed — check the log file"
elif [ -n "$RESULT" ]; then
    echo "OK — sent result (${#RESULT} chars)"
    send_telegram "$RESULT"
fi
rm -f "$ERRLOG"

# IMPORTANT:
# - Use `claude -p` (one-shot), NOT `claude --channels` (that would steal messages from the main bot)
# - Each cron script is an independent process — it starts, runs the prompt, exits
# - Log output with >> to a dedicated log file for debugging
# - The bot token here can be the same as your channel bot's token
# - flock prevents overlapping runs if Claude takes longer than the cron interval
# - Capture stderr to a temp file so you can diagnose failures (don't use 2>/dev/null)
