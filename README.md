# Claude Code Telegram Agent — Production Config

Battle-tested configuration for running Claude Code as a 24/7 Telegram agent with persistent memory, automatic recovery, scheduled tasks, and 38 reusable agent skills.

## What This Is

We run two Claude Code bots on a single machine via Telegram — a **Chief of Staff** (email, calendar, research, admin) and a **VP of Engineering** (code review, PRs, architecture, CI). After several weeks in production, we hit real problems and built solutions for each one. This repo contains those solutions as reusable templates.

**What you get**: You message a Telegram bot from your phone, and Claude Code responds — with full access to your codebase, files, terminal, databases, and any MCP tools you've configured. It remembers what you were working on across session restarts, proactively does things on a schedule, and auto-recovers when it hits context limits.

---

## The Problems We Solved

| # | Problem | Solution | Docs |
|---|---------|----------|------|
| 1 | **Bot forgets everything after restart** — context window fills up, session "bakes", all conversation history is lost | Structured state file + Claude Code hooks that nudge the bot to save/load state | [State File & Hooks](docs/state-file-and-hooks.md) |
| 2 | **No scheduled/proactive behavior** — bot only responds when messaged | Cron scripts running `claude -p` one-shots, independent of the channel bot | [Cron Jobs](docs/cron-jobs.md) |
| 3 | **Bot can't access files outside working directory** | `--add-dir` flags in start scripts | [Start Scripts](examples/start-scripts/) |
| 4 | **Multiple bots producing conflicting information** | Explicit role boundaries and redirect rules in CLAUDE.md | [Role Isolation](docs/role-isolation.md) |
| 5 | **Bot reports "RUNNING" but is actually dead** — tmux session exists but Claude is idle at the prompt | Watchdog cron that inspects the tmux pane and auto-restarts baked bots | [Watchdog](examples/watchdog/) |
| 6 | **WSL doesn't auto-start bots on Windows reboot** | Windows Scheduled Task + systemd + lingering | [WSL Auto-Start](docs/wsl-autostart.md) |

---

## Quick Start

### New setup? Start here:
1. Follow the [Base Setup Guide](docs/base-setup-guide.md) to get a working Telegram bot

### Already have a working bot? Add these in order:

**Priority 1 — Watchdog** (5 min, biggest reliability win):
- Copy [examples/watchdog/claude-bot-watchdog.sh](examples/watchdog/claude-bot-watchdog.sh)
- Customize the bot names, tmux sockets, and tokens
- Add to crontab: `*/5 * * * * ~/bin/claude-bot-watchdog.sh all >> ~/.claude/channels/watchdog.log 2>&1`
- Your bot will now auto-recover within 5 minutes of hitting context limits

