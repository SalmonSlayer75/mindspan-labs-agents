# /code-simplifier Agent

This agent performs code cleanup, refactoring, and simplification while maintaining correctness.

## Purpose

When code has grown complex, has duplication, or needs cleanup before a milestone, this agent systematically improves code quality without changing behavior.

## Usage

```
/code-simplifier [SCOPE]
```

## Scope Options

| Scope | What It Does |
|-------|--------------|
| `file path/to/file.ts` | Simplify single file |
| `component ComponentName` | Simplify component and related files |
| `feature onboarding` | Simplify feature area |
| `recent` | Simplify files changed today |
| `all` | Full codebase scan (use sparingly) |

## Examples

```
/code-simplifier file lib/schools/queries.ts

/code-simplifier component SchoolCard

/code-simplifier feature onboarding

/code-simplifier recent
```

## Simplification Categories

### 1. Dead Code Removal

**Find and remove:**
- Unused imports
- Unused variables and functions
- Commented-out code blocks
- Unreachable code

```typescript
// ❌ Before: Dead code
import { unusedFunction, usedFunction } from './utils';
import { OldType } from './types';  // Never used

const DEPRECATED_CONSTANT = 'old';  // Never referenced

export function doThing() {
  const unused = 'never used';
  // const oldCode = doOldThing();  // Commented out
  return usedFunction();
}

// ✅ After: Clean
import { usedFunction } from './utils';

export function doThing() {
  return usedFunction();
}
```

### 2. Duplication Elimination

**Identify and consolidate:**
- Copy-pasted code blocks
- Similar functions with slight variations
- Repeated patterns

```typescript
// ❌ Before: Duplicated logic
async function getStudentGPA(userId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Unauthorized');
  return await supabase.from('academics').select('gpa').eq('user_id', userId).single();
}

async function getStudentActivities(userId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Unauthorized');
  return await supabase.from('activities').select('*').eq('user_id', userId);
}

// ✅ After: Shared utility
async function withAuth<T>(query: (userId: string) => Promise<T>): Promise<T> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Unauthorized');
  return query(user.id);
}

const getStudentGPA = () => withAuth(userId =>
  supabase.from('academics').select('gpa').eq('user_id', userId).single()
);

const getStudentActivities = () => withAuth(userId =>
  supabase.from('activities').select('*').eq('user_id', userId)
);
```

### 3. Complexity Reduction

**Simplify:**
- Deeply nested conditionals
- Long functions (>50 lines)
- Complex boolean expressions
- Callback hell

```typescript
// ❌ Before: Nested complexity
function calculateFit(student: Student, school: School): FitResult {
  if (student.gpa) {
    if (school.gpa_25th && school.gpa_75th) {
      if (student.gpa >= school.gpa_75th) {
        return { fit: 'likely', reason: 'GPA above 75th percentile' };
      } else {
        if (student.gpa >= school.gpa_25th) {
          return { fit: 'target', reason: 'GPA in middle 50%' };
        } else {
          if (student.gpa >= school.gpa_25th - 0.3) {
            return { fit: 'reach', reason: 'GPA slightly below 25th' };
          } else {
            return { fit: 'reach', reason: 'GPA significantly below' };
          }
        }
      }
    }
  }
  return { fit: 'unknown', reason: 'Insufficient data' };
}

// ✅ After: Early returns, clear logic
function calculateFit(student: Student, school: School): FitResult {
  if (!student.gpa || !school.gpa_25th || !school.gpa_75th) {
    return { fit: 'unknown', reason: 'Insufficient data' };
  }

  if (student.gpa >= school.gpa_75th) {
    return { fit: 'likely', reason: 'GPA above 75th percentile' };
  }

  if (student.gpa >= school.gpa_25th) {
    return { fit: 'target', reason: 'GPA in middle 50%' };
  }

  const reason = student.gpa >= school.gpa_25th - 0.3
    ? 'GPA slightly below 25th'
    : 'GPA significantly below';

  return { fit: 'reach', reason };
}
```

### 4. Type Improvements

**Improve:**
- `any` types → specific types
- Missing return types
- Overly broad types
- Type assertions that could be avoided

```typescript
// ❌ Before: Weak typing
async function fetchSchool(id: string): Promise<any> {
  const data = await fetch(`/api/schools/${id}`);
  return data.json() as any;
}

// ✅ After: Strong typing
interface School {
  id: string;
  name: string;
  ipeds_unit_id: string;
  // ...
}

async function fetchSchool(id: string): Promise<School> {
  const response = await fetch(`/api/schools/${id}`);
  const data: School = await response.json();
  return data;
}
```

