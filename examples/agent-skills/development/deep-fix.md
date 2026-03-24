# /deep-fix Skill

This skill performs systematic, root-cause-driven resolution of open GitHub issues. Instead of fixing issues one by one, it identifies shared root causes across the entire backlog, red-teams its own assumptions, plans holistic fixes that resolve multiple issues at once, and documents patterns to prevent recurrence.

## How It Differs from /fix-issue

| | `/fix-issue` | `/deep-fix` |
|---|---|---|
| Unit of work | Single issue | Root cause pattern |
| Grouping | By priority | By shared root cause |
| Analysis | Per-issue RCA | Cross-issue pattern detection |
| Validation | Test each fix | Red-team assumptions first |
| Documentation | Close issue + comment | Pattern library + regression guards |
| Goal | Clear the backlog | Eliminate entire classes of bugs |

**When to use `/fix-issue`:** Small batch of unrelated issues, quick triage + fix.
**When to use `/deep-fix`:** Large backlogs with suspected common causes, post-audit cleanup, systemic quality improvement.

## Agent Chain

```
scan → classify → root-cause-map → red-team → holistic-plan
  → [plan branch → local Codex plan review → approval]
  → [fix branch → execute → verify]
  → [CODE REVIEW PR → local Codex code review → approval → merge to main]
  → document
```

## Usage

```
/deep-fix
```

No arguments needed. The skill fetches all open issues automatically.

## Examples

```
/deep-fix                          # Analyze and fix all open issues systematically
```

---

## Phase 1: Scan & Classify

Fetch and parse every open GitHub issue.

```
1. Run: gh issue list --state open --limit 200 --json number,title,labels,body,createdAt,assignees
1a. FILTER OUT issues labeled `in-progress` or `post-beta` — another agent owns them.
    Log skipped issues: "Skipping #N (in-progress — owned by [worktree/agent])"
1b. When you START working on a root cause group, add `in-progress` to ALL issues in it:
    for NUM in [issue numbers]; do gh issue edit $NUM --add-label "in-progress"; sleep 0.5; done
1c. When you FINISH an issue (close it), remove the label:
    gh issue edit [NUMBER] --remove-label "in-progress"
2. For each issue, extract:
   - Priority: P0 | P1 | P2 | P3 | unset (from labels)
   - Type: bug | enhancement | security | refactor | ux | performance (from labels)
   - Affected files: parse from issue body (look for file paths, function names, line numbers)
   - Affected columns/tables: parse from issue body (look for DB column names, table names)
   - Error pattern: what's going wrong (wrong column, missing auth, broken FK, crash, etc.)
   - System area: onboarding | coach | plan | schools | family | admin | auth | infra
   - 🗄️ DB flag: mark any issue whose root cause may be schema drift, RLS, FK integrity,
     Zod alignment, or wrong column names — these will use /data-modeler validate in Phase 3
   - 📋 Template flag: mark any issue whose body is missing sections 2–8 of the standard
     template — these MUST be fleshed out (in the issue body) before implementation begins
3. Present issue count and breakdown to the user
```

> **Template completeness gate:** Before writing any code for an issue, verify its body contains
> completed sections 1–6 of the standard template (`.github/ISSUE_TEMPLATE/bug_report.md`).
> If an issue only has the audit-time minimum (section 1 + header), update the issue body
> with the full template before starting the fix. Sections 7 (Rollout) and 8 (Ownership) can
> remain TBD until the fix plan is written, but sections 2–6 MUST be complete.

### Output: Issue Registry

```
## Issue Registry: [DATE]

Total: X open issues
- P0: N | P1: N | P2: N | P3: N | Unset: N
- Bugs: N | Security: N | Enhancements: N | Refactors: N

### All Issues
| # | Title | Priority | Type | Area | Files Referenced |
|---|-------|----------|------|------|------------------|
| 286 | React hooks violation | P0 | bug | coach | FloatingCoachButton.tsx |
```

---

## Phase 2: Root Cause Mapping

This is the core differentiator. Don't treat issues as independent — find the shared root causes.

### Step 2a: Identify Root Causes

For each issue, ask: **"What underlying mistake or gap caused this?"**

