> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /bug-analyzer Agent

This agent performs root cause analysis on bugs, validates assumptions, and prevents regression.

## Purpose

When a bug is reported or discovered, this agent systematically analyzes the issue, identifies root cause, and ensures the fix doesn't introduce new problems.

## Usage

```
/bug-analyzer [BUG_DESCRIPTION]
```

## Examples

```
/bug-analyzer GPA calculation showing wrong value for weighted grades

/bug-analyzer School recommendations not filtering by student state

/bug-analyzer Coach sending proactive messages too frequently

/bug-analyzer Transcript upload failing for large PDFs
```

## Analysis Process

### 1. Reproduce the Bug

```
1. Document exact steps to reproduce
2. Identify affected user types (student, parent, etc.)
3. Note environment (browser, device, etc.)
4. Confirm bug is reproducible
```

### 2. Gather Context

```
1. Identify affected files and functions
2. Review recent changes to those files
3. Check for related bugs or patterns
4. Review relevant test coverage
```

### 3. Root Cause Analysis

```
1. Form hypotheses about cause
2. Test each hypothesis
3. Identify the actual root cause
4. Document the causal chain
```

### 4. Impact Assessment

```
1. How many users affected?
2. Data integrity implications?
3. Security implications?
4. Related features that may be affected?
```

### 5. Fix Validation

```
1. Does fix address root cause (not just symptom)?
2. Does fix follow PATTERNS.md?
3. Are there edge cases to consider?
4. What tests prevent regression?
```

## the project-Specific Bug Categories

### Category 1: Data Privacy Bugs (CRITICAL)

**Indicators:**
- Student data visible to wrong user
- Sensitive data in logs
- Missing user-scoping in queries

**Root Cause Checklist:**
- [ ] All queries use `user_id` filter
- [ ] RLS policies active on table
- [ ] No sensitive data in error messages
- [ ] Logging redacts GPA, scores, financial info

**Example Analysis:**
```
Bug: "Student can see another student's school list"

Hypothesis 1: Query missing user_id filter
→ Checked: school_lists query in lib/schools/queries.ts
→ CONFIRMED: Line 45 uses .eq('list_id', listId) without .eq('user_id', userId)

Root Cause: Query not scoped to authenticated user
Impact: CRITICAL - data privacy violation
Fix: Add .eq('user_id', userId) to query
Tests: Add test for cross-user access attempt
```

### Category 2: State-Specific Bugs

**Indicators:**
- Feature works for WA but not other states
- Hardcoded state references
- Missing state configuration

**Root Cause Checklist:**
- [ ] No hardcoded 'WA' in code
- [ ] State pulled from user profile
- [ ] State config exists in database
- [ ] Fallback behavior for missing state config

**Example Analysis:**
```
Bug: "WUE eligibility shows for all students"

Hypothesis 1: WUE check hardcoded to return true
→ Checked: lib/schools/wue.ts
→ CONFIRMED: Line 12 returns true without checking student.state

Root Cause: WUE eligibility not checking actual state
Impact: MEDIUM - incorrect financial information displayed
Fix: Check student.state against WUE-eligible states from state_config table
Tests: Add tests for WUE vs non-WUE states
```

### Category 3: Coach Guardrail Bugs

**Indicators:**
- Coach writing essays or application content
- Coach sending too many proactive messages
- Inappropriate tone or advice

**Root Cause Checklist:**
- [ ] System prompt includes all guardrails
- [ ] Essay detection running before response
- [ ] Proactive message frequency check working
- [ ] Message logged for frequency tracking

**Example Analysis:**
```
Bug: "Coach offering to write student's essay"

Hypothesis 1: Essay detection not triggering
→ Checked: lib/coach/guardrails.ts
→ User message was "help me with my essay structure"
→ Pattern only matches "write my essay", not "help me with"

Root Cause: Essay detection patterns too narrow
Impact: HIGH - violates core guardrail
Fix: Expand patterns OR rely on system prompt (preferred)
Tests: Add edge case test messages
```

### Category 4: School Data Bugs

**Indicators:**
- Wrong deadline dates
- Incorrect admission statistics
- Missing or stale data

