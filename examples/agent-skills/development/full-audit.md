> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /full-audit Skill

This skill performs a comprehensive, zero-assumption audit of the entire the project codebase, user experience, and output quality. It systematically reviews every layer — database, APIs, business logic, components, UI/UX, user journeys, insight quality, security, performance, and accessibility — and files GitHub issues for every finding with root cause analysis.

Unlike `/deep-fix` (which fixes existing issues) or `/peer-review` (which processes external feedback), `/full-audit` is a **proactive discovery tool** that assumes nothing works correctly until proven otherwise.

## How It Differs from Other Skills

| | `/full-audit` | `/deep-fix` | `/fix-issue` | `/security-reviewer` |
|---|---|---|---|---|
| Purpose | Discover ALL problems | Fix known issues by root cause | Fix issues one by one | Security-only review |
| Input | The codebase itself | Open GitHub issues | Open GitHub issues | Specific scope |
| Output | GitHub issues + report | Fixes + commits | Fixes + commits | Security findings |
| Action | Find only — never fix | Find + fix | Find + fix | Find only |
| Scope | Everything | Open issue backlog | Open issue backlog | Security layer |
| Assumption | Nothing works | Issues are real | Issues are real | Code is insecure |

**When to use `/full-audit`:** Before launch, after major feature work, periodically for quality assurance, when bugs keep surprising you.
**When to use `/deep-fix`:** After an audit produces issues to fix.

## Agent Chain

```
prep → /data-modeler (DB layer) → /api-auditor (API layer) → /prompt-auditor (LLM layer) → business-logic → /frontend-auditor (component layer) → ui-ux → user-journeys → /playbook-auditor (insight quality) → /security-reviewer (security) → /performance-auditor (performance) → /a11y-auditor (accessibility) → pattern-analysis → help-content → report
```

> **Phases 1, 2, 3 (LLM), 4, 7, 8, 9, and 10 delegate to specialized audit agents.** Each agent has deeper, more accurate checks than a generic audit description could capture. `/full-audit` orchestrates them and consolidates their findings into one report and one GitHub issue log.

## Usage

```
/full-audit                          # Full audit of everything
/full-audit focus database,api       # Focus on specific layers
/full-audit focus onboarding         # Focus on specific feature area
/full-audit focus ui,a11y            # Focus on UI and accessibility
```

### Focus Options

| Focus | What It Audits |
|-------|---------------|
| `database` | Schema, migrations, RLS, constraints, data integrity |
| `api` | All API routes, auth, validation, error handling |
| `logic` | Business logic, engines, calculations, data transforms |
| `components` | React components, state, props, rendering |
| `ui` | Visual design, dark mode, responsive, brand compliance |
| `journeys` | End-to-end user flows (onboarding → plan → schools → coach) |
| `insights` | Quality of AI outputs, analyses, recommendations |
| `security` | OWASP top 10, RLS, auth, data privacy, coach guardrails |
| `performance` | N+1 queries, bundle size, re-renders, LLM cost |
| `a11y` | WCAG 2.1 AA, keyboard nav, screen readers, contrast |
| `onboarding` | All onboarding phases end-to-end |
| `plan` | "Your Plan" screens and engines |
| `schools` | School list, discovery, fit analysis |
| `coach` | AI coach, chat, proactive messages |

Multiple focuses can be combined: `focus database,api,security`

If no focus is specified, ALL layers are audited.

---

## Pre-Audit: Preparation

### Step 0a: Label Setup

```
1. Determine the next audit round number:
   gh label list --search "audit-round" --json name
   → Find the highest round-N, increment by 1
   → If none exist, start with round-15

2. Create the label for this round:
   gh label create "audit-round-N" --color "5319E7" --description "Full audit round N - [DATE]"

3. Note the label — ALL issues from this audit will be tagged with it
```

### Step 0b: Duplicate Detection Setup

```
1. Fetch all open issues:
   gh issue list --state open --limit 200 --json number,title,labels,body

2. Build a duplicate index:
   - For each open issue, extract key terms (file names, function names, error types)
   - Store as lookup table for checking before creating new issues

3. Rule: Before creating ANY issue, search the index:
   - If exact duplicate exists → skip, note in audit log
   - If related but different → create issue, reference the related one
   - If no match → create new issue
```

### Step 0c: Fresh Codebase Snapshot

```
1. Run full TypeScript check: npx tsc --noEmit
   → Record error count (should be 0; any errors are immediate issues)

2. Run full test suite: npx vitest run
   → Record pass/fail count (any failures are immediate issues)

3. Count current state:
   - Total source files: find src/ -name "*.ts" -o -name "*.tsx" | wc -l
   - Total migrations: ls supabase/migrations/*.sql | wc -l
   - Total API routes: find src/app/api -name "route.ts" | wc -l
   - Total components: find src/components -name "*.tsx" | wc -l
   - Open issues: gh issue list --state open --json number | jq length
```

