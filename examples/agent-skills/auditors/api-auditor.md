> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /api-auditor Skill

A standalone API route audit skill for the project. Use this whenever you are adding new routes, reviewing a pull request, or debugging API failures — to catch missing auth, unvalidated input, inconsistent response shapes, missing LLM telemetry, and broken parent-access patterns before they reach production.

The the project API has 60+ routes across students, coach, family, and admin areas. Many were written at different stages and use slightly different patterns. This skill exists to detect the gaps that cause real HTTP 4xx/5xx failures in E2E runs.

## Agent Chain

```
read-patterns → audit-checks → fix-or-report → document
```

## Usage

```
/api-auditor audit              — Full audit of all routes in src/app/api/
/api-auditor validate [file]   — Audit a specific route file
/api-auditor fix [issue]       — Diagnose and fix a specific API route bug
/api-auditor new [route-file]  — Pre-flight check before adding a new route
```

---

## the project API Fundamentals

Read these before doing anything. Every recurring API bug traces back to one of these.

### Rule 1 — Auth: Two Patterns, One Must Be Present

**Preferred (wrapper-based):** 30+ routes use `withStudentAuth`, `withOptionalStudentAuth`, or `withAuth` from `src/lib/api/with-auth.ts`. These inject `user`, `studentProfile`, and `supabase` automatically.

```typescript
// ✅ PREFERRED — wrapper handles auth, profile fetch, and error response
export const GET = withStudentAuth(
  async (req, user, studentProfile, supabase) => {
    // user and studentProfile are guaranteed non-null here
    return NextResponse.json({ success: true, data: { ... } });
  },
  { route: '/api/students/activities', method: 'GET' }
);
```

**Acceptable (manual inline):** Older routes do the auth check inline.

```typescript
// ✅ ACCEPTABLE — manual check, must be the first thing in the handler
const supabase = await createRouteHandlerClient();
const { data: { user }, error: authError } = await supabase.auth.getUser();
if (authError || !user) {
  return ApiErrors.unauthorized();
}
```

**Never acceptable:**
```typescript
// ❌ WRONG — no auth check at all
export async function GET() {
  const supabase = await createRouteHandlerClient();
  const { data } = await supabase.from('student_profiles').select('*');
  return NextResponse.json({ data });
}
```

A route with no auth check is an IDOR vulnerability. Flag it as P0.

---

### Rule 2 — Error Responses Must Use ApiErrors

`ApiErrors` lives in `src/lib/api/errors.ts`. Every error response should use it.

```typescript
// ✅ CORRECT
return ApiErrors.unauthorized();
return ApiErrors.forbidden('You do not have access to this student');
return ApiErrors.notFound('Student profile not found');
return ApiErrors.badRequest('school_id is required');
return ApiErrors.validation('Invalid activity data', validationResult.error.issues);
return ApiErrors.rateLimited(spendingCap.message);
return ApiErrors.internal('Failed to generate strategies');

// ❌ WRONG — raw NextResponse instead of ApiErrors helper
return NextResponse.json({ error: 'Not found' }, { status: 404 });
return NextResponse.json({ success: false, message: 'Bad request' }, { status: 400 });
```

Error shape: `{ success: false, error: { code: string, message: string, details?: unknown } }`

---

### Rule 3 — Success Responses Have a Consistent Envelope

```typescript
// ✅ CORRECT — 200 read/update
NextResponse.json({ success: true, data: { ... } })

// ✅ CORRECT — 201 create
NextResponse.json({ success: true, data: createdObject }, { status: 201 })

// ✅ CORRECT — with optional metadata
NextResponse.json({ success: true, data: { ... }, message: '...', cached: true })

// ❌ WRONG — missing success flag
NextResponse.json({ activities: [...] })

// ❌ WRONG — data not nested under 'data' key
NextResponse.json({ success: true, activities: [...] })
```

---

### Rule 4 — Input Validation Uses safeParse, Not parse

```typescript
// ✅ CORRECT — safeParse returns {success, data, error} — never throws
const result = createActivitySchema.safeParse(body);
if (!result.success) {
  return ApiErrors.validation('Invalid activity data', result.error.issues);
}
const validated = result.data;

// ❌ WRONG — .parse() throws a ZodError that hits the catch block and returns a 500
const validated = createActivitySchema.parse(body);
```

Query params also need validation:
```typescript
// ✅ CORRECT
const { searchParams } = new URL(request.url);
const studentId = searchParams.get('studentId');
if (!studentId) return ApiErrors.badRequest('studentId is required');

// ❌ WRONG — uses raw query param without validation
const id = req.nextUrl.searchParams.get('id');  // could be null, used unchecked
```