Common root cause categories:
- **Schema drift** — Code references columns/tables that don't exist or have changed
- **FK migration gap** — Dual FK standardization missed this table/query
- **Missing auth/RLS** — Endpoint or policy lacks ownership verification
- **Contract mismatch** — Frontend expects different shape than API returns
- **Stale types** — TypeScript types don't match actual DB schema
- **Missing validation** — Zod schema allows values the DB rejects (or vice versa)
- **Hardcoded values** — Magic numbers, year constants, phase counts
- **Dead code** — Code path that can never execute correctly
- **Race condition** — Concurrent operations produce wrong state
- **Missing feature** — Required capability simply doesn't exist

**For 🗄️ DB-flagged issues**, run `/data-modeler validate [file]` on each affected file to get a structured column-by-column, RLS, and Zod alignment report before building the root cause map. This prevents grouping issues under the wrong root cause.

### Step 2b: Cross-Reference

Build a root cause map:

```
ROOT CAUSE: "Wrong column names in database queries"
├── #333 — coach-context.ts: activity_category → category
├── #314 — coach/questions: wrong column in GET/PUT/DELETE
├── #288 — timeline bulk: wrong column on student_profiles
└── #338 — playbook-data: queries user_profiles.email (doesn't exist)

ROOT CAUSE: "Missing ownership checks on API endpoints"
├── #316 — parent-actions PATCH: no ownership verification
├── #315 — coach/feedback: any user can rate any message
└── #317 — IDOR via coach tools: LLM-controlled user_id
```

### Step 2c: Score Each Root Cause

| Root Cause | Issues | Highest Priority | Risk if Unfixed | Fix Complexity |
|------------|--------|-----------------|-----------------|----------------|
| Wrong column names | 5 | P0 | High — features silently broken | Medium |
| Missing auth checks | 3 | P0 | Critical — security holes | Low |

---

## Phase 3: Red Team Assumptions

**CRITICAL PHASE — Do not skip.**

For each root cause and its proposed fix, actively try to prove yourself WRONG:

### 3a: Verify Issues Still Exist

```
For each issue in the root cause group:
1. Read the ACTUAL current code (not cached/stale knowledge)
2. Verify the bug described in the issue is still present
3. Check git log for recent commits that may have already fixed it
4. If fixed, mark the issue as "already resolved" and close it

DO NOT trust issue descriptions blindly. The code may have changed since the issue was filed.
```

### 3b: Verify Against Actual User Data (MANDATORY)

```
Before finalizing any root cause hypothesis, check the ACTUAL database state
for the affected user:

1. Identify the user from the issue context (email, user ID, feedback metadata)
2. Query the relevant tables to see what data actually exists
3. Compare what the code ASSUMES vs. what the DB CONTAINS
4. Check for edge cases: empty content with non-null rows, in-progress
   generation placeholders, API response envelope mismatches, etc.

DO NOT assume "data is missing" — the data may exist but the code may be
reading it incorrectly (wrong nesting level, wrong column name, stale cache).
DO NOT assume "no data causes the crash" — a row may exist with empty content
(e.g., generation_model: "in-progress") that the UI treats as valid.
```

**Why this matters:** Code-only analysis can produce plausible-sounding root causes
that are completely wrong. Example: a crash on `.length` of undefined LOOKS like
"user has no data" but may actually be "user has 282 playbook rows and the one
the UI loaded has empty content because generation never completed." The fix is
the same (add `?.`) but the root cause understanding changes whether you find
deeper issues (like stale in-progress rows that should be cleaned up).

### 3c: Challenge Root Cause Hypotheses

```
For each root cause hypothesis:
1. Could this be INTENTIONAL behavior? Check comments, ADRs, PATTERNS.md
2. Is the column really wrong, or is there an alias/view?
3. Does the "missing" feature actually exist somewhere else?
4. Would fixing this BREAK something that currently works?
5. Are there OTHER issues not in the backlog that share this root cause?
   (Search the codebase for the same pattern beyond what was filed)
```

**For 🗄️ DB-flagged root causes**, use `/data-modeler validate [file]` to confirm:
- The exact column names the code uses vs. what the DB actually has
- Whether RLS policies cover all four operations (SELECT/INSERT/UPDATE/DELETE)
- Whether Zod schemas match NOT NULL constraints and CHECK enums
- Any additional query sites in other files with the same wrong patterns

### 3d: Check for Fix Conflicts

