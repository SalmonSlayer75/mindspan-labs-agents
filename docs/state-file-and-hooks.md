# Persistent Memory: State File + Hooks

The biggest problem with running Claude Code as a 24/7 Telegram agent is **memory loss**. When a conversation hits the context limit, the session ends and restarts fresh. Everything discussed — action items, decisions, pending tasks — is gone.

This guide shows how to give your bot persistent working memory that survives session restarts.

## The Problem

Claude Code channel sessions have a finite context window. When it fills up, the session "bakes" (ends) and goes idle. After restart, it's a blank slate. The bot literally forgets what you were just talking about.

## Why "Save at End of Session" Doesn't Work

We tried adding CLAUDE.md instructions like: "At the end of each meaningful interaction, save context to a log file."

This fails because:
- The bot often hits the context limit **unexpectedly** — the session dies before it gets a chance to write
- It relies on the bot **remembering** to do something before an event it can't predict
- It's too passive — "at the end of" is a weak instruction for an LLM

## The Solution: Three Layers

### Layer 1: Structured State File

Create a markdown file in your bot's working directory that serves as its working memory:

```markdown
# Bot State
<!-- Auto-updated after every substantive interaction. Read at conversation start. -->
<!-- Last updated: YYYY-MM-DDTHH:MMZ -->

## Open Threads
<!-- Active conversations or tasks in progress. Remove when resolved. -->

## Pending Action Items
<!-- Format: - [ ] [item] | owner: [who] | due: [date] | source: [where] -->

## Recent Decisions (last 7 days)
<!-- Format: - [decision] (YYYY-MM-DD) -->

## Waiting On Human
<!-- Things the bot needs human input on before proceeding -->

## Context Carry-Forward
<!-- Important context from recent conversations that would be lost on restart -->
```

See [examples/state-files/](../examples/state-files/) for templates.

### Layer 2: Aggressive CLAUDE.md Instructions

Add this to your bot's CLAUDE.md:

```markdown
- **CRITICAL — Maintain state across restarts:** Your conversation WILL end unexpectedly
  (context limit, crash, restart). You WILL lose everything in your conversation history.
  The ONLY thing that survives is what you write to disk. To compensate:
  - **Read your state file at the START of every conversation** — this is your working memory
  - **Update it IMMEDIATELY after every substantive interaction** — do NOT wait until
    session end, because session end may never come
  - After every Telegram exchange where something was decided, requested, or committed to:
    update the state file RIGHT THEN
  - Prune "Recent Decisions" older than 7 days; prune "Context Carry-Forward" older than 3 days
```

Key principles:
- **"WILL end unexpectedly"** — urgency matters for LLM instruction-following
- **"IMMEDIATELY after"** — write after each exchange, not at session end
- **Explicit pruning rules** — prevent unbounded growth

### Layer 3: Hooks (Automated Nudges)

Instructions alone aren't enough. Use Claude Code hooks to inject system-level reminders that fire every time the bot sends a Telegram message.

Add to your project's `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__plugin_telegram_telegram__reply",
        "hooks": [
          {
            "type": "command",
            "command": "if [ ! -f /tmp/mybot-state-loaded ]; then echo '[STARTUP] Read ~/myproject/bot-state.md FIRST to restore your working memory before replying.'; touch /tmp/mybot-state-loaded; fi"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "mcp__plugin_telegram_telegram__reply",
        "hooks": [
          {
            "type": "command",
            "command": "echo '[STATE REMINDER] You just sent a Telegram reply. If this interaction involved any decisions, action items, commitments, or important context — update ~/myproject/bot-state.md NOW before doing anything else.'"
          }
        ]
      }
    ]
  }
}
```

**How it works:**
- **PreToolUse** fires before the first Telegram reply of a new session. A `/tmp/` flag file tracks whether the bot has read its state file this session. Flag resets on reboot.
- **PostToolUse** fires after **every** Telegram reply — a constant nudge to update state.

See [examples/hooks/settings.local.json](../examples/hooks/settings.local.json) for a complete example.

## How the Layers Work Together

1. **Bot starts** (fresh session, no context)
2. **PreToolUse hook fires** → "Read your state file first!"
3. Bot reads state file → knows what was happening before the restart
4. Bot replies to the user on Telegram
5. **PostToolUse hook fires** → "Update your state file NOW!"
6. Bot writes any new decisions/items/context to state file
7. Repeat 4-6 for every interaction
8. Session eventually bakes → state file is already up to date
9. Go to step 1

The key insight (borrowed from [OpenClaw](https://openclaw.ai/)): **don't rely on the bot to remember — remind it mechanically.**