---

### Rule 5 — Parent Routes Use targetStudentId, Not user.id

A parent's `user.id` is their own auth ID — it never matches a student's `student_id`. Parent routes must:
1. Get `studentId` from query params (accept both `studentId` and `student_id`)
2. Verify the parent has a `family_accounts` row
3. Verify an active `family_links` row links parent → student
4. Use `studentId` (the target) for all DB queries, never `user.id`

```typescript
// ✅ CORRECT — parent route DB query
.eq('student_id', studentId)      // studentId = target student's auth.users.id

// ❌ WRONG — parent route uses their own ID
.eq('student_id', user.id)        // user.id = parent's auth.users.id — wrong table entirely
```

The 3-step parent verification pattern lives in `src/app/api/family/student-plan/route.ts` — use it as the reference implementation.

---

### Rule 6 — LLM Routes Need Three Things

Every route that calls an LLM must have:

```typescript
// 1. maxDuration at the top of the file (60s for generation, 120s for coach)
export const maxDuration = 60;

// 2. checkSpendingCap before the LLM call
const spendingCap = await checkSpendingCap(user.id);
if (!spendingCap.allowed) return ApiErrors.rateLimited(spendingCap.message);

// 3. recordLLMTelemetry after the call (even in the catch block)
await recordLLMTelemetry({ userId: user.id, model, operationType, tokensIn, tokensOut, costUsd, durationMs });
```

Missing `maxDuration` → Vercel kills the function after 10s → HTTP 504 in production.
Missing `checkSpendingCap` → users can run up unlimited bills.
Missing `recordLLMTelemetry` → cost monitoring blind spots.

Valid `operationType` values: `coach_response`, `plan_generation`, `document_extraction`, `brag_sheet`, `executive_summary`, `strategy_one_pager`, `school_strategy`, `summer_planning`, `career_explorer`, `interest_explorer`, `interview_prep`, `essay_deep_review`, `demonstrated_interest`, `mock_interview`, `activity_tiers`, `testing_strategy`, `format_activities`, `red_team_critique`, `action_plan`, `program_quality_tier`, `other`

---

### Rule 7 — adminClient Is Only For Server-Side Edge Cases

`adminClient` bypasses RLS. It should only appear in:
- Server-side API routes where the inserting user doesn't satisfy the SELECT RLS of the newly inserted row (e.g., parent family_links invite)
- Admin-only routes with explicit role checks

```typescript
// ✅ CORRECT — adminClient in server route where RLS would block
import { createAdminClient } from '@/lib/supabase/admin';
const adminClient = createAdminClient();
await adminClient.from('family_links').insert({ ... });

// ❌ WRONG — adminClient in client component
// ❌ WRONG — adminClient used to bypass RLS for regular student data
```

---

### Rule 8 — try/catch Wraps the Entire Handler

Every handler must have a top-level try/catch that:
1. Calls `logError()` with the route/method context
2. Does NOT expose internal error details to the client
3. Returns `ApiErrors.internal('...')` — never the raw error message

```typescript
} catch (error) {
  logError('Error in student profile update', error, {
    route: '/api/students/profile',
    method: 'PUT',
  });
  return ApiErrors.internal('Failed to update profile');
}
```

---

## Phase 1: Read Route File(s)

Before auditing, establish scope:

```
For /api-auditor audit:
1. Run: find src/app/api -name "route.ts" | sort
2. Read src/lib/api/errors.ts  (ApiErrors methods)
3. Read src/lib/api/with-auth.ts  (wrapper patterns)
4. Group routes by area: students/ | coach/ | family/ | admin/ | other

For /api-auditor validate [file]:
1. Read the specific route file
2. Read the Zod schema file it imports (if any)
3. If it calls an LLM: read the generator/module it calls to understand cost
```

---

## Phase 2: Audit Checks

Run these checks for every route (or the specific file for `validate`).

### 2a — Auth Completeness

```
For each HTTP method handler (GET, POST, PUT, PATCH, DELETE):
□ Is there a getUser() call OR a withStudentAuth/withAuth wrapper?
□ Is the auth error/null-user case handled and returns 401?
□ For admin routes: is there a role check after auth (user.role === 'admin')?
□ For parent routes: is there a 3-step parent verification?
□ Does auth happen BEFORE any DB queries or business logic?
```

**Severity:** Missing auth = P0 (IDOR vulnerability).

---

### 2b — Input Validation