---

## Phase 1: Database & Schema Audit — delegated to `/data-modeler`

**Goal:** Verify every table, column, constraint, RLS policy, and migration is correct and consistent.

**Run:**
```
/data-modeler audit
```

The `/data-modeler` skill contains the full procedure: FK integrity, RLS completeness (all four policies), column-name drift detection, Zod schema alignment, migration health, and query pattern safety. Its 8 fundamental rules and 7 audit checks cover every failure mode that has produced production bugs in the project.

**After `/data-modeler audit` completes:**
1. Collect all issues it files — they are already tagged with appropriate labels
2. Add `audit-round-N` label to each: `gh issue edit NNN --add-label "audit-round-N"`
3. Record the issue numbers in this audit's summary report under "Phase 1: Database"

**Key checks performed by `/data-modeler`:**
- `student_id → auth.users(id)` (never `student_profiles.id`)
- PostgREST nested joins have real FK constraints
- RLS SELECT/INSERT/UPDATE/DELETE policies on all student data tables
- Column names in queries match actual DB schema (`sat_math_25`, not `sat_25`)
- DB CHECK constraints match Zod enum values
- Zod strip-mode silent NULL (missing fields default to NULL)
- Migration ordering (DROP FK → update data → re-add FK)
- Staging/production sync check

---

## Phase 2: API Route Audit — delegated to `/api-auditor`

**Goal:** Verify every API endpoint is correct, secure, and handles all edge cases.

**Run:**
```
/api-auditor audit
```

The `/api-auditor` skill contains the full procedure across 10 checks (2a–2j). It knows the exact patterns the project uses: `withStudentAuth` wrappers, `ApiErrors` helpers, the standard `{ success, data, error }` envelope, `safeParse` vs `parse`, LLM route requirements (`maxDuration`, `checkSpendingCap`, `recordLLMTelemetry`), and the 3-step parent verification pattern.

**After `/api-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 2: API"

**Key checks performed by `/api-auditor`:**
- Auth completeness: every handler has `getUser()` or `withStudentAuth` wrapper (missing = P0 IDOR)
- Input validation: `safeParse` (not `parse`) on all POST/PUT/PATCH bodies
- Response envelope: `{ success: true, data: {...} }` — data not naked at root
- `ApiErrors.*` used for all error responses (not raw `NextResponse.json`)
- LLM routes: `maxDuration`, `checkSpendingCap`, `recordLLMTelemetry` all present
- Parent routes: 3-step verification + `targetStudentId` for all DB queries
- `adminClient` used only in server routes with documented RLS bypass reason
- Top-level try/catch with `logError()` in every handler

---

## Phase 3: Business Logic & Engine Audit

**Goal:** Verify every calculation, analysis, and data transformation produces correct results.

### 3a: Engine Inventory

```
1. Find all analysis engines (src/lib/engines/, src/lib/analysis/, etc.)
2. For each engine:
   - What does it calculate?
   - What inputs does it need?
   - What does it output?
   - Is the logic correct?
   - Are edge cases handled (null inputs, zero values, extreme ranges)?
```

### 3b: Calculation Verification

```
For each calculation/score:
1. Verify the formula is correct (not just "runs without error")
2. Test with known inputs → expected outputs
3. Test edge cases:
   - Zero values (GPA 0.0, income $0)
   - Maximum values (GPA 5.0, SAT 1600)
   - Missing/null inputs
   - Boundary conditions
4. Verify `??` is used instead of `||` for numeric defaults
5. Verify no division by zero is possible
```

### 3c: Data Flow Verification

```
Trace data from source to display:
1. User enters data in form
2. Form validates with Zod schema
3. API receives and validates
4. Database stores
5. API reads back
6. Frontend receives and displays

At each step, verify the data shape and values are preserved correctly.
Watch for:
- Field name mismatches (form field ≠ API field ≠ DB column)
- Type coercions (string "3.5" → number 3.5)
- Null vs undefined handling
- Array vs single value
```

### 3d: LLM Integration Audit — delegated to `/prompt-auditor`

**Run:**
```
/prompt-auditor audit
```

The `/prompt-auditor` skill contains the full procedure across 9 checks (2a–2i). It knows the exact patterns the project uses: all 6 coach guardrails, `wrapUserContent()` XML injection resistance, AUTHORITATIVE directive for major/school/career binding, cache-first pattern (synchronous await, not fire-and-forget), `MODELS.HAIKU` vs `MODELS.SONNET` selection, data minimization, `JSON.parse()` fallback, token efficiency, and `checkSpendingCap()` + `recordLLMTelemetry()`.

**After `/prompt-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 3: LLM"