```
For each fix group:
1. Do any two fixes touch the same file in conflicting ways?
2. Does fix A's change invalidate fix B's approach?
3. Does the fix order matter? (e.g., schema migration must come before code change)
4. Could a holistic fix introduce a NEW bug class?
```

### 3e: Confidence Assessment

Rate each root cause:

| Root Cause | Confidence | Issues Verified | Conflicts Found |
|------------|-----------|-----------------|-----------------|
| Wrong column names | HIGH — read actual schema | 5/5 verified | None |
| Missing auth | HIGH — no ownership check in code | 3/3 verified | None |
| Contract mismatch | MEDIUM — need to trace full data flow | 2/3 verified | Fix may change API shape |

**Present findings to the user. Get approval before proceeding to fixes.**

Use `EnterPlanMode` for this checkpoint. The user may:
- Approve all fix groups
- Defer specific groups
- Reorder priorities
- Challenge your red team findings
- Add context about intentional behavior

---

## Phase 4: Holistic Fix Planning

For each validated root cause group, plan a SINGLE fix that resolves ALL related issues.

### Fix Group Template

```
## Fix Group [N]: [Root Cause Name]
Resolves: #X, #Y, #Z (N issues)
Priority: P0 | P1 | P2
Confidence: HIGH | MEDIUM | LOW

### Root Cause
[One sentence explaining the underlying mistake]

### Why These Issues Are Related
[Explain the shared pattern — why fixing the root cause fixes all of them]

### Holistic Fix
1. [Step 1: e.g., "Update column names in coach-context.ts lines 192-336"]
2. [Step 2: e.g., "Update downstream references in lines 294-296, 311-313, 322-326"]
3. [Step 3: e.g., "Search codebase for same wrong column names in other files"]

### Files to Modify
| File | Change | Lines |
|------|--------|-------|
| `src/lib/llm/coach-context.ts` | Fix 4 column name groups | 192, 198, 245, 331-336 |

### Potential Regressions
- [What could break? e.g., "If column names are wrong in types too, TS will error"]
- [What to watch for? e.g., "Coach responses should now include activity data"]

### Verification Steps
1. [How to verify the fix works: e.g., "Query returns non-null activity data"]
2. [How to verify no regression: e.g., "All existing tests still pass"]
```

### Fix Group Ordering

