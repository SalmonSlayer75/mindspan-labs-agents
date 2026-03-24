# Agent Skills (Claude Code Slash Commands)

These are reusable Claude Code slash commands (placed in `.claude/commands/`) that give your Telegram bot specialized capabilities. They were developed for production use across multiple projects and are designed to be portable.

## How to Use

1. Copy any `.md` file into your project's `.claude/commands/` directory
2. The bot can invoke them with `/command-name` or you can reference them in CLAUDE.md instructions
3. Customize the project-specific references (repo names, file paths) for your codebase

## Categories

### VPE Workflow (`vpe-workflow/`)

Core engineering management workflow — plan, implement, review, ship.

| Skill | What it does |
|-------|-------------|
| `/review-plan` | Reviews an implementation plan before coding starts. Checks for gaps in root cause analysis, scope, security implications, test plan, and rollback strategy. |
| `/review-pr` | Full PR review with security audit, architecture check, test coverage analysis, and code quality scan. Posts findings with severity ratings (P0 blocker, P1 must-fix, P2 should-fix). |
| `/review-bugfix` | Bug fix review with higher scrutiny — verifies root cause is real, checks for regression potential, and assesses whether the fix prevents recurrence. |
| `/engineering-status` | Generates a current engineering status report: open issues, PR status, CI health, recent commits, velocity metrics. |

### Auditors (`auditors/`)

Specialized code review lenses — each focuses on one domain.

| Skill | What it does |
|-------|-------------|
| `/security-reviewer` | Auth, RLS, user scoping, PII handling, prompt injection, secrets in code |
| `/api-auditor` | Auth levels, Zod validation, response shapes, rate limiting, telemetry |
| `/frontend-auditor` | AbortController lifecycle, loading/error states, fetch patterns |
| `/prompt-auditor` | LLM guardrails, injection protection, model selection, cache-first patterns, spending caps |
| `/data-modeler` | Schema audit, RLS policies, FK integrity, migration safety, Zod alignment |
| `/performance-auditor` | N+1 queries, sequential awaits, React re-renders, cache gaps |
| `/a11y-auditor` | WCAG 2.1 AA, keyboard navigation, ARIA, contrast ratios, touch targets |
| `/cost-guardian` | LLM cost tracking, spending analysis, model routing optimization |

### Development (`development/`)

Higher-level engineering skills.

| Skill | What it does |
|-------|-------------|
| `/architect` | System design review, ADR compliance, pattern consistency |
| `/bug-analyzer` | Root cause analysis with data verification |
| `/deep-reviewer` | Two-pass plan + code review with veto power |
| `/full-audit` | Comprehensive codebase health check across all dimensions |
| `/sprint-planner` | Priority analysis, dependency mapping, sprint decomposition |
| `/test-writer` | Unit, integration, E2E test generation following project standards |

## Design Principles

All skills follow a common output contract:

**Plan → Implementation Files → Security Review → Tests → Telemetry → Open Questions**

This ensures consistent, thorough output regardless of which skill is invoked. Every skill:
- Cites specific file paths and line numbers
- Rates findings by severity (P0/P1/P2)
- Suggests concrete fixes, not just problems
- Considers security implications
- Flags open questions for human decision
