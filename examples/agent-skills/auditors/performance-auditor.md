> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /performance-auditor Skill

A standalone backend and frontend performance audit skill for the project. Use this after adding new API routes, LLM calls, database queries, or React components — to catch N+1 queries, sequential awaits, missing indexes, unbounded result sets, and React re-render traps before they degrade production performance.

the project is serverless-first (Vercel + Supabase). Every millisecond of unnecessary latency increases cold start cost and degrades the student experience. Performance bugs here are often invisible until the app is under real load.

## Usage

```
/performance-auditor audit              — Full performance audit across backend + frontend
/performance-auditor validate [file]   — Audit a specific file (route, component, lib)
/performance-auditor queries           — DB query audit only (N+1, indexes, unbounded)
/performance-auditor frontend          — React performance audit only (memo, re-renders, bundles)
/performance-auditor llm               — LLM cost efficiency audit (model selection, batching, caching)
```

---

## the project Performance Fundamentals

Read these before doing anything. Every recurring performance bug traces back to one of these.

### Rule 1 — N+1 Queries Must Be Batched

Loading a list and then querying each item individually is the most common database performance bug.

```typescript
// ❌ WRONG — N+1: one query per school
for (const school of schools) {
  const data = await supabase.from('school_financial_data')
    .select('*')
    .eq('school_id', school.id)
    .single();
}

// ✅ CORRECT — 1 query for all schools
const schoolIds = schools.map(s => s.id);
const { data } = await supabase.from('school_financial_data')
  .select('*')
  .in('school_id', schoolIds);
```

**N+1 hotspots in the project:** school list rendering, playbook data assembly, coach context building.

### Rule 2 — Independent Async Operations Must Run in Parallel

Sequential awaits for independent operations are the most common latency bug in Next.js API routes.

```typescript
// ❌ WRONG — 3 sequential DB calls: 300ms + 300ms + 300ms = 900ms
const profile = await getStudentProfile(userId);
const schools = await getStudentSchools(userId);
const activities = await getStudentActivities(userId);

// ✅ CORRECT — parallel: max(300ms, 300ms, 300ms) = 300ms
const [profile, schools, activities] = await Promise.all([
  getStudentProfile(userId),
  getStudentSchools(userId),
  getStudentActivities(userId),
]);
```

**Parallel win threshold:** If two operations don't depend on each other's data, they MUST run in parallel.

### Rule 3 — All Queries Must Have a LIMIT

Unbounded queries are a correctness and performance time bomb — they work fine on small datasets and explode in production.

```typescript
// ❌ WRONG — returns all rows, no limit
const { data } = await supabase.from('schools').select('*');

// ✅ CORRECT — bounded result set
const { data } = await supabase.from('schools')
  .select('id, name, fit_category')
  .eq('student_id', userId)
  .limit(50);  // or .range() for pagination
```

**Rule:** Any query that returns a list MUST have `.limit()` or explicit `.range()` pagination.

### Rule 4 — SELECT * Must Never Reach Production

Selecting all columns is wasteful when only 3 fields are needed. It increases network payload, DB load, and serialization cost.

```typescript
// ❌ WRONG — pulls every column including large text fields
const { data } = await supabase.from('student_activities').select('*');

// ✅ CORRECT — explicit columns the caller actually uses
const { data } = await supabase.from('student_activities')
  .select('id, activity_name, role_position, impact_description, hours_per_week');
```

**Exception:** `select('*')` is acceptable in unit tests and seed scripts. Never in production route handlers.

### Rule 5 — Cache Before Every Expensive Call

LLM calls, school data aggregation, and financial calculations that produce deterministic results for a given student must be cached.

```typescript
// ✅ CORRECT — check cache, return early if hit
const cached = await supabase.from('strategic_playbooks')
  .select('brag_sheet')
  .eq('student_id', userId)
  .single();

if (cached.data?.brag_sheet && !forceGenerate) {
  return NextResponse.json({ success: true, data: cached.data.brag_sheet, cached: true });
}

// Only runs on cache miss
const result = await callLLM(...);
await supabase.from('strategic_playbooks').upsert({ student_id: userId, brag_sheet: result });
```

**Cache scope rules:** student-level content (playbook, identity) → `student_id` scope. School-specific content → `student_id + school_id` scope.

