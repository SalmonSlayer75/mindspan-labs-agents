> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /frontend-auditor Skill

A standalone frontend audit skill for the project. Use this whenever adding new pages/components, reviewing a pull request, or debugging silent UI failures — to catch broken API response consumption, missing loading/error states, AbortController leaks, and insecure parent-route patterns before they reach production.

## Usage

```
/frontend-auditor audit              — Full audit of all pages and components in src/app/(app)/ and src/components/
/frontend-auditor validate [file]   — Audit a specific page or component file
/frontend-auditor fix [issue]       — Diagnose and fix a specific frontend bug
/frontend-auditor new [component]   — Pre-flight check before adding a new data-fetching component
```

---

## the project Frontend Fundamentals

Read these before doing anything. Every recurring frontend bug traces back to one of these.

### Rule 1 — API Response Consumption: Always Use the Standard Envelope

Every API response follows `{ success: boolean, data?: T, error?: { code: string, message: string } }`.

```typescript
// ✅ CORRECT — check success flag, read from data key
const result = await response.json();
if (!response.ok || !result.success) {
  throw new Error(result.error?.message || 'Failed to load');
}
const activities = result.data.activities;  // nested under data

// ❌ WRONG — skips success check, reads from wrong key
const result = await response.json();
const activities = result.activities;  // undefined — data is at result.data.activities

// ❌ WRONG — reads error as string (old format)
throw new Error(result.error || 'Failed');  // result.error is { code, message }, not a string
```

**Exception routes** (use flat response shape, not `data` envelope):
- `GET /api/students/strategies/batch` → `{ success, strategies, summary }` (not `data.strategies`)
- `POST /api/students/strategies/batch` → same
- `POST /api/students/documents/upload` → `{ success, document, extraction, error?: string }` (error is a flat string here)

These exceptions are documented. If a route is not in this list, it uses the standard envelope.

**Error code handling** — check specific codes for targeted responses:

```typescript
// ✅ CORRECT — handle specific error codes
if (!response.ok || !result.success) {
  if (result.error?.code === 'UNAUTHORIZED') {
    router.push('/login');
    return;
  }
  if (response.status === 403) {
    setError('You do not have access to this data.');
    return;
  }
  throw new Error(result.error?.message || 'Failed');
}

// ❌ WRONG — ignores error codes, generic handler for everything
if (!response.ok) {
  setError('Something went wrong');
}
```

Valid error codes: `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `VALIDATION_ERROR`, `RATE_LIMITED`, `INTERNAL_ERROR`

---

### Rule 2 — useEffect Fetches Require AbortController

Every `useEffect` that calls `fetch` must use an AbortController. Without it:
- Stale responses update state after the component unmounts (React warning)
- Rapid navigation can cause race conditions where old responses overwrite newer ones

```typescript
// ✅ CORRECT — AbortController + cleanup + abort guard
useEffect(() => {
  const controller = new AbortController();

  const fetchData = async () => {
    try {
      const response = await fetch('/api/...', { signal: controller.signal });
      const result = await response.json();
      if (!response.ok || !result.success) {
        throw new Error(result.error?.message || 'Failed to load');
      }
      if (!controller.signal.aborted) {  // guard: don't setState if unmounted
        setData(result.data);
      }
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') return;  // normal cleanup
      if (!controller.signal.aborted) {
        setError(err instanceof Error ? err.message : 'Error loading data');
      }
    } finally {
      if (!controller.signal.aborted) {
        setIsLoading(false);
      }
    }
  };

  fetchData();
  return () => controller.abort();  // cleanup
}, [dependency]);

// ❌ WRONG — no AbortController
useEffect(() => {
  fetch('/api/...')
    .then(r => r.json())
    .then(data => setData(data));
}, []);