Order fix groups by:
1. **Dependencies first** — Schema/migration changes before code that uses them
2. **Risk level** — Higher risk of regression = fix earlier (so later fixes don't compound)
3. **Impact** — Most issues resolved per fix group = higher priority
4. **Priority cascade** — Within same tier, resolve P0s before P1s

---

## Phase 4.4: Sprint Decomposition (After Planning, Before Execution)

Planning is comprehensive — all root cause groups across all issues get planned in full.
Sprint decomposition happens **after** the complete plan is written, not during it.
The goal is a full picture first, then a practical execution sequence.

### Why Decompose After Planning (Not Before)

Planning is cheap — it's mostly reading and writing. Execution is expensive — every file
is read again, edited, compiled, tested. A 40-file plan is fine to write in one pass.
A 40-file *execution* will hit context limits mid-edit and produce partial fixes that are
harder to debug than no fix at all.

### Execution Sprint Sizing Limits

| Limit | Cap | Why |
|-------|-----|-----|
| Fix groups per execution sprint | **≤ 6** | More than 6 makes PRs unreviable |
| Issues per execution sprint | **≤ 30** | Beyond 30, individual fixes blur together |
| Files modified per execution sprint | **≤ 25** | Each file is read + edited = 2 tool calls; 25 files ≈ 50 tool calls, leaving room for tests and compiles |

### Decomposition Procedure

After Phase 4 (all fix groups are fully planned):

```
1. List every fix group with its estimated file count.
2. Sort groups by: P0 first, then P1, then (issue_count / file_count) descending.
3. Pack groups into execution sprints greedily:
   - Add groups one by one until adding the next would exceed any cap.
   - That's Sprint 1. Start a new sprint. Repeat.
4. Present the full sprint roadmap to the user:
   - Sprint 1: N groups, X issues, Y files → implement in this session
   - Sprint 2: N groups, X issues, Y files → next session
   - Sprint N: ...
5. Get explicit approval on the roadmap before proceeding to Phase 4.5.
```

### Sprint Roadmap Output Format

```
## Sprint Roadmap

Full plan covers: N fix groups, X issues, ~Y files total.
Decomposed into Z execution sprints (each fits one context window).

| Sprint | Groups | Issues | ~Files | Session |
|--------|--------|--------|--------|---------|
| 1 | Groups 1–3 (auth gaps, column drift, envelope) | #316 #315 #333 ... | 18 | this session |
| 2 | Groups 4–6 (falsy numeric, playbook quality) | #909 #880 ... | 22 | next session |
| 3 | Groups 7–8 (a11y, performance) | #873 #850 ... | 15 | next session |

Proceed with Sprint 1? (Sprints 2–3 will be picked up in future /deep-fix runs.
The full plan is saved in docs/plans/<sprint>/ for continuity.)
```

**Do not start execution until the user approves the Sprint 1 scope.**

### Continuing From a Previous Sprint

When starting a new session to execute Sprint 2+:
1. Read the existing plan in `docs/plans/<sprint>/plan_vN.md`
2. Identify which fix groups were already completed (check git log)
3. Identify the next un-executed sprint from the roadmap
4. Proceed directly to Phase 5 (skip Phases 1–4 — the plan is already approved)

### Mid-Execution Context Warning

During Phase 5 execution, if you notice:
- A fix group is touching more files than estimated (>10 unexpected files), OR
- You have already edited more than 20 files in this session

→ **Stop after completing the current fix group.** Commit what's done, push, open the PR,
and tell the user: "Context budget reached after N fix groups. Remaining groups are Sprint N+1."
Do NOT start a new fix group in an overloaded context — partial fixes are worse than deferred ones.

---

## Pre-Plan Quality Bar (Before Opening the PR)

**Before creating the [PLAN] PR**, the plan must be complete enough that Codex can do a final quality check — not discover basic gaps. The goal is ≤3 Codex iterations, not 8.

### Mandatory pre-plan checklist

**Scope completeness**
- [ ] Run `grep -r "PATTERN" src/` to find ALL instances of the root cause across the codebase, not just the reported file
- [ ] For any "add X to all Y" fixes: grep for ALL Y, verify count, list every file explicitly in the plan
- [ ] Check edge cases: are there routes/components that use the pattern indirectly (imports, sub-functions)?

**Test plan specificity**
- [ ] Every changed API route has a named integration test file and specific assertion
- [ ] Regression test is described at root-cause level (would have caught the original bug)
- [ ] For systemic fixes: CI guard is described with actual code logic, not just "a test that checks X"
- [ ] CI guard code is verified by dry-running the logic mentally (path resolution, glob patterns, regex)

**Code validity**
- [ ] Any code in the plan (especially test snippets) is checked for correctness — paths, variable names, logic
- [ ] Path resolution in test code uses correct `__dirname` base and resolves to real file locations

**Plan branch hygiene**
- [ ] Plan branch contains ONLY changes to `docs/plans/**`
- [ ] Any incidental improvements (AGENTS.md, CLAUDE.md) go in a separate commit on main FIRST, before opening the plan PR

---

## Phase 4.5: Codex Plan Review (ALWAYS REQUIRED)

**Every deep-fix run requires a Codex plan review before any code is written.**
There are no exceptions. The gate is not conditional on file count, priority, or recurrence.

### Why always

Plan review is cheap. Shipping the wrong fix is expensive. Codex catches missing call sites,
over-permissive logic, and incomplete test specs before a single line of code is written.
The goal is ≤3 Codex iterations, not discovering gaps mid-implementation.

### How to identify a recurring bug (for your own awareness)

Before writing the plan, scan `memory/lessons.md` and the issue history:
1. Does the root cause match any documented lesson?
2. Has this root cause appeared in more than one previous sprint?
3. Does the issue title or body mention "again", "recurring", or reference a prior issue number?

Flag recurring bugs in the plan — they warrant extra scrutiny in your test specs.

### Steps

1. Check out a `plan/<slug>` branch (e.g., `plan/r73-coach-context-columns`):
   ```
   git checkout -b plan/<slug>
   ```
2. Write the plan to `docs/plans/<sprint>/plan_v1.md` using `docs/plans/PLAN_TEMPLATE.md`
3. Commit locally — do NOT push to GitHub and do NOT open a GitHub PR:
   ```
   git add docs/plans/<sprint>/plan_v1.md
   git commit -m "docs: plan v1 — <description>"
   ```
4. **Stop. Tell the product lead the plan branch is ready for local Codex review.**
   the product lead will ask local Codex to review the plan and paste findings back.
5. Address all P0/P1 findings, write `plan_v2.md`, commit on the same branch.
6. Repeat up to round 3/3. Stop addressing findings after round 3 unless the product lead asks for more.
7. Once the product lead approves the product direction:
   - **Stay on the plan branch** — do NOT merge to main yet
   - Proceed to Phase 5

> **Plan branch hygiene:** The plan branch contains ONLY changes to `docs/plans/**`.
> Any incidental improvements (CLAUDE.md, PATTERNS.md) go in a separate commit on main FIRST.

---

## Phase 5: Execute

### 5-pre: Create the implementation branch

Before writing any code, create a `fix/<slug>` branch from **main** (not from the plan branch):

```bash
git checkout main
git pull origin main          # ensure main is up to date
git checkout -b fix/<slug>    # e.g., fix/r73-coach-context-columns
```

All implementation work happens on this branch. The plan branch remains untouched.
Do NOT push `fix/<slug>` to GitHub until all fixes are complete and verified (see Phase 5g).

### For Each Fix Group:

#### 5a: Apply the Fix

```
1. If migration needed:
   - Use /data-modeler migrate [change] to design and write the migration correctly
     (handles FK ordering, RLS policies, indexes, and migration header format)
   - Apply to staging first: scripts/apply-migrations.sh --target staging
   - Verify on staging, then apply to production: scripts/apply-migrations.sh --target production
2. Update application code:
   - Follow PATTERNS.md
   - Use existing patterns from the codebase
   - No over-engineering — fix the root cause, nothing more
   - For DB query fixes: run /data-modeler validate [file] after editing to confirm all
     column names, RLS patterns, and Zod alignments are now correct
3. Update types/schemas if affected:
   - Zod schemas
   - TypeScript interfaces
   - Database types (if relevant)
```

#### 5b: Compile Check

```
npx tsc --noEmit
# MUST be 0 errors before proceeding
```

#### 5c: Run Tests

```
npx vitest run
# ALL existing + new tests must pass
```

#### 5d: Write Regression Tests

For each fix group, write at least ONE test that would have caught the bug:

```typescript
// ✅ GOOD regression test: Verifies the root cause is fixed
describe('coach-context activity loading', () => {
  it('should use correct column names for activities query', () => {
    // Verify 'category' not 'activity_category'
    // Verify 'is_leadership' not 'leadership_role'
    // Verify 'years_involved' not 'years_participated'
  });
});

// ❌ BAD regression test: Only tests one symptom
describe('coach-context', () => {
  it('should load activities', () => {
    // Too vague — doesn't verify the specific root cause
  });
});
```

#### 5e: Update Issue Body + Close Issues

```
For each issue resolved by this fix group:

1. If the issue body is still in audit-time minimal format (sections 2–8 say "TBD"),
   update the issue body with the completed template BEFORE closing:

   gh issue edit <number> --body "$(cat <<'EOF'
   **Severity:** P1
   **Found by:** /full-audit round N, Phase X
   **File(s):** `path/to/file.ts:line_number`

   ## 1. Root Cause
   **What failed at the system level?**
   [completed]
   **Why did existing guardrails/tests not catch it?**
   [completed]

   ## 2. Proposed Fix
   [completed — what was actually changed]

   ## 3. Scope / Non-Goals
   **In scope:** [what was fixed]
   **Non-goals:** [what was not touched]

   ## 4. Affected Files / Interfaces / Data
   **API routes:** [list]
   **Libraries/components:** [list]
   **DB tables/RLS/migrations:** [list]

   ## 5. Security / Privacy Checks
   [completed or N/A]

   ## 6. Test Plan
   **Unit:** [test file + assertion]
   **API:** [test file + assertion]
   **Integration/E2E regression:** [test file + assertion]

   ## 7. Rollout + Rollback
   [completed or N/A for code-only changes]

   ## 8. Ownership + Execution
   **Owner:** Claude Code
   **Definition of done:**
   - [x] Code merged
   - [x] Tests merged and passing
   - [x] Staging verified
   - [x] Production verification complete
   EOF
   )"

2. Comment on the issue explaining the holistic fix:
   gh issue comment <number> --body "Fixed as part of root cause group: [name].
   Root cause: [explanation]. Fixed in commit <sha>.
   Also resolves: #X, #Y, #Z."

3. Close the issue:
   gh issue close <number>
```

#### 5f: Commit to the fix branch

```bash
# Commit the entire fix group as one logical unit on fix/<slug>
git add [specific files]
git commit -m "fix: [root cause description] (#ISSUE1, #ISSUE2, #ISSUE3)

Root cause: [one sentence]
Fixes: #ISSUE1, #ISSUE2, #ISSUE3

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

**Commit strategy:**
- One commit per fix group (not per issue)
- All related issues referenced in the commit message
- **Do NOT push to GitHub yet.** Push happens only after all fix groups are done and
  Phase 6 verification passes — as part of the code review gate in Phase 5g.

---

#### 5g: Codex Code Review Gate (ALWAYS REQUIRED)

After all fix groups are committed and Phase 6 verification passes:

1. Push the `fix/<slug>` branch to GitHub:
   ```bash
   git push -u origin fix/<slug>
   ```
2. Open a GitHub PR targeting `main`:
   ```bash
   gh pr create \
     --title "[CODE REVIEW] <description>" \
     --body "$(cat <<'EOF'
   ## Summary
   - Issues fixed: #X, #Y, #Z
   - Root cause group(s): [names from plan]
   - Plan approved in: plan/<slug> branch (local Codex review)

   ## Test results
   - Tests: X passing, 0 failing
   - TypeScript: 0 errors

   ## Files changed
   [list key files]
   EOF
   )"
   ```
3. **Stop. Tell the product lead the PR is ready for local Codex code review.**
   the product lead will ask local Codex to review the PR diff and paste findings back.
4. Address all P0/P1 findings. Commit fixes on the same `fix/<slug>` branch and push.
5. After CI passes and Claude Code review finds no P0/P1, Joe (CTO, @yourusername) merges:
   ```bash
   # Joe (@yourusername) merges via GitHub UI
   ```
6. Close all resolved GitHub issues with comments (see 5e above).

> **Joe (CTO, @yourusername) performs final review and merges to main.**
> This is the final gate before production.

---

## Phase 6: Verify (Anti-Regression)

After ALL fix groups are applied, run a comprehensive verification pass.

```
### 6a: Full Test Suite
npx vitest run
# Report: X passing, 0 failing