**Root Cause Checklist:**
- [ ] Data source verified (IPEDS, Scorecard, CDS)
- [ ] Data freshness within threshold
- [ ] Entity resolution correct (right school)
- [ ] Parsing logic correct

**Example Analysis:**
```
Bug: "Stanford ED deadline showing as Nov 1 instead of Nov 1"
→ Wait, that's correct...

Bug: "Stanford showing as 'Rolling' admission"

Hypothesis 1: Data parsing error from CDS
→ Checked: crawl log for Stanford (IPEDS ID: 243744)
→ CDS parser extracted "rolling" from wrong section

Root Cause: CDS Section C parser matching wrong text
Impact: MEDIUM - incorrect admission info
Fix: Update parser to match Section C1 specifically
Tests: Add Stanford CDS to test fixtures
```

### Category 5: Onboarding Flow Bugs

**Indicators:**
- Progress not saving
- Can't navigate back
- Data lost between phases
- Validation errors unclear

**Root Cause Checklist:**
- [ ] Progress saved on each interaction
- [ ] Navigation preserves form state
- [ ] Validation messages user-friendly
- [ ] All required fields have defaults or skips

### Category 6: LLM/AI Bugs

**Indicators:**
- Extraction returning wrong data
- Coach response inappropriate
- High latency or timeouts
- Cost anomalies

**Root Cause Checklist:**
- [ ] Prompt engineered correctly
- [ ] Model selection appropriate (Sonnet vs Haiku)
- [ ] Timeout configured
- [ ] Telemetry recording correctly
- [ ] Response parsed correctly

## Output Template

```
## Bug Analysis: [Brief Description]

### Reproduction
- Steps: [1, 2, 3...]
- Environment: [Browser, device, user type]
- Frequency: [Always/Sometimes/Rare]

### Investigation

#### Files Examined
| File | Relevant Code | Finding |
|------|---------------|---------|
| `path/file.ts` | Lines 40-55 | Query missing user filter |

#### Hypotheses Tested
| # | Hypothesis | Result |
|---|------------|--------|
| 1 | Missing user filter | ✅ Confirmed |
| 2 | RLS policy disabled | ❌ RLS active |

### Root Cause
[Clear explanation of the actual cause]

### Impact Assessment
- **Severity:** Critical / High / Medium / Low
- **Users Affected:** [Scope]
- **Data Integrity:** [Impact]
- **Security:** [Impact]

### Recommended Fix
```typescript
// Before
const { data } = await supabase
  .from('school_lists')
  .select('*')
  .eq('list_id', listId);

// After
const { data } = await supabase
  .from('school_lists')
  .select('*')
  .eq('list_id', listId)
  .eq('user_id', userId);  // ADD: user scoping
```

### Regression Prevention
- [ ] Test: Cross-user access returns empty
- [ ] Test: Own user access works
- [ ] Security review: Verify all list queries scoped

### Related Areas to Check
- [ ] Other queries in `lib/schools/queries.ts`
- [ ] Similar pattern in `lib/activities/queries.ts`
```

## Checklist (Auto-Verified)

- [ ] Bug is reproducible with documented steps
- [ ] Root cause identified (not just symptom)
- [ ] Fix follows PATTERNS.md
- [ ] Impact assessed across all categories
- [ ] Regression tests defined
- [ ] Related code checked for same issue

## Integration

After running this agent:

1. **Check if this is a recurring bug** — search `memory/lessons.md` for the root cause pattern. Has it appeared before?
2. **Route to the right next step**:
   - **Recurring bug OR complex fix** (≥8 files, migration, auth/security involved): create a `[PLAN]` PR using `docs/plans/PLAN_TEMPLATE.md`, comment `@codex review`, and wait for approval before writing any code.
   - **Simple, novel bug**: proceed directly to fix → write regression tests → implement.
3. Run `/security-reviewer` if privacy-related
4. Update any affected documentation
5. Add to decision log if architectural

---

**Note:** Always fix the root cause, not the symptom. If a bug reveals a pattern violation, check for the same violation elsewhere in the codebase. Recurring violations are the strongest signal that a Codex plan review is needed.