**Priority 2 — Persistent Memory** (10 min, OpenClaw-style state):
- Copy a [state file template](examples/state-files/) into your project directory
- Add the [CLAUDE.md instructions](docs/state-file-and-hooks.md#layer-2-aggressive-claudemd-instructions) to your bot's CLAUDE.md
- Add the [hooks config](examples/hooks/settings.local.json) to your project's `.claude/settings.local.json`
- Your bot will now remember action items, decisions, and context across restarts

**Priority 3 — Scheduled Tasks** (15 min per task):
- Copy the [cron script template](examples/cron-scripts/scheduled-task-template.sh)
- Customize the prompt and delivery method
- Add to crontab
- Your bot will now do things proactively without being asked

**Priority 4 — Agent Skills** (drop-in):
- Browse [examples/agent-skills/](examples/agent-skills/) for reusable slash commands
- Copy any `.md` file into your project's `.claude/commands/` directory
- The bot can now run specialized audits, reviews, and analysis on demand

---

## Prerequisites

- **Claude Code CLI** installed and authenticated
- **Claude Max or Team subscription** (the bot uses your account's API quota)
- **Linux with systemd** (native or WSL2)
- **Telegram bot** created via [@BotFather](https://t.me/BotFather)
- **tmux** installed (`sudo apt install tmux`)

---

## Repository Structure

```
docs/
  base-setup-guide.md         # Step-by-step: from zero to working Telegram bot
  extensions.md                # Full writeup of all production additions
  state-file-and-hooks.md      # Deep dive: persistent memory across restarts
  cron-jobs.md                 # Deep dive: scheduled one-shot tasks
  role-isolation.md            # Deep dive: multi-bot coordination
  wsl-autostart.md             # WSL-specific auto-start on Windows boot

examples/
  start-scripts/               # Bot start scripts with --add-dir for multi-directory access
    work-bot-start.sh

  watchdog/                    # Auto-restart bots that hit context limits
    claude-bot-watchdog.sh

  cron-scripts/                # Templates for scheduled tasks
    scheduled-task-template.sh

  hooks/                       # Claude Code hooks for state persistence
    settings.local.json

  state-files/                 # Structured state file templates
    bot-state.md               # General-purpose bot
    engineering-bot-state.md   # Engineering-focused bot

  management/                  # Bot lifecycle management
    claude-bot                 # start/stop/restart/status/logs for all bots

  agent-skills/                # 38 reusable Claude Code slash commands (by Mindspan Labs)
    README.md                  # Full catalog with descriptions
    vpe-workflow/              # Plan → Review → Ship workflow (4 skills)
      review-plan.md
      review-pr.md
      review-bugfix.md
      engineering-status.md
    auditors/                  # Specialized code review lenses (8 skills)
      security-reviewer.md
      api-auditor.md
      frontend-auditor.md
      prompt-auditor.md
      data-modeler.md
      performance-auditor.md
      a11y-auditor.md
      cost-guardian.md
    development/               # Building, fixing, and analyzing code (12 skills)
      architect.md
      bug-analyzer.md
      code-architect.md
      code-simplifier.md
      deep-fix.md
      deep-reviewer.md
      fix-issue.md
      full-audit.md
      new-component.md
      new-endpoint.md
      sprint-planner.md
      test-writer.md
    quality/                   # Testing, review, and diagnostics (6 skills)
      peer-review.md
      playbook-auditor.md
      root-cause-triage.md
      run-e2e.md
      test-session.md
      issue-intelligence.md
    ux-design/                 # UX, design systems, and content (5 skills)
      designer.md
      heuristic-eval.md
      ux-ia-auditor.md
      ux-writer.md
      error-ux-auditor.md
```

---

## How It All Fits Together

```
┌─────────────────────────────────────────────────────┐
│                    Your Phone                        │
│                   (Telegram)                         │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
    @work_bot                   @personal_bot
         │                           │
┌────────┴────────┐         ┌────────┴────────┐
│  tmux session   │         │  tmux session   │
│  (isolated)     │         │  (isolated)     │
│                 │         │                 │
│  Claude Code    │         │  Claude Code    │
│  --channels     │         │  --channels     │
│  --add-dir ...  │         │  --add-dir ...  │
│                 │         │                 │
│  CLAUDE.md      │         │  CLAUDE.md      │
│  bot-state.md   │         │  bot-state.md   │
│  .claude/       │         │  .claude/       │
│    hooks        │         │    hooks        │
│    skills       │         │    skills       │
└────────┬────────┘         └────────┬────────┘
         │                           │
         └─────────────┬─────────────┘
                       │
              ┌────────┴────────┐
              │   Watchdog      │
              │   (cron 5min)   │
              │   Auto-restart  │
              └────────┬────────┘
                       │
              ┌────────┴────────┐
              │   Cron Jobs     │
              │   (claude -p)   │
              │   Scheduled     │
              │   one-shots     │
              └─────────────────┘
```

---

## Key Concepts

### State File = Working Memory
The bot writes a structured markdown file after every interaction. On restart, it reads this file first. This is how it "remembers" across sessions. Hooks enforce the discipline — the bot gets a system-level nudge after every Telegram reply.

### Watchdog = Self-Healing
When Claude hits its context limit, the conversation "bakes" and the bot goes idle. The tmux session is still running, so `status` says RUNNING, but the bot is deaf. The watchdog inspects what's actually on the tmux screen every 5 minutes and restarts baked bots automatically.

### Cron One-Shots = Proactive Behavior
Scheduled tasks use `claude -p` (one-shot prompt mode), completely independent of the channel bot. They fire, run a prompt, send results to Telegram, and exit. The channel bot stays alive for interactive messages.

### Role Isolation = No Conflicts
Each bot's CLAUDE.md defines what it owns, what it must not do, and how to redirect questions to the other bot. Bots coordinate through files and databases, not shared memory.

---

## Our Production Setup

For reference, here's what we actually run:

| Bot | Role | Cron Jobs | Skills |
|-----|------|-----------|--------|
| **COS** (Chief of Staff) | Email, calendar, Notion, research, admin | Morning brief (7am), email check (every 15min), weekly research (Mon 6am), weekly use cases (Tue 6am), EOD summary (6pm), weekly review (Fri 4pm) | Google Workspace, Notion, LinkedIn API, WebSearch |
| **VPE** (VP Engineering) | Code review, PRs, architecture, CI, security | Daily status (8am), PR watcher (every 30min), weekly report (Fri 3pm) | 38 agent skills (auditors, reviewers, planners, UX, quality) |

Both bots:
- Run in isolated tmux sessions with separate sockets
- Have structured state files with hook-based persistence
- Are monitored by the watchdog (5-min cron)
- Auto-start via systemd on boot
- Have explicit role boundaries preventing overlap

---

## Credits

- Base setup guide by [Peter Steinberger](https://github.com/steipete)
- Extensions and agent skills by Jeremy @ [Mindspan Labs](https://mindspanlabs.ai) and Claude K.

## License

MIT — use however you like.