```
For each POST/PUT/PATCH handler:
□ Is there a Zod schema for the request body?
□ Does it use .safeParse() (not .parse())?
□ Is the validation error returned as ApiErrors.validation() or ApiErrors.badRequest()?
□ Are required query params checked for null/missing?
□ Is the JSON body parsed in a try/catch (req.json() can throw on malformed JSON)?
```

**Severity:** Missing validation on write endpoints = P1 (data integrity risk).

---

### 2c — Response Shape Consistency

```
For each handler:
□ Success responses: { success: true, data: { ... } } ?
□ Creates return 201 status?
□ Error responses use ApiErrors.* helpers?
□ No raw NextResponse.json({ error: '...' }) on non-test routes?
□ No naked data outside the data envelope (e.g., { activities: [...] } instead of { data: { activities: [...] } })?
```

**Severity:** Shape mismatch = P1 (frontend silently reads wrong key → appears broken).

---

### 2d — Student ID Scoping

```
For each DB query in student-facing routes:
□ student_id queries use user.id (from auth), never studentProfile.id or profile.id?
□ For parent routes: student_id queries use targetStudentId, never user.id?
□ Result set is scoped to one student (no unbounded queries returning all students' data)?
```

**Severity:** Wrong ID source = P0 for parent routes (data cross-contamination), P1 for student routes.

---

### 2e — LLM Route Requirements

```
For each route that imports from @/lib/llm/ or calls a generator function:
□ export const maxDuration = 60 (or 120) at top of file?
□ checkSpendingCap() called before LLM invocation?
□ recordLLMTelemetry() called after LLM invocation?
□ recordLLMTelemetry() also called in the catch block (error telemetry)?
□ operationType is a valid value from the known list?
□ userId passed to recordLLMTelemetry (not undefined, unless auth genuinely unavailable)?
```

**Severity:** Missing maxDuration = P1 (504s in production). Missing telemetry = P2 (cost blind spot).

---

### 2f — Error Handling

```
For each handler:
□ Is there a top-level try/catch wrapping all async operations?
□ Does the catch block call logError() with route and method context?
□ Does the catch block return ApiErrors.internal() — not the raw error message?
□ Does the catch block NOT expose stack traces or internal details to the client?
□ Are Supabase errors checked (error from .select(), .insert(), etc.) before using data?
```

**Severity:** Missing try/catch = P1 (unhandled rejections crash the route). Exposing error details = P2 (information disclosure).

---

### 2g — Parent Route Pattern

```
For routes in /api/family/* or /api/students/parent-actions/*:
□ Gets studentId from query params (not hardcoded, not from user.id)?
□ Verifies family_accounts row exists for this parent?
□ Verifies active family_links row linking parent → student?
□ Optionally checks data_permissions for privacy-sensitive fields?
□ All DB queries for student data use studentId, not user.id?
□ Uses adminClient if inserting rows where RLS would block the read-back?
```

**Severity:** All parent route violations = P0 (data security).

---

### 2h — CRUD Completeness

```
For each resource (e.g., /api/students/activities):
□ If POST exists: is there a GET to read back the created resource?
□ If GET + POST exist: is there a PUT/PATCH for updates?
□ If GET + POST + PUT exist: is there a DELETE?
□ For [id] routes: do the GET/PUT/DELETE all use the same ID param name?
□ Is there a list endpoint (GET /resource) AND an individual endpoint (GET /resource/[id])?
```

**Note:** Missing DELETE is P2 — data accumulates and can't be cleaned up. Missing GET after POST is P1 — user can't see what they created.

---

### 2i — HTTP Method Correctness

```
For each route:
□ GET handlers do NOT modify data (no INSERT, UPDATE, DELETE)?
□ POST creates a new resource (not a mutation of an existing one)?
□ PUT replaces a resource; PATCH updates fields?
□ DELETE removes the resource?
□ No business logic in GET that has side effects?
```

**Severity:** GET with side effects = P2 (unexpected mutations from page refreshes/prefetching).

---

### 2j — adminClient Safety

```
For each route that imports createAdminClient():
□ Is the route server-side only (API route, not client component)?
□ Is there a documented reason why adminClient is needed (comment explaining the RLS bypass)?
□ Is adminClient NOT used for regular student data CRUD (where RLS should apply)?
```

