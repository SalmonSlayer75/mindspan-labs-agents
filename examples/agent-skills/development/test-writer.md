> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /test-writer Agent

This agent generates comprehensive tests for the project code, covering unit tests, integration tests, and end-to-end scenarios.

## Purpose

Ensure all code has appropriate test coverage, focusing on happy paths, edge cases, security boundaries, and the project-specific requirements.

## Usage

```
/test-writer [SCOPE] [OPTIONS]
```

## Scope Options

| Scope | What It Tests |
|-------|---------------|
| `file path/to/file.ts` | Tests for single file |
| `endpoint /api/path` | API endpoint tests |
| `component ComponentName` | React component tests |
| `feature [name]` | Feature area tests |
| `function functionName` | Specific function tests |

## Options

| Option | Description |
|--------|-------------|
| `--unit` | Unit tests only |
| `--integration` | Integration tests only |
| `--e2e` | End-to-end tests only |
| `--coverage` | Include coverage analysis |

## Examples

```
/test-writer file lib/schools/fit.ts

/test-writer endpoint /api/students/profile

/test-writer component SchoolCard

/test-writer feature onboarding --integration

/test-writer function calculateGPA --unit
```

## Test Categories

### 1. Unit Tests

**Purpose:** Test individual functions in isolation

**Framework:** Vitest (or Jest)

**Naming:** `[filename].test.ts`

**Example:**
```typescript
// lib/schools/fit.test.ts
import { describe, it, expect } from 'vitest';
import { calculateFit } from './fit';

describe('calculateFit', () => {
  describe('when student has high GPA', () => {
    it('returns "likely" for schools with lower GPA range', () => {
      const student = { gpa: 4.0 };
      const school = { gpa_25th: 3.2, gpa_75th: 3.7 };

      const result = calculateFit(student, school);

      expect(result.fit).toBe('likely');
      expect(result.reason).toContain('above 75th');
    });
  });

  describe('when student GPA is in middle range', () => {
    it('returns "target" for schools where GPA is in middle 50%', () => {
      const student = { gpa: 3.5 };
      const school = { gpa_25th: 3.2, gpa_75th: 3.7 };

      const result = calculateFit(student, school);

      expect(result.fit).toBe('target');
    });
  });

  describe('when data is missing', () => {
    it('returns "unknown" when student has no GPA', () => {
      const student = { gpa: undefined };
      const school = { gpa_25th: 3.2, gpa_75th: 3.7 };

      const result = calculateFit(student, school);

      expect(result.fit).toBe('unknown');
      expect(result.reason).toContain('Insufficient data');
    });

    it('returns "unknown" when school has no GPA data', () => {
      const student = { gpa: 3.5 };
      const school = { gpa_25th: undefined, gpa_75th: undefined };

      const result = calculateFit(student, school);

      expect(result.fit).toBe('unknown');
    });
  });
});
```

### 2. API Endpoint Tests

**Purpose:** Test API routes including auth, validation, and responses

**Framework:** Vitest + supertest (or built-in Next.js testing)

**Naming:** `[endpoint].test.ts` in `tests/api/`

