# /fix-issue Skill

This skill scans ALL open GitHub issues, triages them into a prioritized sprint plan, and then executes fixes one by one — with full testing and documentation at each step.

## Agent Chain

```
triage → bug-analyzer/architect (per issue) → plan → implement → test-writer → security-reviewer → doc-sync
```

## Usage

```
/fix-issue
```

No arguments needed. The skill fetches all open issues automatically.

## What It Does

### Phase 1: Triage — Scan & Classify All Open Issues

Fetch every open issue and build a picture of the work:

```
1. Run `gh issue list --state open --limit 100 --json number,title,labels,body,createdAt,assignees`
1a. FILTER OUT issues labeled `in-progress` or `post-beta` — another agent owns them.
    Log skipped issues: "Skipping #N (in-progress — owned by [worktree/agent])"
1b. When you START working on an issue, immediately add `in-progress` label:
    gh issue edit [NUMBER] --add-label "in-progress"
1c. When you FINISH an issue (close it), remove the label:
    gh issue edit [NUMBER] --remove-label "in-progress"
2. For each issue, classify:
   - Type: bug | feature | content | refactor | question
   - Priority: P0 | P1 | P2 | unset (from labels)
   - Effort: S (< 1 file) | M (2-5 files) | L (6+ files)
   - Category: which part of the app (onboarding, schools, plan, coach, admin, infra)
3. Detect clusters — issues that touch the same files or feature area
4. Detect dependencies — issues that should be fixed in a specific order
5. Flag stale issues (> 30 days old) or duplicates
```

### Phase 2: Sprint Plan — Prioritize & Organize

Present a comprehensive plan to the user:

```
## Sprint Plan: [DATE]

### Summary
- X open issues total
- Y bugs, Z features, W content fixes
- Estimated effort: [S/M/L]

### Execution Order

Issues are grouped into sprints ordered by:
1. P0 bugs first (blocking / data integrity)
2. P1 bugs and features (next sprint)
3. Clustered work (issues touching same files, done together for efficiency)
4. P2 backlog items

### Sprint 1: Critical (P0)
| # | Issue | Type | Effort | Files Affected |
|---|-------|------|--------|----------------|
| 3 | [title] | bug | S | proxy.ts |

### Sprint 2: High Priority (P1)
| # | Issue | Type | Effort | Files Affected |
|---|-------|------|--------|----------------|
| 7 | [title] | feature | M | schools/, plan/ |
| 12 | [title] | bug | S | coach/route.ts |

### Sprint 3: Clustered Work
| # | Issue | Type | Effort | Cluster |
|---|-------|------|--------|---------|
| 5 | [title] | content | S | onboarding copy |
| 8 | [title] | content | S | onboarding copy |

### Sprint 4: Backlog (P2)
| # | Issue | Type | Effort | Files Affected |
|---|-------|------|--------|----------------|
| 15 | [title] | feature | M | settings/ |

### Deferred / Needs Clarification
| # | Issue | Reason |
|---|-------|--------|
| 20 | [title] | Unclear requirements — needs user input |

### Risks & Dependencies
- Issue #7 requires a migration — must deploy before #12
- Issue #5 and #8 touch the same component — do together to avoid conflicts
```

**Present this plan to the user for approval before executing.**

Use `EnterPlanMode` to present the plan. The user may:
- Approve the full plan
- Reorder priorities
- Defer specific issues
- Add context or clarification

### Phase 3: Execute — Fix Each Issue

Once the plan is approved, work through each issue in order. For each issue:

> **Template gate (REQUIRED before writing code):** Read the issue body. If sections 2–6
> of the standard template (`.github/ISSUE_TEMPLATE/bug_report.md`) still say "TBD",
> complete them in the issue body via `gh issue edit <number> --body "..."` before
> implementing. This documents the fix contract and prevents scope creep.

#### 3a. Analysis

**For bugs** — apply `/bug-analyzer` thinking:
```
1. Identify affected files from issue description (page URL, stack trace, context)
2. Trace the code path to find root cause
3. CHECK ACTUAL USER DATA — if the issue references a specific user, query the
   database to verify what data actually exists. Do NOT assume "data is missing"
   or "user has no records." The data may exist but the code may read it wrong
   (wrong API envelope nesting, empty content in an existing row, stale
   in-progress placeholder, column name mismatch). Code-only analysis produces
   plausible but often wrong root causes.
4. Assess impact: users affected, data integrity, security
```

**For features** — apply `/architect` thinking:
```
1. Map the request to existing architecture
2. Identify what changes vs. what's new
3. Check for existing patterns to follow
4. Estimate scope (files, migrations, tests)
```

**For content** — simpler:
```
1. Find the affected text in the codebase
2. Draft the correction
```

#### 3b. Implement

```
1. Write migration (if needed) — naming: YYYYMMDDHHMMSS_descriptive_name.sql
2. Update types — TypeScript interfaces, Zod schemas
3. Write the fix — follow PATTERNS.md, use existing patterns
4. Run `npx tsc --noEmit` — zero errors required
```

**Code standards:**
- Follow existing patterns in the codebase
- No over-engineering — fix what the issue asks for
- No unrelated cleanup — stay focused
- Add comments only where logic is non-obvious