// ❌ WRONG — AbortController created but signal not passed to fetch
useEffect(() => {
  const controller = new AbortController();
  fetch('/api/...')  // missing { signal: controller.signal }
    .then(r => r.json())
    .then(data => setData(data));
  return () => controller.abort();
}, []);
```

---

### Rule 3 — Every Data-Fetching Component Needs Three States

Components that fetch data must handle: loading, error, and success. Missing any state produces blank UI or crashes.

```typescript
// ✅ CORRECT — all three states declared and rendered
const [data, setData] = useState<DataType | null>(null);
const [isLoading, setIsLoading] = useState(true);
const [error, setError] = useState<string | null>(null);

// In render:
if (isLoading) return <ComponentSkeleton />;
if (error) return <ErrorAlert message={error} />;
if (!data) return null;  // or a "no data" empty state

// ❌ WRONG — no loading state
const [data, setData] = useState<DataType | null>(null);
// Renders null/empty on first paint, no user feedback

// ❌ WRONG — no error state
const [data, setData] = useState<DataType | null>(null);
const [isLoading, setIsLoading] = useState(true);
// Silently shows blank UI on API failure
```

**Loading UI standard:**
- Full-page / section loads: `<Skeleton className="h-N w-N" />` from `@/components/ui/skeleton`
- Button/action in progress: `<Loader2 className="h-4 w-4 animate-spin" />` from `lucide-react`
- Disable the triggering button while action is in progress

**Error UI standard:**
- Display `error` message with an `<Alert variant="destructive">` or toast
- Provide a retry button where possible (call the fetch function again)

---

### Rule 4 — Async Actions Need In-Progress State

Buttons that trigger API calls (save, delete, resend, generate) must track in-progress state to prevent double-submits and provide feedback.

```typescript
// ✅ CORRECT — per-action progress state
const [actionInProgress, setActionInProgress] = useState<string | null>(null);

const handleDelete = async (id: string) => {
  setActionInProgress(id);
  try {
    const response = await fetch(`/api/.../${id}`, { method: 'DELETE' });
    if (!response.ok) throw new Error('Failed to delete');
    setItems(prev => prev.filter(item => item.id !== id));
    toast({ title: 'Deleted successfully' });
  } catch (error) {
    toast({ variant: 'destructive', title: 'Delete failed', description: error instanceof Error ? error.message : 'Unknown error' });
  } finally {
    setActionInProgress(null);
  }
};

<Button
  onClick={() => handleDelete(item.id)}
  disabled={actionInProgress === item.id}
>
  {actionInProgress === item.id
    ? <Loader2 className="h-4 w-4 animate-spin" />
    : <Trash2 className="h-4 w-4" />}
</Button>

// ❌ WRONG — no in-progress state
const handleDelete = async (id: string) => {
  await fetch(`/api/.../${id}`, { method: 'DELETE' });
};

<Button onClick={() => handleDelete(item.id)}>Delete</Button>
// User can click multiple times, no feedback during operation
```

---

### Rule 5 — Forms Use React Hook Form + Zod

All forms must use RHF + zodResolver. Never validate manually or call `.parse()` on form data.

```typescript
// ✅ CORRECT — RHF + Zod + FormMessage
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const form = useForm<FormInput>({
  resolver: zodResolver(formSchema),
  defaultValues: { ... },
});

const onSubmit = async (data: FormInput) => {
  // data is already Zod-validated by RHF
  setIsSaving(true);
  try {
    const response = await fetch('/api/...', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!response.ok) {
      const result = await response.json();
      throw new Error(result.error?.message || 'Save failed');
    }
    toast({ title: 'Saved' });
    onSuccess?.();
  } catch (error) {
    toast({ variant: 'destructive', title: 'Error', description: error instanceof Error ? error.message : 'Save failed' });
  } finally {
    setIsSaving(false);
  }
};

