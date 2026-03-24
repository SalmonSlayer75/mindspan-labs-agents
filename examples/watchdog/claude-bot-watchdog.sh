#!/usr/bin/env bash
# claude-bot-watchdog — detects bots that have "baked" (session ended) and restarts them
#
# Run via cron every 5 minutes. A bot is considered idle if its tmux pane
# does NOT contain "Listening for channel messages" — meaning the conversation
# ended (context limit, crash, etc.) and claude is sitting at an empty prompt.
#
# Usage: claude-bot-watchdog.sh [work|personal|all]
#
# CUSTOMIZE: Update the BOT_* arrays below with your bot names, tmux sockets,
# start scripts, and Telegram bot tokens.

set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
export HOME="/home/yourusername"    # <-- CHANGE THIS

LOG="$HOME/.claude/channels/watchdog.log"

# --- CONFIGURE YOUR BOTS HERE ---
declare -A BOT_SOCKET BOT_SESSION BOT_SCRIPT BOT_TOKEN

BOT_SOCKET[work]="claude-work"
BOT_SESSION[work]="claude-work-bot"
BOT_SCRIPT[work]="$HOME/bin/claude-work-bot-start.sh"
BOT_TOKEN[work]="<your-work-bot-token>"    # <-- CHANGE THIS

BOT_SOCKET[personal]="claude-personal"
BOT_SESSION[personal]="claude-personal-bot"
BOT_SCRIPT[personal]="$HOME/bin/claude-personal-bot-start.sh"
BOT_TOKEN[personal]="<your-personal-bot-token>"    # <-- CHANGE THIS

CHAT_ID="<your-telegram-user-id>"    # <-- CHANGE THIS
# --- END CONFIGURATION ---

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

send_telegram() {
    local token="$1" text="$2"
    curl -s -X POST "https://api.telegram.org/bot${token}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${text}" \
        -d parse_mode="Markdown" \
        > /dev/null 2>&1
}

check_and_restart() {
    local name="$1"
    local socket="${BOT_SOCKET[$name]}"
    local session="${BOT_SESSION[$name]}"
    local script="${BOT_SCRIPT[$name]}"
    local token="${BOT_TOKEN[$name]}"

    # Check if tmux session exists at all
    if ! tmux -L "$socket" has-session -t "$session" 2>/dev/null; then
        log "[$name] tmux session not found — starting bot"
        tmux -L "$socket" new-session -d -s "$session" "$script"
        send_telegram "$token" "Bot was down — watchdog restarted it."
        return
    fi

    # Capture the tmux pane and check for active listening
    local pane_content
    pane_content=$(tmux -L "$socket" capture-pane -t "$session" -p -S -50 2>&1)

    if echo "$pane_content" | grep -q "Listening for channel messages"; then
        # Bot is actively listening — all good
        return 0
    fi

    if echo "$pane_content" | grep -q "Baked for"; then
        # Bot conversation ended — session baked out
        log "[$name] conversation baked — restarting"
        tmux -L "$socket" send-keys -t "$session" C-c
        sleep 2
        tmux -L "$socket" kill-session -t "$session" 2>/dev/null || true
        sleep 1
        # Clear the state-loaded flag so PreToolUse hook fires on new session
        rm -f "/tmp/${name}-state-loaded"
        tmux -L "$socket" new-session -d -s "$session" "$script"
        send_telegram "$token" "Bot hit context limit — watchdog restarted it. State file preserved."
        return
    fi

    # Bot is in a conversation (processing a message) — leave it alone
    # This covers the case where it's mid-reply and neither "Listening" nor "Baked" appears
}

# --- CONFIGURE YOUR BOT NAMES HERE ---
resolve_targets() {
    local target="${1:-all}"
    case "$target" in
        all) echo "work personal" ;;
        work|personal) echo "$target" ;;
        *) echo "Unknown bot: $target" >&2; exit 1 ;;
    esac
}

TARGET="${1:-all}"
for bot in $(resolve_targets "$TARGET"); do
    check_and_restart "$bot"
done