**Key checks performed by `/prompt-auditor`:**
- All 6 coach guardrails present + `detectEssayRequest()` called before LLM
- `wrapUserContent()` on all user-supplied free-text content
- AUTHORITATIVE directive on `intendedMajors`, `intended_career`, school names
- Cache-first pattern: DB check → cache hit returns early → LLM only on miss → `await` write (not fire-and-forget)
- Model imported from `MODELS.*` constants (no hardcoded strings)
- Financial data excluded from coach context
- `JSON.parse()` in `try/catch` with rule-based fallback
- `checkSpendingCap()` before every LLM call
- `recordLLMTelemetry()` after (including in catch block)

### Issue Creation: Business Logic

```
gh issue create \
  --title "[Logic] Brief description" \
  --label "bug,audit-round-N,business-logic" \
  --body "..."
```

---

## Phase 4: Component & Frontend Audit — delegated to `/frontend-auditor`

**Goal:** Verify every React component renders correctly, handles state properly, and follows patterns.

**Run:**
```
/frontend-auditor audit
```

The `/frontend-auditor` skill contains the full procedure across 8 checks (2a–2h). It knows the exact failure modes that have produced the project bugs: wrong API response key (`result.activities` vs `result.data.activities`), missing AbortController signal, DOMException vs Error for AbortError, missing `!response.ok` check before `!result.success`, silent `if(res.ok)` pattern, parent routes using `user.id` instead of URL params, and missing `useCallback` on fetch functions.

**After `/frontend-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 4: Components"

**Key checks performed by `/frontend-auditor`:**
- API response consumption: reads `result.data.X`, checks `!response.ok || !result.success`, reads `result.error?.message` (not `result.error` as string)
- AbortController: present in every `useEffect` fetch, signal passed to `fetch()`, AbortError guarded, cleanup returned
- Three states: `isLoading`, `error`, and data — all declared and rendered
- Async action state: buttons disabled during operations, Loader2 spinner shown, finally-block reset
- Forms: React Hook Form + zodResolver, submit button disabled while saving
- Parent route safety: `studentId` from URL params (not `user.id`), explicit 403 handler
- `useCallback` on fetch functions in useEffect dependency arrays (prevents infinite loops)
- TypeScript safety: no `any` on API response types, optional chaining on nullable fields

---

## Phase 5: UI/UX Visual Audit

**Goal:** Verify the visual experience is premium-quality on all devices and modes.

### 5a: Dark Mode Audit

```
For every page and component:
1. Does it use semantic color classes?
   ✅ bg-card, bg-background, bg-muted, text-foreground, text-muted-foreground, border-border
   ❌ bg-white, bg-gray-100, text-gray-900, border-gray-200
2. Are images/icons visible in both modes?
3. Are shadows appropriate for dark mode?
4. Are form inputs readable in dark mode?
5. Are charts/graphs adapted for dark mode?
6. Are status indicators visible in both modes?
```

### 5b: Responsive Design Audit

```
For every page:
1. Test at breakpoints: 375px, 393px, 768px, 1024px, 1280px
2. Check:
   - No horizontal scrolling at any breakpoint
   - Text is readable at all sizes (min 16px on mobile)
   - Images scale properly
   - Navigation is appropriate for screen size
   - Forms are usable on mobile
   - Tables don't overflow
   - Cards stack correctly
   - Modals don't overflow viewport
```

### 5c: Brand Compliance

```
For every user-facing page:
1. Does the tone match brand voice? (warm, direct, knowledgeable)
2. Are colors consistent with the design system?
3. Is typography consistent (font sizes, weights, line heights)?
4. Is spacing consistent with the spacing scale?
5. Are icons consistent in style and size?
6. Does it feel premium, not like "education software"?
```

### 5d: Loading States & Skeleton Screens

```
For every data-dependent section:
1. Is there a loading indicator or skeleton?
2. Does it avoid layout shift (CLS) when data loads?
3. Are skeleton screens realistic (match final layout)?
4. Is the loading state fast enough (or show skeleton)?
```

### 5e: Error States & Empty States

```
For every section that could be empty or error:
1. Is there a helpful empty state message?
2. Does the empty state guide the user to action?
3. Are error messages user-friendly (not technical)?
4. Can the user retry after an error?
5. Are error boundaries in place?
```

### Issue Creation: UI/UX

```
gh issue create \
  --title "[UI] Brief description" \
  --label "bug,audit-round-N,ux" \
  --body "..."
```

---

## Phase 6: User Journey Audit

**Goal:** Walk through every user flow end-to-end, verifying the experience is complete and functional.

### 6a: Onboarding Journey

```
Walk through all 8 onboarding phases:
1. Phase 1: Welcome/Profile — name, grade, school
2. Phase 2: Academics — GPA, courses, test scores
3. Phase 3: Activities — extracurriculars, leadership
4. Phase 4: Interests — career interests, academic preferences
5. Phase 5: Schools — initial school preferences
6. Phase 6: Financial — family financial context
7. Phase 7: Goals — college goals, priorities
8. Phase 8: Review — summary and confirmation