**Example:**
```typescript
// tests/api/students/profile.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { POST, GET } from '@/app/api/students/profile/route';
import { createMockRequest, createMockUser } from '@/tests/utils';

describe('POST /api/students/profile', () => {
  describe('authentication', () => {
    it('returns 401 when not authenticated', async () => {
      const request = createMockRequest({
        method: 'POST',
        body: { first_name: 'Test' },
      });

      const response = await POST(request);

      expect(response.status).toBe(401);
    });

    it('returns 200 when authenticated', async () => {
      const user = createMockUser();
      const request = createMockRequest({
        method: 'POST',
        body: { first_name: 'Test', grade: '11', state: 'WA' },
        user,
      });

      const response = await POST(request);

      expect(response.status).toBe(200);
    });
  });

  describe('validation', () => {
    it('returns 400 for invalid grade', async () => {
      const user = createMockUser();
      const request = createMockRequest({
        method: 'POST',
        body: { first_name: 'Test', grade: '13' },  // Invalid
        user,
      });

      const response = await POST(request);
      const data = await response.json();

      expect(response.status).toBe(400);
      expect(data.error.field).toBe('grade');
    });

    it('returns 400 for GPA out of range', async () => {
      const user = createMockUser();
      const request = createMockRequest({
        method: 'POST',
        body: { first_name: 'Test', gpa: 6.0 },  // Invalid
        user,
      });

      const response = await POST(request);

      expect(response.status).toBe(400);
    });
  });

  describe('user scoping', () => {
    it('creates profile for authenticated user only', async () => {
      const user = createMockUser({ id: 'user-123' });
      const request = createMockRequest({
        method: 'POST',
        body: { first_name: 'Test' },
        user,
      });

      await POST(request);

      // Verify profile created with correct user_id
      const profile = await getProfile('user-123');
      expect(profile.user_id).toBe('user-123');
    });
  });
});

describe('GET /api/students/profile', () => {
  it('returns only the authenticated user profile', async () => {
    // Create profiles for two users
    await createProfile({ user_id: 'user-1', first_name: 'Alice' });
    await createProfile({ user_id: 'user-2', first_name: 'Bob' });

    // Request as user-1
    const user = createMockUser({ id: 'user-1' });
    const request = createMockRequest({ method: 'GET', user });

    const response = await GET(request);
    const data = await response.json();

    expect(data.data.first_name).toBe('Alice');
    expect(data.data.user_id).toBe('user-1');
  });
});
```

### 3. Component Tests

**Purpose:** Test React components for rendering, interactions, and accessibility

**Framework:** Vitest + React Testing Library

**Naming:** `[Component].test.tsx` in component directory or `tests/components/`

**Example:**
```typescript
// components/SchoolCard/SchoolCard.test.tsx
import { describe, it, expect } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { SchoolCard } from './SchoolCard';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

const mockSchool = {
  id: '1',
  name: 'University of Washington',
  acceptance_rate: 0.52,
  gpa_25th: 3.5,
  gpa_75th: 3.9,
  fit: 'target' as const,
  estimatedCost: 28000,
};

describe('SchoolCard', () => {
  describe('rendering', () => {
    it('displays school name', () => {
      render(<SchoolCard school={mockSchool} />);

      expect(screen.getByText('University of Washington')).toBeInTheDocument();
    });

    it('displays fit indicator', () => {
      render(<SchoolCard school={mockSchool} />);

      expect(screen.getByText('Target')).toBeInTheDocument();
    });

    it('displays acceptance rate as percentage', () => {
      render(<SchoolCard school={mockSchool} />);

      expect(screen.getByText('52%')).toBeInTheDocument();
    });

    it('displays estimated cost formatted', () => {
      render(<SchoolCard school={mockSchool} />);

      expect(screen.getByText('$28,000')).toBeInTheDocument();
    });
  });

  describe('interactions', () => {
    it('calls onSelect when clicked', () => {
      const onSelect = vi.fn();
      render(<SchoolCard school={mockSchool} onSelect={onSelect} />);

      fireEvent.click(screen.getByRole('article'));

      expect(onSelect).toHaveBeenCalledWith(mockSchool.id);
    });

    it('calls onAddToList when add button clicked', () => {
      const onAddToList = vi.fn();
      render(<SchoolCard school={mockSchool} onAddToList={onAddToList} />);

      fireEvent.click(screen.getByRole('button', { name: /add to list/i }));

      expect(onAddToList).toHaveBeenCalledWith(mockSchool.id);
    });
  });

  describe('accessibility', () => {
    it('has no accessibility violations', async () => {
      const { container } = render(<SchoolCard school={mockSchool} />);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('is keyboard navigable', () => {
      render(<SchoolCard school={mockSchool} />);

      const card = screen.getByRole('article');
      card.focus();

      expect(document.activeElement).toBe(card);
    });
  });

  describe('loading state', () => {
    it('shows skeleton when loading', () => {
      render(<SchoolCard school={mockSchool} isLoading />);

      expect(screen.getByTestId('school-card-skeleton')).toBeInTheDocument();
    });
  });

  describe('data freshness', () => {
    it('shows stale data warning when data is old', () => {
      const staleSchool = {
        ...mockSchool,
        last_verified_date: new Date('2023-01-01'),
      };

      render(<SchoolCard school={staleSchool} />);

      expect(screen.getByText(/may be outdated/i)).toBeInTheDocument();
    });
  });
});
```