### 6b: TypeScript Clean
npx tsc --noEmit
# Report: 0 errors

### 6c: Spot-Check Previously Fixed Issues
For each fix group, manually verify one representative issue:
- Does the fixed code path actually work now?
- Did the fix introduce any new TypeScript errors in related files?
- Are there any console warnings or new linting issues?

### 6d: Cross-Fix Regression Check
Look specifically for:
- Fix A changed a function signature — did Fix B's code still work?
- Fix A renamed a column — did Fix C's query update too?
- Fix A added a migration — did it affect Fix D's table?
```

If any regression is found, fix it immediately before proceeding to documentation.

---

## Phase 7: Document Patterns

This phase prevents the same bugs from recurring. It is NOT optional.

### 7a: Pattern Library

For each root cause pattern discovered, create an entry:

```
## Pattern: [Name]
**Category:** Schema Drift | Auth Gap | Contract Mismatch | ...
**Times Found:** N issues
**Severity When Hit:** P0 | P1 | P2

### What It Looks Like
[Description of the bug pattern — how to recognize it]

### Why It Happens
[Root cause — what developer behavior leads to this]

### How to Prevent It
[Concrete steps — what to do differently]

### Detection
[How to scan for this pattern — grep commands, lint rules, test patterns]

### Code Examples
```typescript
// ❌ BAD: The pattern that causes this bug
.select('activity_category, leadership_role')  // Wrong column names

// ✅ GOOD: The correct approach
.select('category, is_leadership')  // Actual DB column names
```
```

### 7b: Update Memory

```
1. Update memory/MEMORY.md with new lessons learned
2. Create or update memory/common-bugs.md with the pattern library
3. If a new PATTERNS.md rule is warranted, add it
```

### 7c: Sprint Summary Report

```
## Deep Fix Report: [DATE]

