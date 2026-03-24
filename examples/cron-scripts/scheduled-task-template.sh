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

BOT_TOKEN="<your-bot-token>"    # <-- CHANGE THIS
CHAT_ID="<your-user-id>"        # <-- CHANGE THIS

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
RESULT=$(cd ~/my-project && claude -p \
    --mcp-config .mcp.json \
    --permission-mode dontAsk \
    "Your task prompt here. Be specific about what to check and how to format the response." 2>&1)

# Send result to Telegram (only if there's something to report)
if [ -n "$RESULT" ]; then
    send_telegram "$RESULT"
fi

# IMPORTANT:
# - Use `claude -p` (one-shot), NOT `claude --channels` (that would steal messages from the main bot)
# - Each cron script is an independent process — it starts, runs the prompt, exits
# - Log output with >> to a dedicated log file for debugging
# - The bot token here can be the same as your channel bot's token