### Rule 6 — React Components Must Not Re-render Without Cause

Unnecessary re-renders are the most common React performance bug. They are invisible in dev mode and degrade production UX.

```typescript
// ❌ WRONG — new object reference on every render triggers child re-render
function ParentComponent() {
  const options = { limit: 10, sort: 'name' };  // new object every render
  return <ChildComponent options={options} />;
}

// ✅ CORRECT — stable reference
const OPTIONS = { limit: 10, sort: 'name' };  // defined outside component

// Or for dynamic values:
const options = useMemo(() => ({ limit: 10, sort: name }), [name]);
```

**the project re-render hotspots:** CoachProvider (re-renders entire app on each message), school list filtering, plan page data loading.

### Rule 7 — LLM Calls Must Not Be Duplicated Across Routes

Multiple routes calling the same LLM operation for the same student is a cost and latency bug.

```typescript
// ❌ WRONG — identity generation called from both /playbook-data and /plan-export
// Student opens plan → LLM call
// Student downloads PDF → same LLM call again

// ✅ CORRECT — generate once, cache, serve from cache everywhere
// /playbook-data generates and caches strategic_identity
// /plan-export reads from cache, never calls LLM directly
```

**Audit question:** Does any LLM operation get triggered by multiple different user actions that could share a cached result?

---

## Phase 1: Establish Scope

```
For /performance-auditor audit:
1. List all API route files: find src/app/api -name "route.ts" | sort
2. List all lib files: find src/lib -name "*.ts" | grep -v __tests__ | sort
3. List all plan generator files: find src/lib/plan -name "*.ts" | sort
4. List all LLM files: find src/lib/llm -name "*.ts" | grep -v __tests__ | sort
5. List key React components: find src/components -name "*.tsx" | grep -v __tests__ | sort
6. Identify files most likely to have performance issues:
   - Routes with multiple DB calls
   - LLM generator files
   - School list and plan data assembly routes
   - Context providers that wrap large subtrees
```

---

## Phase 2: Audit Checks

### 2a — N+1 Query Detection

```
For each API route and lib file:
□ Search for: for(...) { await supabase } or forEach with DB calls inside
□ Search for: .map(item => await supabase...) — array iteration with individual queries
□ Search for: for (const school of schools) { await } — per-item queries in a loop
□ Identify: any place where a list of IDs is available but individual queries are made
□ For each N+1 found: what .in() query would replace it?

Hotspots to check first:
- src/app/api/students/plan/playbook-data/route.ts (assembles many school records)
- src/lib/llm/coach-context.ts (builds context from multiple student tables)
- src/app/api/family/dashboard/route.ts (loads multiple student profiles)
```

**Severity:** N+1 in plan generation or coach = P1 (directly degrades core UX). N+1 in admin = P2.

---

### 2b — Sequential Await Detection

```
For each API route handler:
□ Find all independent await calls (not using data from previous await)
□ Check: are they wrapped in Promise.all() or sequential?
□ Sequential is OK when: call B uses data from call A's result
□ Sequential is WRONG when: both calls could start simultaneously

Pattern to find:
  const a = await x();
  const b = await y();  ← is b independent of a? If yes, this is sequential bug.

Check specifically:
- Routes that call multiple student tables (profile + schools + activities)
- Playbook generation (parallel data fetching before LLM call)
- Family dashboard (loading N student profiles)
```

**Severity:** Sequential independent awaits on main user journey = P1. In background jobs = P2.

---

### 2c — Unbounded Query Detection

```
For every .select() call in src/:
□ Does the query have .limit(N)?
□ Does the query have .range(from, to)?
□ If no limit: how many rows could this realistically return? (100? 10,000?)
□ For school queries: schools table has 4,046 rows — any school query without limit is dangerous
□ For student-scoped queries: bounded by student_id, but still needs limit for activity lists

Acceptable no-limit cases:
- Queries scoped to a single student_id returning a single row (.single())
- Admin queries intentionally paginated at the application layer
- Migration scripts and seed files

Unacceptable:
- Any query on schools, documents, or coach_conversations without limit
```

**Severity:** Unbounded query on large tables = P1. Unbounded on student-scoped small tables = P2.

---

### 2d — SELECT * Detection