For each phase, verify:
- Form fields work correctly
- Validation messages are helpful
- Progress is saved (can leave and return)
- Navigation between phases works (back/next)
- Data flows to the correct API endpoints
- Data is stored correctly in the database
- Mobile experience is smooth
- Phase completion is tracked accurately
```

### 6b: "Your Plan" Journey

```
After onboarding, verify the plan experience:
1. Where You Stand — profile summary, GPA context, competitive position
2. Priorities — strategic recommendations ordered by fit-first framework
3. Timeline — four-year journey with current phase detection
4. What This Opens Up — schools that match, merit opportunities

For each screen:
- Data is loaded correctly from engines
- Insights are accurate and personalized
- Recommendations are actionable
- Display is clear and well-organized
- Mobile layout works
- Navigation between screens works
```

### 6c: School List Journey

```
1. School discovery — search, filter, browse
2. Adding schools to lists (My Schools, Exploring, Not Interested)
3. Moving schools between lists
4. School detail view — fit analysis, cost, deadlines
5. Comparison features

For each action:
- State updates correctly and persists
- List counts update in real-time
- Fit indicators are accurate
- School data is current (freshness dates)
```

### 6d: AI Coach Journey

```
1. Open coach chat
2. Ask a basic question
3. Ask about a specific school
4. Try to get the coach to write an essay (should refuse)
5. Check proactive message behavior
6. Verify context awareness (coach knows student's profile)

For each interaction:
- Response is accurate and helpful
- Guardrails are enforced
- Context is correct (references actual student data)
- Telemetry is recorded
- Response time is acceptable
```

### 6e: Parent Journey (if applicable)

```
1. Parent account creation/linking
2. Viewing student's progress
3. Parent-specific recommendations
4. Family financial context

For each action:
- Parent sees correct student data (not another student's)
- Parent cannot modify student-only data
- Authorization is enforced
```

### Issue Creation: Journey

```
gh issue create \
  --title "[Journey] Brief description" \
  --label "bug,audit-round-N,journey" \
  --body "..."
```

---

## Phase 7: Insight Quality Audit — delegated to `/playbook-auditor`

**Goal:** Verify that the project provides more value than a $10K human college admissions consultant.

**Run:**
```
/playbook-auditor audit
```

The `/playbook-auditor` skill contains the full procedure across 10 checks (2a–2j) and a boilerplate detection algorithm. It knows every known failure mode in the project playbook generation: wrong major in tagline (MAJOR BINDING directive), honest assessment leading with the wrong strength (startup buried under varsity), negative net cost, wrong residency scholarships, nursing essay for pre-law student, junior tasks for submitted senior, template slots in story inventory, placeholder Strategic Positioning in PDF, and identical recommender boilerplate across students.

**After `/playbook-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 7: Insight Quality"

**Key checks performed by `/playbook-auditor`:**
- Strategic identity tagline matches `The [declared major] Path` (AUTHORITATIVE binding)
- Honest Assessment leads with strongest differentiator (startup > varsity sport > GPA)
- School breakdown counter non-zero, fit categories normalized (`Reach` not `reach`)
- Financial: `Math.max(0, ...)` net cost clamp, 3 different budget scenarios, correct WUE eligibility
- Scholarship: residency checks via `scholarship_name + special_eligibility`, no activity-specific mismatch
- Essay prompts filtered by `filterEssayPromptsByMajor()` at all 3 sites
- Action plan phase-correct: `isDecisionMode` for submitted seniors, `sortedAnchor` uses `scoreActivityImpact()`
- Story inventory has real text (no `[describe the challenge]` slots)
- Recommender strategy differentiates across students (boilerplate detection)
- PDF: no placeholder sections, no garbled text, activity bullets have descriptions

---

## Phase 8: Security Red Team — delegated to `/security-reviewer`

**Goal:** Actively try to break the application's security.

**Run:**
```
/security-reviewer audit
```

The `/security-reviewer` skill contains the full security red team procedure: authentication bypass attempts, authorization escalation (IDOR, parent → student cross-access), RLS policy verification, input injection testing (SQL, XSS, prompt injection), data leakage checks, coach guardrail testing, and privacy checks (no PII in logs, no financial data in coach context).

**After `/security-reviewer audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 8: Security"

**Key checks performed by `/security-reviewer`:**
- Auth: every route has `getUser()` or `withStudentAuth` — missing = P0 IDOR
- IDOR: student data gated by `student_id = auth.uid()` RLS, not just route checks
- Parent auth: 3-step verification — authenticated, is parent, linked to target student
- Admin routes: `requireAdminRoute()` with AAL2 MFA, fail-closed on error
- Prompt injection: `wrapUserContent()` on all free-text before LLM calls
- Coach guardrails: all 6 present, `detectEssayRequest()` gates before LLM
- Data minimization: no financial fields in coach context, no PII in logs
- Spending cap: `checkSpendingCap()` before all LLM calls

---

## Phase 9: Performance Audit — delegated to `/performance-auditor`

**Goal:** Identify performance bottlenecks and cost waste.

**Run:**
```
/performance-auditor audit
```

The `/performance-auditor` skill contains the full procedure across 9 checks (2a–2i). It knows the exact failure modes that degrade the project production performance: N+1 queries in playbook assembly, sequential awaits where `Promise.all()` would do, `SELECT *` in production routes, unbounded queries on the 4,046-row schools table, missing cache on strategic identity generation, React context providers re-rendering on every keystroke, and heavy library imports on cold-start-sensitive routes.

**After `/performance-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 9: Performance"

**Key checks performed by `/performance-auditor`:**
- N+1 queries: loops with individual DB calls → `.in(ids)` batch
- Sequential independent awaits → `Promise.all()`
- Unbounded queries: every list query must have `.limit(N)` or `.range()`
- `SELECT *` in production routes (never acceptable outside tests/scripts)
- Missing cache on LLM generators (strategic identity, action plan, brag sheet)
- React: `useMemo` on context values, `useCallback` on handlers, stable keys
- LLM cost: `MODELS.HAIKU` for extraction, batch N activities in 1 call not N calls
- Index coverage on high-frequency tables (`student_activities`, `school_list_items`, `coach_conversations`)
- Dynamic `import()` for heavy libraries (`exceljs`, PDF) in high-frequency routes

---

## Phase 10: Accessibility Audit — delegated to `/a11y-auditor`

**Goal:** Verify WCAG 2.1 AA compliance across the entire application.

**Run:**
```
/a11y-auditor audit
```

The `/a11y-auditor` skill contains the full WCAG 2.1 AA procedure across 9 checks (2a–2i). It knows the exact failure patterns in the project Tailwind/shadcn stack: `focus:outline-none` without `focus-visible:ring` (keyboard trap), muted-foreground text below 4.5:1 on white backgrounds, buttons without text using `aria-label`, selects without `<label>`, heading hierarchy violations, aria-live missing on coach chat messages, and touch targets below 44×44px.

**After `/a11y-auditor audit` completes:**
1. Add `audit-round-N` label to each issue it files
2. Record issue numbers in this audit's summary under "Phase 10: Accessibility"

**Key checks performed by `/a11y-auditor`:**
- Color contrast: ≥4.5:1 normal text, ≥3:1 large text, in both light and dark modes
- Keyboard: all interactions accessible, logical tab order, no traps
- Focus indicators: `focus:outline-none` always paired with `focus-visible:ring`
- ARIA: `aria-label` on icon-only buttons, live regions on coach chat updates
- Headings: single `<h1>`, logical `h1→h2→h3` hierarchy per page
- Forms: `<label htmlFor>` + `aria-describedby` for errors, `aria-required`
- Images: `alt` text present, decorative images have `aria-hidden="true"`
- Touch targets: all interactive elements ≥44×44px on mobile
- Dynamic content: loading/error states announced, modal focus trapping

---

## Phase 11: Closed Issue Pattern Analysis

**Goal:** Mine closed issues for systemic root causes that keep producing new bugs.

### 11a: Closed Issue Mining

```
1. Fetch all closed issues:
   gh issue list --state closed --limit 500 --json number,title,labels,body,closedAt

2. Categorize by root cause:
   - Schema drift (wrong column names, missing columns)
   - FK migration gap (student_profiles.id vs auth.users.id)
   - Missing auth/RLS
   - Contract mismatch (frontend vs API shape)
   - Stale types
   - Validation gap
   - Hardcoded values
   - Race conditions
   - Null handling
   - Dark mode violations
   - Form→DB field mismatches

3. Count occurrences of each root cause category
```

### 11b: Recurrence Detection

```
1. For each root cause category that has been fixed before:
   - Search the CURRENT codebase for the same pattern
   - Has the same bug type recurred in new code?
   - Are there preventive measures in place?

2. Cross-reference with open issues:
   - Do any open issues share root causes with frequently-closed patterns?
```

### 11c: Systemic Root Cause Report

```
For each recurring pattern:
1. How many times has this type of bug appeared? (closed + open)
2. What was the original cause?
3. Was the underlying cause actually fixed, or just the symptom?
4. What preventive measure would stop this class of bug forever?
5. Is there a lint rule, test, or pattern that could catch it?
```

### Issue Creation: Systemic Patterns

```
gh issue create \
  --title "[Pattern] Recurring root cause: description" \
  --label "refactor,audit-round-N,systemic" \
  --body "$(cat <<'EOF'
## Systemic Root Cause Pattern

**Pattern:** [Name]
**Times Found:** N instances across M closed issues + K open issues
**Severity:** P0/P1/P2

### Historical Instances
| Issue | Status | When | Symptom |
|-------|--------|------|---------|
| #NNN | Closed | [date] | [symptom] |
| #NNN | Open | [date] | [symptom] |

### Root Cause
[Why this keeps happening]

### Current State
[Is the pattern still present in the codebase?]

### Preventive Fix
[What would eliminate this class of bug permanently]

### Detection
[Grep pattern, test, or lint rule to catch it]

---
*Identified by `/full-audit` pattern analysis, round N*
EOF
)"
```

---

## Phase 12: Help Content Audit

**Goal:** Verify that help articles match the current product and provide accurate, useful guidance for both students and parents.

### 12a: Content Currency Check

```
1. Fetch all published help articles:
   SELECT slug, title, audience, updated_at, content_md
   FROM help_articles WHERE published = true

2. For each article, cross-reference against the CURRENT product:
   - Do navigation references match? (Home, My Profile, Schools, My Plan)
   - Do feature descriptions match what the code actually does?
   - Are screenshots/examples still accurate?
   - Do linked paths (/help/..., /schools, /plan, etc.) resolve?
   - Is the pricing correct ($399/year)?

3. Check for stale content signals:
   - References to removed features (old dashboard, strategy pages, etc.)
   - Wrong nav labels or page names
   - Descriptions of flows that have changed (onboarding phases, school list behavior)
   - Outdated terminology from pre-ADR-015 era
```

### 12b: Role Coverage Check

```
1. Count articles by audience:
   - student-only articles: should cover getting started, home, profile, schools, plan, coach
   - parent-only articles: should cover parent home, financial picture, what parents can do, permissions
   - both: should cover coach, family accounts, fit explanation, FAQs, external resources

2. Gap analysis:
   - Is there a help article for every major feature/page?
   - Are parent-specific concerns addressed? (finances, how to support, what they can see)
   - Are student-specific concerns addressed? (getting started, what to do next, how fit works)

3. Verify role filtering works:
   - parent-only articles should have audience = 'parent'
   - student articles should NOT reference parent-only features
   - "both" articles should use inclusive language
```

### 12c: Feature Context Mapping

```
1. Find all HelpTooltip instances with featureContext:
   grep -r 'featureContext=' src/components/ src/app/

2. For each unique featureContext value, verify:
   - A matching help_articles row exists with that feature_context
   - The "Learn more" link resolves to a relevant article
   - If no match exists, flag as gap (tooltip's "Learn more" link will be broken)
```

### 12d: Content Quality Check

```
1. Tone: Does each article match brand voice? (warm, direct, knowledgeable — not corporate or condescending)
2. Accuracy: Do "how to" instructions match actual UI flows?
3. Completeness: Does each article answer the question its title implies?
4. Links: Do internal links (/help/...) point to existing articles?
5. Search: Are search_keywords populated and relevant?
```

### Issue Creation: Help Content

```
gh issue create \
  --title "[Help] Brief description" \
  --label "bug,audit-round-N,ux" \
  --body "..."
```

Priority guidelines:
- **P1**: Article describes a feature that no longer exists or works differently
- **P2**: Article is accurate but incomplete, tone is off, or minor details are stale
- **Enhancement**: Missing article for a feature that should have help coverage

---

## Phase 13: Summary Report

After all phases complete and all issues are filed, generate an executive summary.

### Report Template

```markdown
# Full Audit Report: Round N — [DATE]

## Executive Summary

| Metric | Value |
|--------|-------|
| Audit scope | [Full / focused areas] |
| Source files reviewed | X |
| API routes reviewed | X |
| Components reviewed | X |
| Migrations reviewed | X |
| Issues created | X |
| Critical (P0) | X |
| High (P1) | X |
| Medium (P2) | X |
| Enhancements | X |
| Systemic patterns found | X |

## Issue Breakdown by Phase

| Phase | Agent | Issues Found | P0 | P1 | P2 | Enhancement |
|-------|-------|-------------|----|----|----|----|
| Database & Schema | `/data-modeler` | X | | | | |
| API Routes | `/api-auditor` | X | | | | |
| Business Logic + LLM | `/prompt-auditor` + full-audit | X | | | | |
| Components & Frontend | `/frontend-auditor` | X | | | | |
| UI/UX | full-audit | X | | | | |
| User Journeys | full-audit | X | | | | |
| Insight Quality | `/playbook-auditor` | X | | | | |
| Security | `/security-reviewer` | X | | | | |
| Performance | `/performance-auditor` | X | | | | |
| Accessibility | `/a11y-auditor` | X | | | | |
| Help Content | full-audit | X | | | | |
| Systemic Patterns | full-audit | X | | | | |
| **Total** | | **X** | | | | |

## Critical Issues (P0) — Must Fix Before Launch

| # | Title | Phase | Root Cause |
|---|-------|-------|------------|
| #NNN | [title] | [phase] | [root cause] |

## High Priority Issues (P1) — Should Fix Before Launch

| # | Title | Phase | Root Cause |
|---|-------|-------|------------|
| #NNN | [title] | [phase] | [root cause] |

## Systemic Root Cause Patterns

| Pattern | Instances | Recurrence Risk | Preventive Fix |
|---------|-----------|-----------------|----------------|
| [pattern] | N | High/Medium/Low | [fix] |

## Consultant Parity Assessment

| Area | Current Coverage | Gap | Recommendation |
|------|-----------------|-----|----------------|
| Academic fit | 95% | Minor | [action] |
| Financial analysis | 90% | Medium | [action] |
| Timeline/deadlines | 85% | Medium | [action] |
| School recommendations | 95% | Minor | [action] |
| Essay strategy | 0% (intentional) | N/A | Coach guidance only |

## Quality Scores (Subjective Assessment)

| Dimension | Score (1-10) | Notes |
|-----------|-------------|-------|
| Code quality | X | [brief] |
| Test coverage | X | [brief] |
| Security posture | X | [brief] |
| UI/UX polish | X | [brief] |
| Mobile experience | X | [brief] |
| Dark mode | X | [brief] |
| Accessibility | X | [brief] |
| Insight quality | X | [brief] |
| Performance | X | [brief] |
| Overall launch readiness | X | [brief] |

## Recommended Next Steps

1. **Immediate:** Run `/deep-fix` on P0 issues
2. **This week:** Address P1 issues
3. **Before launch:** Resolve all P1+, assess P2s
4. **Ongoing:** Implement preventive fixes for systemic patterns

## Comparison to Previous Audit

| Metric | Round N-1 | Round N | Trend |
|--------|-----------|---------|-------|
| Issues found | X | X | ↑/↓/→ |
| P0 issues | X | X | ↑/↓/→ |
| Systemic patterns | X | X | ↑/↓/→ |
| Launch readiness | X/10 | X/10 | ↑/↓/→ |

---
*Generated by `/full-audit` round N — [DATE]*
*Review all issues: `gh issue list --label audit-round-N`*
```

Save report to: `reports/audit_round_N_report.md`

---

## Issue Severity Guidelines

| Severity | Label | Criteria | Examples |
|----------|-------|----------|---------|
| **P0** | `P0` | Data loss, security breach, app crash, blocking | Auth bypass, data corruption, blank screen |
| **P1** | `P1` | Broken feature, wrong data shown, bad UX | Wrong GPA displayed, form won't submit, dark mode unreadable |
| **P2** | `P2` | Polish, minor UX, edge cases | Slight misalignment, rare edge case, minor copy issue |
| **Enhancement** | `enhancement` | Opportunity to improve (not broken) | Better insight, new feature, UX improvement |

### Issue Body Template (Standard)

Every issue created by this audit MUST use the standardized 8-section template at `.github/ISSUE_TEMPLATE/bug_report.md`.

Audit-time issues are **discovery issues** — sections 2–8 may be marked `TBD — fill before implementation`. They MUST be completed before `/deep-fix` or `/fix-issue` begins work on that issue.

Minimum required at filing time (sections 1 + header):

```markdown
**Severity:** P0/P1/P2/Enhancement
**Found by:** /full-audit round N, Phase X
**File(s):** `path/to/file.ts:line_number`

## 1. Root Cause

**What failed at the system level (not just symptom)?**
[Clear description — trace to underlying mistake, not just symptom]

**Evidence:** [Code snippet, query result, or stack trace]

**Why did existing guardrails/tests not catch it?**
[No test existed / test covered wrong path / pattern was new]

## 2. Proposed Fix
TBD — fill before implementation

## 3. Scope / Non-Goals
TBD — fill before implementation

## 4. Affected Files / Interfaces / Data
**API routes:** [list]
**Libraries/components:** [list]
**DB tables/RLS/migrations:** [list if applicable]

## 5. Security / Privacy Checks
TBD — fill before implementation (required if auth/RLS/PII involved)

## 6. Test Plan
TBD — fill before implementation

## 7. Rollout + Rollback
TBD — fill before implementation (required for DB/auth/security/perf changes)

## 8. Ownership + Execution
**Owner:** Claude Code
**Definition of done:**
- [ ] Code merged
- [ ] Tests merged and passing
- [ ] Staging verified
- [ ] Production verification complete

### Related Issues
- #NNN (if related)
- Previously fixed: #NNN (if regression)

---
*Found by `/full-audit` round N, Phase X*
```

---

## When to Escalate

Stop and ask the user if:
- A finding challenges an existing ADR or architectural decision
- A security vulnerability requires immediate attention (potential data breach)
- The audit reveals the system is fundamentally broken in a way that requires redesign
- You discover potential data corruption in production
- The audit scope is taking significantly longer than expected
- You find evidence that a previous fix introduced a new bug

---

## Anti-Patterns to Avoid

```
❌ WRONG: Fix bugs as you find them
   → This is an AUDIT, not a fix sprint. File issues only.

❌ WRONG: Skip a phase because "we checked that last time"
   → Every audit is fresh. Assume nothing.

❌ WRONG: Create vague issues ("something seems wrong with the coach")
   → Every issue must have root cause, evidence, and suggested fix.

❌ WRONG: Create duplicate issues
   → Always check the duplicate index before creating.

❌ WRONG: Only look at the code, not the actual user experience
   → Walk through journeys as a real user would.

❌ WRONG: Rate everything as P0
   → Be honest about severity. P0 means "app is broken/unsafe."

❌ WRONG: Skip the pattern analysis phase
   → Finding systemic causes is MORE valuable than finding individual bugs.

✅ RIGHT: File precise issues with root causes, walk through journeys,
   analyze patterns, and produce an honest assessment of launch readiness.
```

---

## Checklist (Per Phase)

- [ ] Every file in scope has been reviewed
- [ ] Every finding has a GitHub issue with root cause
- [ ] No duplicates created (checked against existing issues)
- [ ] Severity is honest and consistent
- [ ] All issues tagged with `audit-round-N`

## Checklist (Audit-Level)

- [ ] All phases completed (or focused phases if scoped)
- [ ] TypeScript status recorded
- [ ] Test suite status recorded
- [ ] Duplicate detection applied throughout
- [ ] Closed issue pattern analysis completed
- [ ] Summary report generated and saved
- [ ] Issue count and severity breakdown tallied
- [ ] Launch readiness score assessed
- [ ] Recommended next steps documented
- [ ] All issues viewable via `gh issue list --label audit-round-N`

---

## Skill Output: /full-audit

### 1. Plan
- Step 1: Preparation (labels, duplicate index, snapshot)
- Step 2: `/data-modeler audit` — DB layer (FK, RLS, column drift, Zod alignment, migration health)
- Step 3: `/api-auditor audit` — API layer (auth, validation, response shape, LLM requirements, parent routes)
- Step 4: `/prompt-auditor audit` — LLM layer (coach guardrails, injection resistance, cache-first, model selection, spending cap)
- Step 5: Business logic engines audit (calculations, data flow, edge cases)
- Step 6: `/frontend-auditor audit` — Component layer (API consumption, AbortController, loading/error states, parent route safety)
- Step 7-8: UI/UX, user journeys
- Step 9: `/playbook-auditor audit` — Insight quality (personalization, financial invariants, essay filtering, PDF completeness)
- Step 10: `/security-reviewer audit` — Security red team (auth bypass, IDOR, injection, data leakage)
- Step 11: `/performance-auditor audit` — Performance (N+1, sequential awaits, unbounded queries, cache gaps, re-renders)
- Step 12: `/a11y-auditor audit` — Accessibility (WCAG 2.1 AA: contrast, keyboard, ARIA, forms, touch targets)
- Step 13: Help content audit (currency, role coverage, feature context mapping, quality)
- Step 14: Closed issue pattern analysis
- Step 15: Summary report generation

### 2. Issues Created
| # | Title | Phase | Severity | Root Cause |
|---|-------|-------|----------|------------|
| [auto-populated from audit] |

### 3. Security Review
| Check | Status | Notes |
|-------|--------|-------|
| Auth bypass attempted | ✅/❌ | [details] |
| RLS bypass attempted | ✅/❌ | [details] |
| Input injection tested | ✅/❌ | [details] |
| Data leakage checked | ✅/❌ | [details] |
| Coach guardrails tested | ✅/❌ | [details] |

### 4. Pattern Analysis
| Pattern | Instances | Risk | Prevention |
|---------|-----------|------|------------|
| [auto-populated from analysis] |

### 5. Launch Readiness
| Dimension | Score | Blocking Issues |
|-----------|-------|-----------------|
| [auto-populated from assessment] |

### Summary
- Audit round: N
- Phases completed: X/14 (7 delegated to specialized agents: /data-modeler, /api-auditor, /prompt-auditor, /frontend-auditor, /playbook-auditor, /security-reviewer, /performance-auditor, /a11y-auditor)
- Issues created: X (P0: X, P1: X, P2: X, Enhancement: X)
- Systemic patterns: X
- Launch readiness: X/10
- Recommended action: [/deep-fix on P0s | launch ready | needs major work]

---

**Note:** This skill is the most comprehensive quality assurance tool in the the project toolkit. Run it before any launch decision, after major feature additions, and periodically during development. Its output feeds directly into `/deep-fix` for systematic resolution. The goal is simple: **no more surprise bugs.**
