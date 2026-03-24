> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /security-reviewer Agent

This agent performs security and privacy audits specific to the project, focusing on student data protection, coach guardrails, and pattern compliance.

## Purpose

Before code is merged or deployed, this agent verifies compliance with PATTERNS.md security requirements and identifies potential vulnerabilities.

## Usage

```
/security-reviewer [SCOPE]
```

## Scope Options

| Scope | What It Reviews |
|-------|-----------------|
| `file path/to/file.ts` | Single file audit |
| `pr` | All changes in current PR |
| `feature [name]` | All files in feature area |
| `endpoint /api/path` | API endpoint security |
| `component ComponentName` | Component data handling |
| `full` | Complete codebase scan |

## Examples

```
/security-reviewer file app/api/students/profile/route.ts

/security-reviewer pr

/security-reviewer feature onboarding

/security-reviewer endpoint /api/coach/chat

/security-reviewer full
```

## Security Checklist Categories

### Category 1: Student Data Privacy (CRITICAL)

**What to check:**
- All queries scoped to authenticated user
- No sensitive data in logs
- No sensitive data in error messages
- No sensitive data in URLs
- Document storage is user-scoped

**Code patterns to find:**

```typescript
// ✅ PASS: User-scoped query
.eq('user_id', userId)

// ❌ FAIL: Missing user scope
.eq('id', profileId)  // No user check!

// ✅ PASS: Redacted logging
console.log('Profile updated', { userId, updatedAt });

// ❌ FAIL: Sensitive data logged
console.log('Profile', profile);  // Logs GPA, scores!

// ✅ PASS: Generic error
throw new Error('Profile not found');

// ❌ FAIL: Sensitive error
throw new Error(`GPA ${gpa} is invalid`);  // Leaks GPA!
```

**Sensitive data types:**
| Type | Examples | Rule |
|------|----------|------|
| Academic | GPA, test scores, grades | Never log, never in errors |
| Financial | Budget, EFC, aid amounts | Never log, never in errors |
| Personal | Essays, activities detail | Redact in logs |
| Documents | Transcripts, resumes | User-scoped storage only |

### Category 2: Authentication & Authorization

**What to check:**
- All API routes verify authentication
- Authorization checks match business rules
- No auth bypass vulnerabilities
- Session handling is secure

**Code patterns to find:**

```typescript
// ✅ PASS: Auth check at route start
export async function POST(request: Request) {
  const supabase = createRouteHandlerClient({ cookies });
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  // ... proceed with authenticated user
}

// ❌ FAIL: No auth check
export async function POST(request: Request) {
  const body = await request.json();
  // ... processes request without auth!
}

// ❌ FAIL: Auth check after data access
export async function GET(request: Request) {
  const data = await fetchSensitiveData();  // No auth yet!
  const user = await getUser();  // Too late!
}
```

### Category 3: Row Level Security (RLS)

**What to check:**
- All user-data tables have RLS enabled
- Policies enforce user_id matching
- No policy bypasses in application code
- Service role usage is minimal and justified

**Supabase patterns:**

```sql
-- ✅ PASS: RLS enabled with proper policy
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users access own data" ON student_profiles
  FOR ALL USING (auth.uid() = user_id);

-- ❌ FAIL: RLS disabled or missing policy
ALTER TABLE student_profiles DISABLE ROW LEVEL SECURITY;
```

```typescript
// ⚠️ CAUTION: Service role bypasses RLS
const supabase = createClient(url, serviceRoleKey);  // Document why needed!

// ✅ PASS: User client respects RLS
const supabase = createRouteHandlerClient({ cookies });
```

### Category 4: Input Validation

**What to check:**
- All inputs validated with Zod schemas
- No SQL injection vulnerabilities
- No XSS vulnerabilities
- File uploads validated

**Code patterns to find:**

```typescript
// ✅ PASS: Zod validation
const schema = z.object({
  gpa: z.number().min(0).max(5.0),
  grade: z.enum(['9', '10', '11', '12']),
});
const result = schema.safeParse(body);

// ❌ FAIL: No validation
const { gpa, grade } = await request.json();  // Unvalidated!

// ✅ PASS: Parameterized queries (Supabase does this)
.eq('user_id', userId)

// ❌ FAIL: String interpolation in queries
.filter(`user_id = '${userId}'`)  // SQL injection risk!

// ✅ PASS: Sanitized output
<p>{escapeHtml(userInput)}</p>

// ❌ FAIL: Direct HTML insertion
<div dangerouslySetInnerHTML={{ __html: userContent }} />  // XSS risk!
```

### Category 5: AI Coach Guardrails

**What to check:**
- System prompts include all guardrails
- Essay writing detection implemented
- Proactive message frequency enforced
- User data not leaked to AI without purpose

**Code patterns to find:**