```
For every .select('*') in src/app/api/ and src/lib/:
□ Is this in a production route handler? (P1 if yes)
□ What columns are actually used from the result?
□ Are there large text fields being pulled unnecessarily?
   (brag_sheet, essay_drafts, coach conversation bodies)
□ Would a column list reduce network payload by >50%?

Allowed .select('*') locations:
- __tests__ files
- scripts/ directory
- supabase/seed/ directory

Never allowed:
- Production API routes
- LLM context builders (pulls unnecessary PII into prompts)
```

**Severity:** `select('*')` in production routes pulling large text fields = P1. Others = P2.

---

### 2e — Missing Cache Pattern

```
For every LLM generator file:
□ Is there a DB check for an existing cached result before the LLM call?
□ Does the cache check happen before any expensive computation?
□ Is ?force=true supported to bypass cache when needed?
□ Is the cache write synchronous (await), not fire-and-forget?

For every calculation that's deterministic per student:
□ Financial fit scores — cached per student+school?
□ Strategic identity — cached per student?
□ Action plan — cached with TTL or until profile changes?
□ School fit scores — recomputed on demand or cached?

For API routes:
□ Does the route check the cache before calling the generator?
□ Does it return cached: true in the response for cache hits?
```

**Severity:** Missing cache on LLM generator = P1. Missing cache on financial calc = P2.

---

### 2f — React Re-render Audit

```
For each React component that receives objects or arrays as props:
□ Are object/array props stable (useMemo, useCallback, defined outside component)?
□ Are context values wrapped in useMemo to prevent whole-tree re-renders?
□ Does any context provider re-render on every keystroke (controlled inputs)?
□ Are list items rendered with stable key= props (not array index)?
□ Are expensive child components wrapped in React.memo?

Context providers to check:
- CoachProvider — wraps the entire authenticated app
- Any provider that stores arrays or objects in state

Hotspots:
- School list: re-renders on filter change (expected) vs on every scroll (bug)
- Plan page: re-renders when unrelated tab is selected
- Coach widget: re-renders all messages on each new message
```

**Severity:** Context provider re-rendering entire app on input = P1. Individual component re-render trap = P2.

---

### 2g — LLM Cost Efficiency

```
For every LLM call:
□ Is MODELS.HAIKU used for extraction/classification tasks (not MODELS.SONNET)?
□ Is MODELS.SONNET used for strategy/coaching tasks (not MODELS.HAIKU)?
□ Are batch operations using a single LLM call (not N calls for N items)?
   (e.g., format 10 activities in one call, not 10 separate calls)
□ Is the system prompt minimal for the task (not copy-pasted boilerplate)?
□ Are prompts including only the student data needed for THIS specific call?

For playbook generation specifically:
□ Are all LLM calls for one student's playbook batched/parallelized?
□ Could any two LLM operations be merged into one call without quality loss?
□ Is there a cost ceiling per student per day (checkSpendingCap)?
```

**Severity:** Wrong model for task = P2. Missing spending cap = P1 (see /prompt-auditor). N separate calls where 1 batch works = P2.

---

### 2h — Database Index Coverage

```
For the most common query patterns:
□ Is there an index on student_id for every frequently-queried table?
□ Is there an index on school_id + student_id for school-specific student data?
□ Are composite indexes used for multi-column WHERE clauses?
□ Are there indexes on columns used in ORDER BY on large tables?

Tables most likely to need index review:
- student_activities (queried by student_id in every plan view)
- school_list_items (queried by student_id + fit_category)
- coach_conversations (queried by student_id + created_at)
- strategic_playbooks (queried by student_id for cache checks)
- llm_usage_logs (queried by student_id + operation_type for cost checks)

Note: RLS policies filter by student_id — PostgREST uses the index for this.
Check: does the RLS policy column match the index column exactly?
```

**Severity:** Missing index on student_id in high-frequency table = P1. Missing composite index = P2.

---

### 2i — Serverless Cold Start Patterns