### Execution Summary
| Metric | Value |
|--------|-------|
| Issues analyzed | X |
| Root causes identified | Y |
| Fix groups executed | Z |
| Issues resolved | W |
| Issues deferred | V |
| Regression tests added | R |
| Patterns documented | P |

### Root Cause Groups
| Group | Root Cause | Issues Resolved | Confidence |
|-------|-----------|-----------------|------------|
| 1 | Wrong column names | #333, #314, #288 | HIGH |
| 2 | Missing auth checks | #316, #315, #317 | HIGH |

### Resolved Issues
| # | Title | Fix Group | Commit |
|---|-------|-----------|--------|
| 333 | coach-context wrong columns | 1 | abc1234 |

### Deferred Issues
| # | Title | Reason |
|---|-------|--------|
| 20 | [title] | Needs product clarification |

### Patterns Documented
| Pattern | Category | Issues Prevented |
|---------|----------|------------------|
| Schema drift | Column names | Future wrong-column bugs |

### Test Status
- Total tests: X passing, 0 failing
- TypeScript: 0 errors
- New regression tests: Y

### Files Modified
- Files changed: X
- Lines added: Y
- Lines removed: Z
- Migrations: N

### Remaining Open Issues
- X issues still open
- Next recommended action: [run /deep-fix again | run /fix-issue for remaining | defer to post-beta]