### 5. Naming Clarity

**Improve names for:**
- Single-letter variables (except loop indices)
- Abbreviations that aren't obvious
- Generic names (data, result, item)
- Misleading names

```typescript
// ❌ Before: Unclear names
const d = await getData(u);
const r = d.map(i => transform(i));
const f = r.filter(x => x.valid);

// ✅ After: Clear names
const schools = await getSchoolsForUser(userId);
const normalizedSchools = schools.map(school => normalizeSchoolData(school));
const validSchools = normalizedSchools.filter(school => school.isValid);
```

### 6. the project-Specific Simplifications

#### Student Data Queries
```typescript
// ❌ Before: Inconsistent scoping
const profile = await supabase.from('profiles').select().eq('user_id', userId).single();
const activities = await supabase.from('activities').select().eq('student_id', id);
const schools = await supabase.from('school_lists').select().eq('owner', uid);

// ✅ After: Consistent pattern
const profile = await getStudentData('profiles', userId);
const activities = await getStudentData('activities', userId);
const schools = await getStudentData('school_lists', userId);
```

#### Coach Prompts
```typescript
// ❌ Before: Prompts scattered everywhere
const systemPrompt = `You are a college admissions coach...`;
// ... different file ...
const coachInstructions = `As an AI coach for the project...`;

// ✅ After: Centralized in lib/coach/prompts.ts
import { COACH_SYSTEM_PROMPT, getContextualPrompt } from '@/lib/coach/prompts';
```

#### State Configuration
```typescript
// ❌ Before: Hardcoded checks
if (state === 'WA' || state === 'OR' || state === 'CA') {
  // WUE eligible
}

// ✅ After: Data-driven
const stateConfig = await getStateConfig(state);
if (stateConfig.wue_eligible) {
  // WUE eligible
}
```

## Process

### Step 1: Scan
```
1. Identify files in scope
2. Run static analysis (if available)
3. Identify issues by category
4. Prioritize by impact
```

### Step 2: Plan
```
1. Group related changes
2. Identify dependencies
3. Plan order of changes
4. Note any behavior-changing refactors (flag for review)
```

### Step 3: Execute
```
1. Make changes incrementally
2. Verify tests pass after each change
3. Commit logical units
4. Document significant changes
```

### Step 4: Verify
```
1. Run full test suite
2. Check for regressions
3. Review type coverage
4. Verify no behavior changes (unless intended)
```

## Output Template

```
## Code Simplification: [Scope]

### Files Analyzed
| File | Lines | Issues Found |
|------|-------|--------------|
| `lib/schools/queries.ts` | 245 | 3 |
| `components/SchoolCard.tsx` | 180 | 2 |

### Changes Made

#### Dead Code Removed
| File | Lines Removed | Description |
|------|---------------|-------------|
| `lib/schools/queries.ts` | 15 | Unused import, dead function |

#### Duplication Eliminated
| Pattern | Files | Lines Saved |
|---------|-------|-------------|
| Auth check pattern | 5 | 45 |

#### Complexity Reduced
| File | Before | After | Change |
|------|--------|-------|--------|
| `calculateFit.ts` | 12 nesting | 3 nesting | -75% |

#### Types Improved
| File | Changes |
|------|---------|
| `types.ts` | Replaced 3 `any` types |

### Test Results
- Before: X tests passing
- After: X tests passing
- New tests added: Y

### Summary
- Files modified: X
- Lines removed: Y
- Lines added: Z
- Net change: -W lines
```

## Checklist (Auto-Verified)

- [ ] All tests pass after changes
- [ ] No behavior changes (unless documented)
- [ ] Types are as specific as possible
- [ ] No dead code remains
- [ ] No obvious duplication
- [ ] Functions under 50 lines
- [ ] Max 3 levels of nesting
- [ ] Clear, descriptive names
- [ ] PATTERNS.md compliance maintained

## When NOT to Simplify

- **Don't simplify** code that's about to be replaced
- **Don't simplify** during active bug investigation (simplify after)
- **Don't simplify** if it makes code harder to understand
- **Don't simplify** third-party code or generated code
- **Ask first** if simplification changes public API

---

**Note:** Simplification should always maintain or improve correctness. When in doubt, add a test first, then simplify.