```
the project runs on Vercel serverless. Cold start behavior matters:

□ Are heavy imports (exceljs, pdf libraries) in routes that are called frequently?
  (If yes: move to dynamic import or background job)
□ Are SDK clients initialized at module level (acceptable) vs inside handlers (wasteful)?
□ Do routes with maxDuration: 60+ have fallback timeouts?
□ Are there synchronous I/O operations at module load time?

Dynamic import pattern (for heavy libraries):
  // ✅ CORRECT — only loaded when needed
  const ExcelJS = await import('exceljs');

  // ❌ WRONG — loaded on every cold start even if route not called
  import ExcelJS from 'exceljs';  // top of file in heavy route

Check specifically:
- Plan export route (uses exceljs/pdfmake)
- Document extraction route (uses pdf parsing)
- Admin routes (heavy, infrequent — cold start acceptable)
```

**Severity:** Heavy sync import in high-frequency route = P1. In low-frequency admin route = P2.

---

## Phase 3: Scoring

| Status | Meaning |
|--------|---------|
| ✅ Pass | No performance issue found |
| ⚠️ Warning | Minor inefficiency, low real-world impact |
| ❌ Fail — P1 | Performance issue on main user journey |
| 🔴 Fail — P0 | Query or operation that would fail at scale (timeout, OOM) |

---

## Common Failure Patterns

| Pattern | Symptom | Severity | Check |
|---------|---------|----------|-------|
| N+1 in playbook assembly | Plan page takes 8s to load for students with 10 schools | P1 | 2a |
| Sequential awaits in coach route | Coach response takes 3× longer than necessary | P1 | 2b |
| `SELECT *` on school_financial_data | Network payload 10× larger than needed | P1 | 2d |
| Missing cache on strategic_identity | $0.12 LLM call on every plan page load | P1 | 2e |
| Unbounded school query | Works for 50 schools, times out for full 4,046 | P1 | 2c |
| CoachProvider re-renders on keystroke | All chat messages re-rendered on every character typed | P1 | 2f |
| Sonnet for activity extraction | 10× cost for tasks Haiku handles equally well | P2 | 2g |
| Missing student_id index | Full table scan on school_list_items for every plan view | P1 | 2h |
| Synchronous exceljs import | 400ms cold start penalty on every API request | P1 | 2i |
| N separate LLM calls for N activities | Brag sheet generation takes 30s instead of 3s | P2 | 2g |

---

## Output Format

```
## Performance Auditor: /performance-auditor [mode] [target]

### Mode
[audit | validate | queries | frontend | llm]

### Files Audited
[N route files, N lib files, N component files]

### Findings
| File | Check | Status | Issue |
|------|-------|--------|-------|
| src/app/api/students/plan/playbook-data/route.ts | N+1 queries | ❌ P1 | Per-school financial query in loop |
| src/lib/llm/brag-sheet-generator.ts | Cache pattern | ✅ Pass | — |
| src/components/coach/CoachProvider.tsx | Re-render | ⚠️ Warning | Context value not memoized |

### Issues Found
| Severity | File | Check | Description | Fix |
|----------|------|-------|-------------|-----|
| P1 | playbook-data/route.ts | N+1 | school_financial_data queried per school in loop | Replace with .in(schoolIds) batch query |
| P2 | CoachProvider.tsx | Re-render | messages array causes all consumers to re-render | Wrap context value in useMemo |

### Summary
✅ [N] checks pass · ❌ [N] issues found · [N] filed as GitHub issues
Estimated latency improvement: [Xms per plan load if P1s fixed]
LLM cost impact: [$X/day if P2s fixed]
```

---

## When to Escalate

Stop and ask if:
- An N+1 fix requires a database view or materialized query (architectural decision)
- A missing index requires a migration on a large production table (downtime risk)
- Parallelizing calls changes the error handling semantics in a way that needs product input
- LLM batching would change output quality (need to test before shipping)
- React re-render fix requires a major component tree restructure

---

## Key References

- `src/app/api/students/plan/playbook-data/route.ts` — Most complex data assembly route
- `src/lib/llm/coach-context.ts` — Context builder (N+1 risk, data minimization)
- `src/lib/llm/strategic-identity.ts` — Reference implementation for cache-first pattern
- `src/components/coach/` — Coach UI (re-render risk)
- `src/lib/plan/financial-fit.ts` — Financial calculations (caching and batching)
- `supabase/migrations/` — Index definitions live here
- PATTERNS.md §5 — LLM Cost Telemetry
- `/prompt-auditor` — Overlapping LLM cost checks (model selection, batch calls)