```typescript
// ✅ PASS: Guardrails in system prompt
const systemPrompt = `
CRITICAL RULES (NEVER VIOLATE):
1. NEVER write essays for the student
2. NEVER guarantee admission outcomes
...
`;

// ❌ FAIL: Missing guardrails
const systemPrompt = `You are a helpful college coach.`;  // No rules!

// ✅ PASS: Essay detection
if (detectEssayRequest(userMessage)) {
  return ESSAY_REFUSAL_RESPONSE;
}

// ❌ FAIL: No essay detection
const response = await callCoach(userMessage);  // Could write essays!

// ✅ PASS: Minimal data to AI
const context = {
  grade: student.grade,
  interests: student.interests,
  // NOT: full_transcript, family_finances
};

// ❌ FAIL: Excessive data to AI
const context = { ...student };  // Sends everything including finances!
```

### Category 6: State-Agnostic Compliance

**What to check:**
- No hardcoded state references
- State config from database
- UI content from content layer

**Code patterns to find:**

```typescript
// ❌ FAIL: Hardcoded state
if (state === 'WA') { ... }
const isWUE = ['WA', 'OR', 'CA'].includes(state);

// ✅ PASS: Config-driven
const stateConfig = await getStateConfig(state);
if (stateConfig.wue_eligible) { ... }
```

### Category 7: Data Freshness & Integrity

**What to check:**
- School data has freshness tracking
- Stale data flagged in UI
- Deadlines verified recently
- Data sources documented

**Code patterns to find:**

```typescript
// ✅ PASS: Freshness tracked
interface SchoolData {
  data_source: string;
  last_verified_date: Date;
  data_confidence: 'high' | 'medium' | 'low';
}

// ❌ FAIL: No freshness info
interface SchoolData {
  acceptance_rate: number;
  // When was this verified? Unknown!
}
```

### Category 8: LLM Cost & Security

**What to check:**
- Telemetry recorded for all LLM calls
- No prompt injection vulnerabilities
- User content sanitized before LLM
- Model selection appropriate

**Code patterns to find:**

```typescript
// ✅ PASS: Telemetry wrapper
await callLLMWithTelemetry({
  model: 'claude-3-5-haiku-20241022',
  operationType: 'transcript_extraction',
  ...
});

// ❌ FAIL: Direct call without telemetry
await anthropic.messages.create({ ... });  // No cost tracking!

// ✅ PASS: User content separated
messages: [
  { role: 'system', content: SYSTEM_PROMPT },
  { role: 'user', content: `Student question: ${sanitize(input)}` }
]

// ❌ FAIL: Prompt injection risk
messages: [
  { role: 'user', content: input }  // Could contain prompt override!
]
```

## Output Template

```
## Security Review: [Scope]

### Summary
| Category | Status | Issues |
|----------|--------|--------|
| Student Data Privacy | ✅ Pass | 0 |
| Authentication | ✅ Pass | 0 |
| RLS Policies | ⚠️ Warning | 1 |
| Input Validation | ✅ Pass | 0 |
| Coach Guardrails | ✅ Pass | 0 |
| State-Agnostic | ✅ Pass | 0 |
| Data Freshness | ✅ Pass | 0 |
| LLM Security | ⚠️ Warning | 1 |

### Critical Issues (Block Merge)
None found.

### Warnings (Should Fix)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `lib/db.ts` | 45 | Service role without comment | Add justification comment |
| `lib/coach.ts` | 89 | Missing telemetry | Wrap with callLLMWithTelemetry |

### Passed Checks
- [x] All queries user-scoped
- [x] No sensitive data in logs
- [x] Auth checks on all routes
- [x] Zod validation on all inputs
- [x] Coach guardrails present
- [x] No hardcoded states
- [x] School data has freshness

### Files Reviewed
| File | Lines | Findings |
|------|-------|----------|
| `app/api/students/route.ts` | 120 | 0 |
| `lib/coach/chat.ts` | 200 | 1 warning |
| `components/SchoolCard.tsx` | 85 | 0 |

### Recommendations
1. Add telemetry wrapper to coach chat function
2. Document service role usage in lib/db.ts

### Certification
[  ] ✅ APPROVED - Safe to merge
[  ] ⚠️ APPROVED WITH NOTES - Fix warnings before production
[  ] ❌ BLOCKED - Critical issues must be resolved
```

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| **CRITICAL** | Data breach risk, auth bypass | Block merge, fix immediately |
| **HIGH** | Privacy violation, guardrail bypass | Block merge, fix before merge |
| **MEDIUM** | Missing best practice | Warning, fix before production |
| **LOW** | Minor improvement | Note for future, can merge |

## Checklist (Auto-Verified)

- [ ] All database queries scoped to user
- [ ] No sensitive data in logs or errors
- [ ] Authentication on all API routes
- [ ] Zod validation on all inputs
- [ ] RLS enabled on user-data tables
- [ ] Coach guardrails in all prompts
- [ ] No hardcoded state references
- [ ] LLM calls have telemetry
- [ ] School data has freshness tracking

## Integration

After running this agent:

1. Address any CRITICAL or HIGH issues before merge
2. Create tickets for MEDIUM issues
3. Note LOW issues for future improvement
4. Re-run after fixes to verify

---

**Note:** This agent is part of the `/new-endpoint` and `/new-component` skill chains. It runs automatically when using those skills. Can also be run standalone for audits.