**Severity:** adminClient misuse = P0 (RLS bypass exposes all users' data).

---

## Phase 3: Scoring & Prioritization

After running all checks, score each route:

| Status | Meaning |
|--------|---------|
| ✅ Pass | No issues found |
| ⚠️ Warning | Non-critical issue (style, missing optional enhancement) |
| ❌ Fail — P1/P2 | Real bug, should fix before next deploy |
| 🔴 Fail — P0 | Security or data integrity issue, fix immediately |

---

## Phase 4: Fix (for `/api-auditor fix [issue]`)

When fixing an issue:

1. Read the full route file first — never fix in isolation
2. Fix the root cause, not just the symptom
3. Run `npx tsc --noEmit` after every fix — 0 errors required
4. Run `npx vitest run` — all tests must pass
5. For new auth checks: add a regression test verifying the 401 is returned
6. Close the GitHub issue with a comment referencing the fix commit

---

## Phase 5: Document

After any fix or full audit:

- If new routes were added: verify they match all patterns above before marking done
- If a recurring violation class was found (e.g., "all plan routes missing maxDuration"): file one GitHub issue covering the whole class, not one per route
- Update `memory/MEMORY.md` if a new API pattern was discovered or confirmed

---

## Common Failure Patterns (Recurring Bugs)

| Pattern | Symptom | Severity | Check |
|---------|---------|----------|-------|
| No auth check | Any user can read/write any student's data | P0 | 2a |
| Parent uses user.id for student queries | Parent sees own data (empty) or wrong student's data | P0 | 2d, 2g |
| Missing maxDuration on LLM route | HTTP 504 in production, works fine locally | P1 | 2e |
| `.parse()` instead of `.safeParse()` | ZodError thrown → caught by try/catch → returns 500 instead of 400 | P1 | 2b |
| Missing Zod schema on POST body | Arbitrary data written to DB | P1 | 2b |
| Raw NextResponse error (not ApiErrors) | Frontend error handling breaks (different shape) | P1 | 2c |
| Data outside `data` envelope | `response.data.activities` → `undefined` because it's `response.activities` | P1 | 2c |
| Missing spending cap on LLM route | Unlimited API bill possible | P2 | 2e |
| Missing recordLLMTelemetry | Cost tracking blind spot | P2 | 2e |
| No try/catch | Uncaught rejection → Vercel 500 with no context | P1 | 2f |
| GET with side effects | Data mutated on page prefetch/refresh | P2 | 2i |

---

## Output Format

Every `/api-auditor` invocation must produce this summary:

```
## API Auditor: /api-auditor [mode] [target]

### Mode
[audit | validate | fix | new]

### Routes Audited
[N routes across N areas]

### Findings
| Route | Method | Check | Status | Issue |
|-------|--------|-------|--------|-------|
| /api/students/activities | GET | Auth | ✅ Pass | — |
| /api/family/join | POST | Auth | 🔴 P0 | No parent verification step |
| /api/students/plan/brag-sheet | POST | LLM reqs | ❌ P1 | Missing maxDuration |

### Issues Found
| Severity | Route | Check | Description | Fix |
|----------|-------|-------|-------------|-----|
| P0 | /api/family/join | Auth | No 3-step parent verification | Add family_accounts + family_links check |
| P1 | /api/students/plan/brag-sheet | LLM | Missing maxDuration export | Add export const maxDuration = 60 |

### Changes Made
| File | Action |
|------|--------|
| src/app/api/students/plan/brag-sheet/route.ts | Added maxDuration |

### Open Questions
| Question | Impact |
|----------|--------|
| [question] | [what depends on the answer] |

### Summary
✅ [N] routes pass · ❌ [N] issues found · [N] fixed · [N] filed as GitHub issues
```

---

## When to Escalate

Stop and ask the user if:
- A missing auth check is on a route that handles payments or PII
- An adminClient misuse would require restructuring the whole route's logic
- Fixing a response shape mismatch would break existing frontend code that's already deployed
- A missing endpoint would require a new DB table or migration

---

## Key References

- `src/lib/api/errors.ts` — ApiErrors helper methods
- `src/lib/api/with-auth.ts` — Auth wrapper patterns (withStudentAuth, withAuth)
- `src/lib/supabase/server.ts` — createRouteHandlerClient()
- `src/lib/supabase/admin.ts` — createAdminClient() (RLS bypass — handle with care)
- `src/lib/llm/spending-caps.ts` — checkSpendingCap()
- `src/lib/llm/telemetry.ts` — recordLLMTelemetry()
- `src/lib/logging.ts` — logError()
- `PATTERNS.md` — Security and coding patterns (§1 Privacy, §3 Coach Guardrails)
- `src/app/api/family/student-plan/route.ts` — Reference implementation for parent route pattern
- `src/app/api/students/strategies/batch/route.ts` — Reference implementation for LLM route pattern