### 4. Integration Tests

**Purpose:** Test multiple components/services working together

**Example:**
```typescript
// tests/integration/onboarding-flow.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { createTestUser, cleanupTestData } from '@/tests/utils';

describe('Onboarding Flow Integration', () => {
  let userId: string;

  beforeEach(async () => {
    const user = await createTestUser();
    userId = user.id;
  });

  afterEach(async () => {
    await cleanupTestData(userId);
  });

  it('completes full onboarding flow', async () => {
    // Phase 1: Quick Profile
    await completePhase1(userId, {
      first_name: 'Test',
      grade: '11',
      state: 'WA',
    });

    const progress = await getOnboardingProgress(userId);
    expect(progress.phase_1_status).toBe('completed');
    expect(progress.current_phase).toBe(2);

    // Phase 2: Academics
    await completePhase2(userId, {
      gpa: 3.7,
      gpa_type: 'weighted',
      courses: [
        { name: 'AP Chemistry', grade: 'A' },
      ],
    });

    expect((await getOnboardingProgress(userId)).phase_2_status).toBe('completed');

    // ... continue through phases ...
  });

  it('allows going back without losing data', async () => {
    await completePhase1(userId, { first_name: 'Test', grade: '11' });
    await completePhase2(userId, { gpa: 3.7 });

    // Go back to phase 1
    await navigateToPhase(userId, 1);

    // Data should still be there
    const profile = await getStudentProfile(userId);
    expect(profile.first_name).toBe('Test');
  });
});
```

### 5. the project-Specific Test Scenarios

#### Privacy Tests
```typescript
describe('Student Data Privacy', () => {
  it('never logs GPA values', async () => {
    const consoleSpy = vi.spyOn(console, 'log');

    await updateStudentProfile(userId, { gpa: 3.9 });

    const allLogs = consoleSpy.mock.calls.flat().join(' ');
    expect(allLogs).not.toContain('3.9');
    expect(allLogs).not.toContain('gpa');
  });

  it('prevents cross-user data access', async () => {
    const user1 = await createTestUser();
    const user2 = await createTestUser();

    await createProfile(user1.id, { first_name: 'Alice' });

    // Try to access user1's profile as user2
    const result = await getProfileAsUser(user1.id, user2.id);

    expect(result).toBeNull();
  });
});
```

#### State-Agnostic Tests
```typescript
describe('State-Agnostic Architecture', () => {
  it('works for non-WA students', async () => {
    const user = await createTestUser({ state: 'TX' });

    const recommendations = await getSchoolRecommendations(user.id);

    expect(recommendations).toBeDefined();
    expect(recommendations.length).toBeGreaterThan(0);
  });

  it('applies correct state-specific rules', async () => {
    const waUser = await createTestUser({ state: 'WA' });
    const txUser = await createTestUser({ state: 'TX' });

    const waConfig = await getStateConfig(waUser.id);
    const txConfig = await getStateConfig(txUser.id);

    expect(waConfig.wue_eligible).toBe(true);
    expect(txConfig.wue_eligible).toBe(false);  // TX not in WUE
  });
});
```

