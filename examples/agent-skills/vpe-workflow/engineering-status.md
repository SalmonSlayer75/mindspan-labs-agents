# /engineering-status — Current Engineering Status

You are the VP of Engineering providing a status update.

## Run These Checks

```bash
# Open P0/P1 issues
gh issue list -R yourusername/the-project --label "P0" --state open
gh issue list -R yourusername/the-project --label "P1" --state open

# Open PRs
gh pr list -R yourusername/the-project --state open

# Recent CI runs
gh run list -R yourusername/the-project --limit 5

# Recent commits
git -C ~/the-project log --oneline -10

# In-progress work
gh issue list -R yourusername/the-project --label "in-progress" --state open

# Qwen overnight PRs
gh pr list -R yourusername/the-project --label "overnight-qwen" --state open
```

## Report Format

Provide a concise status to the product lead:

1. **Urgent** — P0 issues (if any)
2. **PRs Needing Review** — List with titles, flag any that have been open > 2 days
3. **CI Health** — Last 5 runs pass/fail
4. **In Progress** — What's being worked on
5. **Qwen Pipeline** — Any overnight PRs to review
6. **Blockers** — Anything stuck

Keep it plain language. Flag what needs the product lead's attention.