### Lessons Learned
- [Discoveries made during this run]
- [New patterns to watch for]
- [Process improvements for next time]
```

---

## Priority Interpretation

| Priority | Meaning | Deep Fix Action |
|----------|---------|-----------------|
| **P0** | Blocking, data loss, security | Fix group must run first |
| **P1** | Broken feature, bad UX | Include in current run if shares root cause with P0 |
| **P2** | Nice to have, polish | Include ONLY if same root cause as P0/P1; otherwise defer |
| **P3** | Low impact | Defer unless trivial and same root cause |

**Key principle:** A P2 issue that shares a root cause with a P0 gets fixed FOR FREE as part of the P0 fix group. Always include it.

---

## Root Cause Categories Reference

Use these categories when classifying root causes:

| Category | Description | Common Indicators |
|----------|-------------|-------------------|
| **Schema Drift** | Code references columns/tables that don't match actual DB | Wrong column names, PostgREST errors, null data |
| **FK Migration Gap** | Dual FK standardization missed this location | `student_profiles.id` used where `auth.users.id` needed |
| **Missing Auth** | Endpoint lacks ownership/permission verification | No `.eq('student_id', user.id)`, no role check |
| **Missing RLS** | DB policy missing or uses wrong column | Silent empty results, cross-user data exposure |
| **Contract Mismatch** | Frontend reads different shape than API sends | `data.data.key` vs `data.key`, nested vs flat |
| **Stale Types** | TypeScript types don't match actual DB schema | database.types.ts out of date, wrong interfaces |
| **Validation Gap** | Zod allows values DB rejects (or vice versa) | CHECK constraint failures, silent data rejection |
| **Hardcoded Values** | Magic numbers, year constants, phase counts | `=== 8`, `- 2024`, `'WA'` |
| **Dead Code** | Code path that can never execute correctly | Wrong client type, unreachable branches |
| **Missing Feature** | Required capability doesn't exist | No revoke endpoint, no cache, no rate limit |

---

## When to Escalate

Stop and ask the user if:
- A root cause requires a breaking schema change affecting production data
- Two fix groups conflict and you must choose which approach wins
- A root cause challenges an existing ADR or architectural decision
- The red team phase reveals the issue description was wrong (need product input)
- Sprint 1 execution scope unexpectedly exceeds limits (>6 groups, >30 issues, >25 files) — re-decompose and present a revised sprint roadmap
- A P0 security fix needs immediate deploy (confirm strategy)

---

## Anti-Patterns to Avoid

```
❌ WRONG: Fix each issue independently, even when they share a root cause
   → Leads to partial fixes, repeated work, and missed connections

❌ WRONG: Trust issue descriptions without reading the actual code
   → Issues may be stale, wrong, or describe symptoms not causes

❌ WRONG: Skip the red team phase to save time
   → Leads to fixes that break other things or address wrong root cause

❌ WRONG: Fix code but don't document the pattern
   → Same bug class will recur in new code

❌ WRONG: Commit after each individual issue
   → Obscures the holistic nature of the fix; makes git history noisy

❌ WRONG: Cap the planning phase to fit one context window
   → Planning is cheap. You want the full picture — all root causes, all fix groups,
     all sprints — before touching any code. Incomplete plans miss connections between issues.