#### 3c. Test

```
1. Write regression test(s) that would have caught the bug
2. Run full test suite: `npx vitest run`
3. All existing + new tests must pass
```

#### 3d. Security Review

Quick check on all changes:
```
1. No student data exposed or logged
2. Queries scoped to authenticated user (or admin-gated)
3. Input validated (Zod schemas)
4. No new secrets or credentials in code
5. RLS policies still correct (if DB changes)
```

#### 3e. Document

**Always:**
- Comment on the GitHub issue: `gh issue comment <number> --body "Fixed in commit <sha>"`
- Close the issue: `gh issue close <number>`

**If schema changed:**
- `docs/DATA_FIELD_REFERENCE.md` — Add new tables/columns
- Migration file header comments

**If API changed:**
- `docs/api/` — Relevant API doc file
- Code header comments

**If feature/behavior changed:**
- `AI-COORDINATION.md` — Progress tracking
- `CLAUDE.md` — If patterns or ADRs affected

**Notion (if significant):**
- Tasks page (`2ec65d2ef8aa81258d9cf27472e0cd0f`)
- Strategy & Decisions (`2ec65d2ef8aa8168bbe6feaa07533a73`) — if architectural decision

**Memory:**
- `memory/MEMORY.md` — If lesson learned or new pattern discovered

#### 3f. Commit

```
1. Stage specific files (not `git add .`)
2. Commit referencing the issue:
   fix: Description (#ISSUE_NUMBER)
   feat: Description (#ISSUE_NUMBER)
3. Push to main after each sprint (not after each issue)
```

**Commit strategy:**
- Small, focused fixes: commit individually
- Clustered work (same files): commit together as one sprint
- Always push after completing a sprint group

### Phase 4: Sprint Report

After all sprints are done, produce a summary:

```
## Sprint Report: [DATE]

### Issues Resolved
| # | Title | Type | Priority | Commit |
|---|-------|------|----------|--------|
| 3 | [title] | bug | P0 | abc1234 |
| 7 | [title] | feature | P1 | def5678 |

### Issues Deferred
| # | Title | Reason |
|---|-------|--------|
| 20 | [title] | Needs clarification from user |

### Code Impact
- Files modified: X
- Lines added: Y
- Lines removed: Z
- New tests: W
- Migrations: N

### Test Status
- Total tests: X passing, 0 failing
- TypeScript: 0 errors

### Documentation Updated
| Document | Changes |
|----------|---------|
| GitHub Issues | X commented + closed |
| DATA_FIELD_REFERENCE.md | [if updated] |
| AI-COORDINATION.md | [if updated] |
| Notion | [if updated] |

### Lessons Learned
- [Any patterns or gotchas discovered]

### Remaining Open Issues
- X issues still open (list them)
```

## Integration with Feedback Pipeline

Issues created from `/admin/feedback` have the `from-feedback` label and include:
- User's description
- Page URL where feedback was submitted
- Browser/viewport info
- Admin notes and priority

When fixing feedback-originated issues:
1. Fix resolves the user's reported problem
2. Update `user_feedback` row status to `resolved` when issue is closed

## Priority Interpretation

| Priority | Meaning | Action |
|----------|---------|--------|
| **P0** | Blocking, data loss, security | Fix immediately, deploy ASAP |
| **P1** | Broken feature, bad UX | Fix in current sprint |
| **P2** | Nice to have, polish | Batch with related work |
| **Unset** | Not yet triaged | Classify during triage, ask user if unclear |

## Effort Sizing

| Size | Files | Migrations | Tests | Example |
|------|-------|------------|-------|---------|
| **S** | 1-2 | No | 0-2 | Fix typo, adjust copy, one-line bug |
| **M** | 3-5 | Maybe | 2-5 | New feature, multi-file bug fix |
| **L** | 6+ | Likely | 5+ | New module, schema change, cross-cutting |

## When to Escalate

Stop and ask the user if:
- An issue requires a breaking schema change
- An issue contradicts an existing ADR or pattern
- An issue is unclear or has conflicting requirements
- Total sprint scope exceeds 15+ files
- P0 issue needs immediate hotfix (confirm deploy strategy)
- Two issues conflict with each other

## Checklist (Auto-Verified Per Issue)

- [ ] Issue fetched and understood
- [ ] Root cause identified (bugs) or scope defined (features)
- [ ] Implementation follows PATTERNS.md
- [ ] TypeScript compiles clean (0 errors)
- [ ] All tests pass (existing + new)
- [ ] Security review passed
- [ ] GitHub issue commented and closed
- [ ] Relevant documentation updated
- [ ] Commit pushed with issue reference

## Checklist (Sprint-Level)

- [ ] All open issues reviewed and classified
- [ ] Sprint plan presented and approved by user
- [ ] Issues executed in priority order
- [ ] Full test suite passes after all changes
- [ ] Build passes (`npx next build`)
- [ ] Sprint report generated
- [ ] All commits pushed
- [ ] Memory updated with lessons learned

---

**Note:** This skill is the primary way bugs and features flow from user feedback through to deployed fixes. Run it regularly (weekly or after a batch of feedback) to keep the issue backlog at zero.
