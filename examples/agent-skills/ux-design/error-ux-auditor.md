# /error-ux-auditor Skill

A standalone error experience audit skill for the project. Use this to evaluate whether errors are **prevented, communicated clearly, and recoverable** — not just whether error states exist in the code.

`/frontend-auditor` checks that error states are declared and rendered (the code works).
This skill checks that the error **experience** is good (the user isn't frustrated).

## Usage

```
/error-ux-auditor audit              — Full error experience audit across all pages
/error-ux-auditor review [page]      — Audit error handling on a specific page
/error-ux-auditor catalog            — Build the complete error message catalog
```

---

## Error Experience Principles

Every error experience has four stages. Most products only handle stage 3. the project should handle all four.

### Stage 1 — Prevention: Stop Errors Before They Happen

The best error is one the user never sees.

```
✅ GOOD prevention:
  - Form validates as user types (not after submit)
  - File upload shows accepted formats BEFORE the user picks a file
  - "Add School" button disabled if school is already on list
  - GPA field restricts input to 0.0–4.0 range
  - Confirm dialog before destructive actions ("Remove from My Schools?")

❌ BAD — no prevention:
  - User uploads a .docx, gets "Unsupported format" error AFTER upload
  - User submits form, gets 5 validation errors at once
  - User can click "Delete" with no confirmation
  - User enters GPA "5.0" and gets a server error
```

### Stage 2 — Detection: Catch Errors Early and Specifically

When an error happens, identify WHAT went wrong with precision.

```
✅ GOOD detection:
  - "Your GPA must be between 0.0 and 4.0" (specific)
  - "We couldn't connect to the school database. Your internet connection may be down." (diagnosed)
  - "That email is already registered. Did you mean to log in instead?" (contextual)

❌ BAD detection:
  - "Invalid input" (what input? what's invalid?)
  - "Something went wrong" (what went wrong?)
  - "Error" (no information at all)
```

### Stage 3 — Communication: Tell Users What Happened and Why

Error messages must be human-readable, non-technical, and empathetic.

```
✅ GOOD communication:
  - Tone: conversational, not alarming ("Hmm, that didn't work. Let's try again.")
  - Content: what happened + why + what to do
  - Visual: appropriate severity (red for destructive, amber for recoverable)
  - Placement: near the thing that failed (inline, not just a toast)

❌ BAD communication:
  - Technical: "ECONNRESET", "500 Internal Server Error"
  - Alarming: "CRITICAL ERROR! DATA MAY BE LOST!"
  - Dismissive: "Error occurred" with no further detail
  - Misplaced: error about form field appears as a top-of-page banner
```

### Stage 4 — Recovery: Help Users Get Back on Track

After an error, users should know exactly what to do next.

```
✅ GOOD recovery:
  - "Try again" button that actually retries the failed action
  - Form preserves all user input after validation error (don't clear the form!)
  - "Go back to Schools" link when a school detail page fails to load
  - Auto-save draft when session expires (not data loss)
  - "Contact support" link for unrecoverable errors

❌ BAD recovery:
  - Error with no action button (user has to figure out what to do)
  - Form clears all input after a validation error
  - Back button goes to a different page than expected after error
  - Session expires and all unsaved work is lost
  - "Refresh the page" as the only suggestion
```

---

## Phase 1: Error Inventory

Build a complete catalog of all error scenarios.

### Step 1a — Code-Level Error Discovery

```
1. Find all error messages in the codebase:
   Grep: "toast\(" in src/ — all toast notifications
   Grep: "setError\(" in src/ — all error state updates
   Grep: "variant.*destructive" in src/ — destructive toasts
   Grep: "throw new Error" in src/app/ — thrown errors
   Grep: "<Alert" in src/ — alert components
   Grep: "FormMessage" in src/ — form validation messages
   Grep: "catch\s*\(" in src/app/(app)/ and src/components/ — all catch blocks

2. For each error message found, document:
   - File and line number
   - Error message text (what the user sees)
   - Trigger condition (what causes this error)
   - Recovery action available (retry button? link? nothing?)
   - Severity (does it block the user's task?)
```

### Step 1b — Scenario-Based Error Discovery

```
For each major feature, enumerate the error scenarios:

ONBOARDING:
□ Network failure during form save
□ Invalid data in form fields (GPA > 4.0, empty required fields)
□ Document upload fails (wrong format, too large, network error)
□ Session expires mid-onboarding
□ User navigates away and comes back (is progress saved?)

SCHOOLS:
□ School search returns no results
□ School detail page for deleted/invalid school
□ Adding a school that's already on the list
□ Compare page with < 2 schools selected
□ School data is stale/unavailable

PLAN:
□ Plan generation fails (LLM timeout, rate limit)
□ Plan PDF download fails
□ Plan data is incomplete (missing onboarding phases)
□ Plan sections show stale data

COACH:
□ Coach message fails to send
□ Coach response times out
□ Coach rate limit hit
□ Coach says something inappropriate (guardrail failure)

AUTHENTICATION:
□ Login with wrong password
□ Signup with existing email
□ Session expires
□ Password reset flow errors
□ Parent invitation link expired/invalid

DOCUMENTS:
□ Upload fails mid-transfer
□ Extraction fails (unreadable document)
□ File too large
□ Unsupported format
□ Storage quota exceeded
```

---

## Phase 2: Audit Checks

### 2a — Error Prevention

```
For each form in the product:
□ Does it validate inline as the user types? (not just on submit)
□ Are input constraints visible? (max length, accepted formats, valid ranges)
□ Are required fields marked? (asterisk, "Required" label, or aria-required)
□ Are destructive actions confirmed? (delete, remove, reset)
□ Are duplicate actions prevented? (add school already on list, submit twice)
□ Are file upload constraints shown before selection? ("PDF, PNG, JPG. Max 10MB.")

For each async operation:
□ Is the trigger button disabled during the operation? (prevent double-submit)
□ Is there a rate limit indicator if the user might hit it?
```

**Severity:** No inline validation on critical form = P2. Destructive action without confirmation = P1.

---

### 2b — Error Message Quality

```
For every error message found in Phase 1:

□ WHAT: Does it say what happened? (not just "Error")
□ WHY: Does it explain the likely cause? (network, invalid input, server issue)
□ HOW: Does it tell the user what to do? (retry, fix input, contact support)
□ TONE: Is it human and non-alarming? (no "CRITICAL", no technical jargon)
□ SPECIFIC: Is it specific to the error? (not a generic catch-all message)

Score each message:
- 5/5: All five criteria met
- 3-4/5: Missing one or two
- 1-2/5: Generic or technical (needs rewrite)
- 0/5: No message at all (silent failure)
```

**Severity:** Score 0-1 on user-facing error = P1. Score 2-3 = P2.

---

### 2c — Error Recovery Paths

```
For every error state:
□ Is there a recovery action? (retry button, link, suggestion)
□ Does retry actually work? (re-calls the failed function, doesn't just refresh)
□ Is user input preserved after error? (form data, selections, progress)
□ Is there an escape route? (back button, nav link, close dialog)
□ For unrecoverable errors: is there a fallback? (contact support, try later)

For session/auth errors:
□ Does session expiry save draft data?
□ Does re-login return the user to where they were?
□ Is the auth error message clear? ("Your session expired. Please log in again.")
```

**Severity:** Error with no recovery and data loss = P1. Error with no retry button = P2.

---

### 2d — Error Visibility & Placement

```
For every error display:
□ Is the error shown near the thing that failed? (not just a top-of-page banner)
□ For form errors: inline next to the field that failed?
□ For async errors: toast or alert in a visible location?
□ Is the error visually distinct? (red/destructive variant, icon)
□ Does the error persist until resolved? (not auto-dismiss too quickly)
□ For screen readers: is the error announced? (aria-live, role="alert")

Timing:
□ Does the error appear immediately? (not delayed)
□ For toasts: is the duration long enough to read? (≥ 5 seconds for errors)
□ For inline errors: do they appear as user types or on blur? (not only on submit)
```

**Severity:** Error message auto-dismisses before user can read = P1. Error not near the failed element = P2.

---

### 2e — Async Operation Feedback

```
For every operation that takes > 1 second:
□ Is there a loading indicator? (spinner, skeleton, progress bar)
□ Does the loading indicator have a label? ("Generating your plan..." not just a spinner)
□ For long operations (> 5s): is there a progress indication? (% complete, step X of Y)
□ Can the user cancel the operation? (especially for LLM generation)
□ If the operation fails: is the loading state cleared? (no stuck spinners)
□ If the operation succeeds: is there a success confirmation? (toast, visual change)

For operations that can be retried:
□ Is the retry button clearly visible after failure?
□ Does retry preserve any previously entered context?
□ Is there a limit on retries with appropriate messaging?
```

**Severity:** Stuck loading spinner after error = P1. No cancel for long operation = P2.

---

## Phase 3: Error Message Catalog

Produce a complete catalog for reference and consistency:

```markdown
# the project Error Message Catalog

## Network Errors
| Trigger | Message | Recovery | Tone |
|---------|---------|----------|------|
| API timeout | "This is taking longer than expected. Try again?" | Retry button | Patient |
| Network offline | "It looks like you're offline. Check your connection and try again." | Retry button | Helpful |
| Rate limited | "You're moving fast! Please wait a moment and try again." | Auto-retry after delay | Light |

## Form Validation
| Field | Rule | Message | Placement |
|-------|------|---------|-----------|
| GPA | 0.0-4.0 | "Enter a GPA between 0.0 and 4.0" | Inline |
| Email | Valid format | "Please enter a valid email address" | Inline |
| ...  | ... | ... | ... |

## Auth Errors
| Trigger | Message | Recovery |
|---------|---------|----------|
| Wrong password | "That password doesn't match. Try again or reset your password." | Reset link |
| Session expired | "Your session expired. Please log in again." | Login redirect |
| ... | ... | ... |

## Feature-Specific Errors
[By feature area: onboarding, schools, plan, coach, documents]
```

---

## Output Format

```
## Error UX Auditor: /error-ux-auditor [mode] [target]

### Mode
[audit | review | catalog]

### Scope
[N pages, N error scenarios, N error messages reviewed]

### Error Quality Scores
| Feature Area | Prevention | Detection | Communication | Recovery | Overall |
|-------------|------------|-----------|---------------|----------|---------|
| Onboarding | 4/5 | 3/5 | 2/5 | 3/5 | 3.0/5 |
| Schools | 3/5 | 4/5 | 3/5 | 2/5 | 3.0/5 |
| Plan | 2/5 | 3/5 | 2/5 | 1/5 | 2.0/5 |
| Coach | 3/5 | 4/5 | 4/5 | 3/5 | 3.5/5 |
| ... | ... | ... | ... | ... | ... |

### Findings
| Severity | Stage | File | Error Scenario | Issue | Fix |
|----------|-------|------|----------------|-------|-----|
| P1 | Recovery | PlanPage.tsx | Generation fails | No retry button, user stuck | Add retry CTA |
| P1 | Communication | DocumentUpload.tsx | Upload fails | Shows raw Supabase error | Wrap in user-friendly message |
| P2 | Prevention | AcademicsForm.tsx | GPA > 4.0 | No input validation until submit | Add max={4.0} + inline error |

### Error Message Catalog
[Full catalog or link to generated file]

### Summary
🛡️ Error scenarios identified: [N]
📝 Error messages audited: [N]
🔴 P1 issues: [N]
⚠️ P2 issues: [N]
✅ Well-handled errors: [N]
📊 Average error quality: [X.X]/5
```

---

## When to Escalate

Stop and discuss if:
- An error scenario reveals a **data loss risk** (unsaved work, cleared forms)
- An unrecoverable error has **no support channel** for users to escalate
- Error handling would require **API changes** (new error codes, different response shapes)
- A pattern of poor errors suggests the **error handling architecture** needs rethinking

---

## Key References

- `/frontend-auditor` Rule 3 — Error states exist (code-level)
- `/frontend-auditor` Rule 4 — Async action states
- `/a11y-auditor` Rule 9 — Error recovery (WCAG)
- `/ux-writer` Rule 6 — Error message copy quality
- `src/lib/api/errors.ts` — API error codes
- User Testing Sprint 1 — Raw error leaks to client (PR #1744)