❌ WRONG: Execute all planned groups in one session without sprint decomposition
   → Editing 40+ files in one session hits context limits mid-fix. Partial fixes are
     harder to debug than deferred ones. Decompose into ≤25-file execution sprints first.

❌ WRONG: Start a new fix group when already past the context budget mid-execution
   → Produces incomplete edits and confusing PRs. Stop after the current group,
     commit, push, and hand off cleanly to the next session.

✅ RIGHT: Plan comprehensively across all issues → decompose into execution sprints →
   execute one sprint per session
```

---

## Checklist (Auto-Verified Per Fix Group)

- [ ] Root cause verified by reading actual code (not just issue description)
- [ ] Red team check: confirmed issue still exists and fix won't break other things
- [ ] Holistic fix resolves ALL issues in the group
- [ ] TypeScript compiles clean (0 errors)
- [ ] All tests pass (existing + new regression tests)
- [ ] Regression test written that would catch the root cause
- [ ] Committed on `fix/<slug>` branch (NOT on main, NOT on plan branch)
- [ ] Commit references all resolved issue numbers
- [ ] **If DB-flagged**: `/data-modeler validate [file]` run after fix — 0 schema issues found

## Checklist (Run-Level)

- [ ] All open issues scanned and classified (🗄️ DB-flagged where relevant)
- [ ] Root cause map built with cross-references
- [ ] `/data-modeler validate` run on all DB-flagged files before root cause grouping
- [ ] Red team phase completed — assumptions challenged
- [ ] **PLAN GATE**: full plan written (all groups, all sprints) on `plan/<slug>` branch → local Codex review → the product lead approved
- [ ] **SPRINT DECOMPOSITION**: full plan split into execution sprints (≤6 groups, ≤30 issues, ≤25 files each) → sprint roadmap presented → the product lead approved Sprint 1 scope
- [ ] `fix/<slug>` branch created from main after plan approval
- [ ] Sprint 1 fix groups executed in dependency order on `fix/<slug>` (subsequent sprints in future sessions)
- [ ] **If migrations written**: applied to staging first, verified, then production
- [ ] Full test suite passes after all changes
- [ ] Build passes (`npx tsc --noEmit`)
- [ ] **CODE REVIEW GATE**: `fix/<slug>` pushed → Claude Code automated review → Joe (@yourusername) merges to main
- [ ] All resolved issues commented and closed with cross-references (after merge)
- [ ] Pattern library updated (memory/common-bugs.md)
- [ ] Memory updated with lessons learned
- [ ] Sprint summary report generated

---

## Skill Output: /deep-fix

### 1. Plan
- Step 1: Scan X open issues
- Step 2: Map Y root causes across Z issues
- Step 3: Red team all assumptions
- Step 4: Plan N fix groups
- Step 5: Execute fix groups in order
- Step 6: Verify no regressions
- Step 7: Document patterns

### 2. Files Created/Modified
| File | Action | Lines |
|------|--------|-------|
| `path/to/file.ts` | Modified | +15, -3 |

### 3. Security Review
| Check | Status | Notes |
|-------|--------|-------|
| User-scoped queries | ✅ Pass | All queries filtered by user_id |
| No sensitive data logged | ✅ Pass | GPA, scores redacted |
| Auth checks present | ✅ Pass | All endpoints verified |
| RLS policies correct | ✅ Pass | Policies match code |

### 4. Tests
| Test File | Tests | Status |
|-----------|-------|--------|
| `tests/path/test_file.ts` | 5 | ✅ All passing |

### 5. Telemetry
_Skip — no LLM operations in this skill._

### 6. Open Questions / Assumptions
| Item | Assumption Made | Needs Confirmation |
|------|-----------------|-------------------|
| [Item] | [Assumption] | ⚠️ Check with product |

### 7. Pattern Library (NEW — unique to /deep-fix)
| Pattern | Category | Issues Prevented | Documented In |
|---------|----------|------------------|---------------|
| Wrong column names | Schema Drift | #333, #314 | memory/common-bugs.md |

### Summary
✅ Deep fix completed
- X root causes identified
- Y fix groups executed
- Z issues resolved
- W regression tests added
- V patterns documented

---

**Note:** This skill is designed for systematic quality improvement, not quick fixes. Run it when the backlog has accumulated related issues, especially after audits or red team sessions. For small, unrelated issues, use `/fix-issue` instead.