<Button type="submit" disabled={isSaving}>
  {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
  Save
</Button>

// ❌ WRONG — manual validation
const handleSubmit = (e: React.FormEvent) => {
  e.preventDefault();
  if (!name) { setError('Name is required'); return; }
  // ...
};

// ❌ WRONG — no submit button disabled state
<Button type="submit">Save</Button>  // Can double-submit
```

---

### Rule 6 — Parent Routes Use studentId from URL Params

Parent-facing pages get the target student ID from the URL. Never derive it from auth state (`user.id`) — that's the parent's own ID.

```typescript
// ✅ CORRECT — studentId from URL param, passed to API
const params = useParams();
const studentId = params.studentId as string;

const response = await fetch(`/api/family/student-plan?studentId=${studentId}`);

// ✅ CORRECT — handle 403 explicitly
if (response.status === 403) {
  setError('You do not have access to this student\'s data.');
  return;
}

// ❌ WRONG — uses auth user.id as studentId in parent page
const { user } = useAuth();
const response = await fetch(`/api/family/student-plan?studentId=${user.id}`);
// user.id is the PARENT's ID — will return empty or 403

// ❌ WRONG — no 403 handling on parent routes
if (!response.ok) {
  setError('Failed to load');  // Swallows the real access-denied error
}
```

---

### Rule 7 — Permissions Are Gated in the API, Displayed in the UI

Permission-sensitive sections (essays, financials) receive an explicit boolean from the API (`canViewEssays`, `canViewFinancialData`). The UI renders a locked placeholder, not an error.

```typescript
// ✅ CORRECT — show locked UI for unavailable permission
{data.permissions.canViewFinancialData ? (
  <FinancialSection data={data.financials} />
) : (
  <Card className="border-dashed">
    <CardContent className="text-center text-muted-foreground">
      Financial details are private. Your student can share this from their settings.
    </CardContent>
  </Card>
)}

// ❌ WRONG — crash if permission not granted
<FinancialSection data={data.financials} />  // financials is undefined when not permitted
```

---

### Rule 8 — useCallback for Fetch Functions in useEffect Deps

Fetch functions used in `useEffect` dependencies must be wrapped in `useCallback` to prevent infinite re-render loops.

```typescript
// ✅ CORRECT — useCallback prevents re-render loop
const fetchData = useCallback(async (signal?: AbortSignal) => {
  // fetch logic
}, [studentId, router]);  // deps are stable primitives

useEffect(() => {
  const controller = new AbortController();
  fetchData(controller.signal);
  return () => controller.abort();
}, [fetchData]);  // stable because of useCallback

// ❌ WRONG — inline function recreated on every render
useEffect(() => {
  const fetchData = async () => { /* ... */ };
  fetchData();
}, [someState]);  // causes infinite loop if fetchData is in dep array
```

---

## Phase 1: Read Component File(s)

Before auditing, establish scope:

```
For /frontend-auditor audit:
1. Run: find src/app/(app) src/components -name "*.tsx" | grep -v __tests__ | sort
2. Group by type:
   - Pages: src/app/(app)/**/*.tsx
   - Feature components: src/components/[feature]/*.tsx
   - UI primitives: src/components/ui/*.tsx (SKIP — not data-fetching)
   - Forms: src/components/forms/*.tsx
   - Hooks: src/hooks/*.ts

For /frontend-auditor validate [file]:
1. Read the specific file
2. Identify: does this component fetch data? (look for fetch(), useEffect, useState for data)
3. If yes: apply all 8 rules
4. If no (display-only): skip Rules 1-4, check Rules 6-8 if parent-facing
```

**What to skip:**
- `src/components/ui/` — shadcn primitives, no data fetching
- `src/app/(app)/layout.tsx` — layout files, auth handled by middleware
- Server components that use `async/await` directly (no useEffect pattern needed)

---

## Phase 2: Audit Checks

Run these checks for every data-fetching component.

### 2a — API Response Consumption

```
For each fetch() call in the component:
□ Does it call response.json() and check result.success?
□ Does it check !response.ok || !result.success?
□ Does it read data from result.data.X (not result.X)?
□ Does it read error messages from result.error?.message (not result.error)?
□ For UNAUTHORIZED (401): does it redirect to /login?
□ For parent routes (403): does it show an access-denied message (not a generic error)?
□ Exception routes (strategies/batch, documents/upload): are they consuming the flat shape correctly?
```

**Severity:** Wrong data key = P1 (feature silently returns `undefined`). Missing UNAUTHORIZED handler = P2 (user stuck on broken page).

---

### 2b — AbortController Completeness

```
For each useEffect that contains a fetch() call:
□ Is an AbortController created inside the effect?
□ Is { signal: controller.signal } passed to every fetch() call in the effect?
□ Is err.name === 'AbortError' checked before handling errors?
□ Is !controller.signal.aborted checked before every setState call?
□ Is () => controller.abort() returned from the effect?
```

**Severity:** Missing AbortController = P1 (React setState-after-unmount warning, potential race conditions). Missing signal guard on setState = P2.

---

### 2c — Loading/Error State Completeness

```
For each component that has useState for data (data-fetching indicator):
□ Is there an isLoading state initialized to true?
□ Is there an error state initialized to null?
□ Is isLoading set to false in a finally block (not just on success)?
□ Does the render return a skeleton/spinner when isLoading is true?
□ Does the render return an error display when error is non-null?
□ Is there a guard against rendering with null data after loading?
```

**Severity:** Missing loading state = P1 (blank flash on page load). Missing error state = P1 (silent failure, blank UI on API error).

---

### 2d — Async Action State

```
For each button/action that triggers an API call (not initial data load):
□ Is there an in-progress state variable (isSaving, isDeleting, actionInProgress)?
□ Is the button disabled while the action is in progress?
□ Is there a visual indicator (Loader2 spinner) while in progress?
□ Is the in-progress state reset in a finally block?
□ Does success show a toast with title?
□ Does failure show a toast with variant: 'destructive'?
```

**Severity:** Missing disabled state = P2 (double-submit risk). Missing toast feedback = P2 (user doesn't know if action succeeded).

---

### 2e — Form Pattern

```
For each <form> element or component that submits data:
□ Does it use useForm from react-hook-form?
□ Does it use zodResolver with a Zod schema?
□ Do all fields render <FormMessage /> for inline validation errors?
□ Is the submit button disabled while isSaving is true?
□ Does the submit button show a spinner while saving?
□ Does the onSubmit handler check response.ok and show error toast on failure?
□ Are sensitive fields (essays, test scores) not logged to console?
```

**Severity:** Missing RHF+Zod = P1 (no client-side validation, validation errors return 400 with no user feedback). Missing disabled submit = P2 (double-submit).

---

### 2f — Parent Route Safety

```
For components in src/app/(app)/parent/* or that accept a studentId prop:
□ Is studentId sourced from URL params (useParams()), not from auth/user state?
□ Is studentId validated as a non-empty string before use?
□ Is response.status === 403 handled explicitly (not swallowed in generic error)?
□ Are permission booleans from the API response used for gating, not derived client-side?
□ Do permission-gated sections show a locked placeholder (not crash) when permission is false?
```

**Severity:** Wrong studentId source = P0 (parent sees their own empty data or wrong student's data). Missing 403 handler = P1 (confusing error message).

---

### 2g — useCallback for Fetch Functions

```
For each function defined inside a component that is used in a useEffect dependency array:
□ Is the fetch function wrapped in useCallback?
□ Does the useCallback dependency array contain only stable values (primitives, other callbacks, refs)?
□ Are there any functions NOT wrapped in useCallback in useEffect dependency arrays?
   (This would cause infinite re-render loops)
```

**Severity:** Missing useCallback on dep = P1 (infinite render loop, component crashes or hammers API).

---

### 2h — TypeScript Safety

```
For each component:
□ Is the data state typed with a specific interface (not any or unknown)?
□ Are API response types explicitly defined (not inferred from json())?
□ Are optional chaining (?.) and nullish coalescing (??) used for nullable fields?
□ Is 'as' type assertion avoided on API response data (should be typed properly)?
```

**Severity:** Untyped API response = P2 (silent runtime errors when shape changes). Excessive type assertions = P2.

---

## Phase 3: Scoring & Prioritization

| Status | Meaning |
|--------|---------|
| ✅ Pass | No issues found |
| ⚠️ Warning | Non-critical (style, missing enhancement) |
| ❌ Fail — P1 | Real bug, fix before next deploy |
| 🔴 Fail — P0 | Security or data integrity issue, fix immediately |

---

## Phase 4: Fix (for `/frontend-auditor fix [issue]`)

When fixing an issue:

1. Read the full component file first — never fix in isolation
2. Fix the root cause, not just the symptom
3. Run `npx tsc --noEmit` after every fix — 0 errors required
4. Run `npx vitest run` — all tests must pass
5. Check dark mode variants are present on any UI added (pre-commit hook enforces this)
6. Close the GitHub issue with a comment referencing the fix commit

---

## Phase 5: Document

After any fix or full audit:
- If a new pattern was confirmed: update `memory/MEMORY.md`
- If a recurring violation was found (e.g. "all plan components missing AbortController"): file one GitHub issue covering the class, not one per component
- If a new exception route is discovered (flat response shape): add it to Rule 1's exception list in this file

---

## Common Failure Patterns (Recurring Bugs)

| Pattern | Symptom | Severity | Check |
|---------|---------|----------|-------|
| Reads `result.activities` not `result.data.activities` | Feature always shows empty, no error | P1 | 2a |
| Reads `result.error` as string | Error message is `[object Object]` in toast | P1 | 2a |
| No AbortController | React "Can't perform state update on unmounted component" warning | P1 | 2b |
| Missing signal guard on setState | Race condition on fast navigation | P2 | 2b |
| No isLoading state | Page flashes blank then loads, no skeleton | P1 | 2c |
| No error state | Blank UI on API failure, no user feedback | P1 | 2c |
| No disabled submit button | Double-submit on slow connection | P2 | 2d |
| No Loader2 on action button | User can't tell if click registered | P2 | 2d |
| Parent uses user.id as studentId | Parent sees empty data (their own ID has no student records) | P0 | 2f |
| No 403 handler on parent route | Generic "Failed to load" instead of "No access" message | P1 | 2f |
| Fetch function not in useCallback | Infinite render loop, hammers API | P1 | 2g |
| No AbortError check in catch | Triggers error state on normal navigation | P2 | 2b |

---

## Output Format

Every `/frontend-auditor` invocation must produce this summary:

```
## Frontend Auditor: /frontend-auditor [mode] [target]

### Mode
[audit | validate | fix | new]

### Files Audited
[N pages, N components, N hooks]

### Findings
| File | Check | Status | Issue |
|------|-------|--------|-------|
| app/(app)/dashboard/page.tsx | AbortController | ✅ Pass | — |
| components/plan/ActionPlan.tsx | Async action state | ❌ P1 | Generate button not disabled during generation |
| app/(app)/parent/plan/[studentId]/page.tsx | Parent safety | ✅ Pass | — |

### Issues Found
| Severity | File | Check | Description | Fix |
|----------|------|-------|-------------|-----|
| P1 | components/plan/ActionPlan.tsx | Async action | Generate button not disabled | Add isGenerating state, disable button |

### Changes Made
| File | Action |
|------|--------|
| src/components/plan/ActionPlan.tsx | Added isGenerating state + disabled button |

### Summary
✅ [N] files pass · ❌ [N] issues found · [N] fixed · [N] filed as GitHub issues
```

---

## When to Escalate

Stop and ask the user if:
- A response shape fix would require changing how multiple components read data (could be widespread)
- A parent route fix requires restructuring how studentId is passed through a component tree
- A missing permission gate would require a new API field to be returned
- Total fix scope exceeds 15 files

---

## Key References

- `src/app/(app)/dashboard/page.tsx` — Reference implementation for AbortController + loading/error states
- `src/app/(app)/parent/plan/[studentId]/page.tsx` — Reference implementation for parent route pattern
- `src/components/forms/ActivityForm.tsx` — Reference implementation for RHF + Zod form pattern
- `src/hooks/usePhasePlaybook.ts` — Reference implementation for custom data-fetching hook
- `src/components/ui/skeleton.tsx` — Skeleton component for loading states
- `PATTERNS.md` — Security patterns (§1 Privacy — no PII in console.log)
- `src/lib/api/errors.ts` — Error codes returned by the API
