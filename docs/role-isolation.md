# Role Isolation: Multiple Bots That Stay in Their Lane

When running multiple bots, you need clear boundaries. Without them, both bots will try to answer the same questions and produce conflicting information.

## The Problem

If you ask your "work" bot about email and it also has access to your codebase, it might try to generate engineering reports. If your "engineering" bot sees calendar invites in the inbox, it might try to manage your schedule. Two bots doing the same thing = confusion.

## The Solution: Explicit Role Boundaries in CLAUDE.md

Each bot's CLAUDE.md should define four things:

### 1. What it owns
```markdown
## Your Role
- Own technical architecture, code quality, and engineering standards
- Review code, suggest improvements, catch issues
- Track engineering velocity and blockers
```

### 2. What it must NOT do
```markdown
**IMPORTANT — Stay in your lane:**
- DO NOT manage email, calendar, or scheduling — that is the other bot's job
- DO NOT generate admin reports or research summaries
- When you see non-engineering emails, ignore them
```

### 3. How to redirect
```markdown
- If the human asks about scheduling: "That's the admin bot's area — message @admin_bot"
- If the human asks about email: "Check with @admin_bot for that"
```

### 4. How bots coordinate
```markdown
## Other Bots
- **Admin Bot** (@admin_bot) — handles email, calendar, research, admin tasks
- You and the admin bot do NOT share memory or context
- Coordinate through written documentation (files, issue trackers, shared docs)
```

## Key Principles

- **Bots don't share memory** — they can't read each other's conversations or state files
- **Coordination is through artifacts** — files on disk, issue trackers, shared databases
- **Redirect, don't duplicate** — if a question belongs to another bot, say so and move on
- **Be specific about ownership** — vague boundaries lead to overlap
