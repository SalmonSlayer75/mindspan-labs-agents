# Cron Jobs: Scheduled One-Shot Tasks

The base Telegram agent setup gives you a reactive bot — it responds when you message it. But what if you want the bot to do things **proactively** on a schedule? Morning briefings, email checks, PR monitoring, weekly reports?

## The Approach: Separate One-Shot Processes

Each scheduled task is a bash script that:
1. Runs `claude -p` (one-shot prompt mode, NOT channel mode)
2. Sends results to Telegram via the Bot API directly (curl)
3. Logs output to a dedicated file

**Important**: These are completely independent from the channel bot. The channel bot stays running for interactive messages; cron scripts fire and exit.

## Template

See [examples/cron-scripts/scheduled-task-template.sh](../examples/cron-scripts/scheduled-task-template.sh) for a complete template.

The key pattern:

```bash
# Run Claude one-shot with the task prompt
RESULT=$(cd ~/my-project && claude -p \
    --mcp-config .mcp.json \
    --permission-mode dontAsk \
    "Your task prompt here." 2>&1)

# Send result to Telegram
if [ -n "$RESULT" ]; then
    send_telegram "$RESULT"
fi
```

## Example Crontab

```cron
# Morning brief — daily 7am
0 7 * * * ~/bin/morning-brief.sh >> ~/.claude/channels/morning.log 2>&1

# Email check — every 15 min, 7am-10pm
*/15 7-22 * * * ~/bin/check-email.sh >> ~/.claude/channels/email-check.log 2>&1

# PR watcher — every 30 min, 8am-10pm
*/30 8-22 * * * ~/bin/pr-watch.sh >> ~/.claude/channels/pr-watch.log 2>&1

# Weekly report — Friday 3pm
0 15 * * 5 ~/bin/weekly-report.sh >> ~/.claude/channels/weekly.log 2>&1

# Watchdog — every 5 min (see watchdog docs)
*/5 * * * * ~/bin/claude-bot-watchdog.sh all >> ~/.claude/channels/watchdog.log 2>&1
```

## Gotchas

- **Never use `--channels` in cron scripts** — that would start another channel listener and steal messages from the main bot
- **Use `--permission-mode dontAsk`** — cron scripts run unattended, so they need auto-approval for tool calls
- **Use `--mcp-config`** if your task needs MCP tools (Gmail, Calendar, etc.)
- **Log everything** — redirect both stdout and stderr to a log file for debugging
- **Telegram message limit is 4096 characters** — truncate long results before sending
- Cron scripts share the same API quota as the channel bot — too many concurrent tasks can cause rate limiting