#### Coach Guardrail Tests
```typescript
describe('Coach Guardrails', () => {
  it('refuses to write essays', async () => {
    const response = await askCoach(userId, 'Write my college essay about leadership');

    expect(response.content).toContain("can't write your essay");
    expect(response.content).not.toMatch(/essay content/i);
  });

  it('enforces proactive message frequency', async () => {
    // Send first proactive message
    await sendProactiveMessage(userId, { type: 'insight' });

    // Try to send another within a week
    const canSend = await canSendProactiveMessage(userId, 'insight');

    expect(canSend).toBe(false);
  });

  it('allows high-urgency messages to override frequency', async () => {
    await sendProactiveMessage(userId, { type: 'insight' });

    // Urgent deadline warning should be allowed
    const canSend = await canSendProactiveMessage(userId, 'deadline', 'high');

    expect(canSend).toBe(true);
  });
});
```

#### School Data Tests
```typescript
describe('School Data Integrity', () => {
  it('flags stale deadline data', () => {
    const deadline = {
      date: new Date('2024-11-01'),
      verified_date: new Date('2024-01-01'),  // 10 months ago
    };

    expect(isDeadlineReliable(deadline)).toBe(false);
  });

  it('links school data to correct entity', async () => {
    const school = await resolveSchool({ type: 'ipeds', value: '236948' });

    expect(school.name).toBe('University of Washington');
    expect(school.ceeb_code).toBe('4854');
  });
});
```

## Test Utilities

```typescript
// tests/utils/index.ts

export function createMockUser(overrides = {}) {
  return {
    id: `test-user-${Date.now()}`,
    email: 'test@example.com',
    ...overrides,
  };
}

export function createMockRequest({ method, body, user, headers = {} }) {
  const request = new Request('http://localhost', {
    method,
    body: body ? JSON.stringify(body) : undefined,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
  });

  // Mock auth
  if (user) {
    vi.mocked(getUser).mockResolvedValue(user);
  }

  return request;
}

export async function createTestUser(profile = {}) {
  // Create user in test database
  const user = await supabase.auth.admin.createUser({
    email: `test-${Date.now()}@example.com`,
    email_confirm: true,
  });

  if (profile) {
    await supabase.from('student_profiles').insert({
      user_id: user.id,
      ...profile,
    });
  }

  return user;
}

export async function cleanupTestData(userId: string) {
  await supabase.from('student_profiles').delete().eq('user_id', userId);
  await supabase.from('student_activities').delete().eq('user_id', userId);
  await supabase.from('school_lists').delete().eq('user_id', userId);
  await supabase.auth.admin.deleteUser(userId);
}
```

## Output Template

```
## Tests Written: [Scope]

### Test Files Created
| File | Tests | Type |
|------|-------|------|
| `lib/schools/fit.test.ts` | 8 | Unit |
| `tests/api/students/profile.test.ts` | 12 | API |
| `components/SchoolCard/SchoolCard.test.tsx` | 10 | Component |

### Test Coverage
| Category | Tests | Passing |
|----------|-------|---------|
| Happy Path | 15 | ✅ 15 |
| Edge Cases | 8 | ✅ 8 |
| Error Cases | 6 | ✅ 6 |
| Security | 4 | ✅ 4 |
| Accessibility | 3 | ✅ 3 |

### Coverage Report
| File | Statements | Branches | Functions |
|------|------------|----------|-----------|
| `fit.ts` | 95% | 90% | 100% |
| `route.ts` | 88% | 85% | 100% |

### Test Categories
- [x] Unit tests for pure functions
- [x] API tests with auth/validation
- [x] Component rendering tests
- [x] Accessibility tests
- [x] Privacy/security tests
- [x] State-agnostic tests (if applicable)

### Run Command
```bash
npm test tests/[scope]
```

### Notes
[Any observations or recommendations]
```

## Checklist (Auto-Verified)

- [ ] Happy path covered
- [ ] Edge cases covered
- [ ] Error cases covered
- [ ] Authentication tested
- [ ] Validation tested
- [ ] User-scoping tested
- [ ] Accessibility tested (for components)
- [ ] No hardcoded test data that looks real
- [ ] Tests are isolated (no cross-test dependencies)
- [ ] Cleanup runs after each test

---

**Note:** Write tests first (TDD) when fixing bugs to prevent regression. Test names should clearly describe the scenario being tested.
