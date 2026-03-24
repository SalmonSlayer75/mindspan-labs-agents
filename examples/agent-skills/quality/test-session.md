# /test-session Skill

A user testing preparation and synthesis skill for the project. Use this to **structure testing sessions before they happen** and **turn raw feedback into prioritized issues after**.

This is for **human user testing** (Anna, Jason, beta testers) — not automated E2E tests (use `/run-e2e` for that).

## Usage

```
/test-session plan [persona]           — Create a test session plan for a specific tester
/test-session synthesize [notes]       — Turn raw session notes into categorized findings
/test-session compare [session1] [s2]  — Compare findings across two sessions
/test-session track                    — View all sessions and finding patterns
```

---

## Why Structure Matters

Unstructured testing produces anecdotes ("Anna didn't like the color"). Structured testing produces data ("3 of 4 testers couldn't find the compare feature within 60 seconds"). Data drives prioritization.

---

## Phase 1: Session Planning (/test-session plan)

### Step 1a — Define the Tester

```
TESTER PROFILE:
  Name: [real name]
  Role: Student / Parent
  Grade: [if student]
  Tech comfort: Low / Medium / High
  Prior sessions: [number of previous test sessions]
  Key context: [anything relevant — e.g., "first time seeing the plan page"]

FOCUS AREAS FOR THIS SESSION:
  (Select 2-3 — don't try to test everything at once)
  □ Onboarding flow (first-time experience)
  □ Dashboard comprehension (does the user understand what's shown?)
  □ School list management (find, add, compare schools)
  □ Plan reading and comprehension (does the plan feel personalized?)
  □ Coach interaction (can the user get help?)
  □ Financial information (are costs clear and trustworthy?)
  □ Parent experience (monitoring, permissions, navigation)
  □ Mobile experience (complete tasks on phone)
  □ Returning user experience (what's different on visit 2+)
```

### Step 1b — Write Task Scripts

Each task should be a realistic user goal, NOT "click the blue button."

```
TASK FORMAT:
  Task [N]: [Goal in user's words]
  Scenario: [Context that makes the task feel real]
  Success criteria: [Observable outcome — not just "they found it"]
  Max time: [How long before we consider it a failure]
  Observe: [What specific behaviors to watch for]

EXAMPLE TASKS:

Task 1: Find a school that fits your budget
  Scenario: "You're looking for schools that would cost your family less than $30K/year. Find one."
  Success criteria: User navigates to schools, filters/sorts by cost, identifies a school under $30K
  Max time: 3 minutes
  Observe: Do they use search? Filters? Scroll? Do they understand cost figures?

Task 2: Understand your plan's financial section
  Scenario: "Look at your plan and tell me what you'd pay at your top school."
  Success criteria: User finds financial section, can name a dollar figure, understands it's estimated
  Max time: 2 minutes
  Observe: Do they notice the disclaimer? Do they trust the number? Any confusion?

Task 3: Ask the coach for help
  Scenario: "You're not sure which schools to apply to first. Ask the coach for advice."
  Success criteria: User finds coach, types a question, gets a useful response
  Max time: 2 minutes
  Observe: Where do they look for the coach? Is it obvious?

Task 4: Compare two schools
  Scenario: "You're deciding between [School A] and [School B]. Compare them."
  Success criteria: User navigates to compare page, can articulate a difference between the two
  Max time: 3 minutes
  Observe: How do they access compare? Can they read the comparison?
```

### Step 1c — Pre-Session Checklist

```
BEFORE THE SESSION:
□ Test account set up with appropriate data (seeded profile, schools, plan)
□ Account verified working on target device (desktop/mobile)
□ Screen recording enabled (if remote)
□ Session notes template ready
□ Tester briefed: "Think out loud. There are no wrong answers. We're testing the app, not you."
□ Timer ready for timed tasks
□ Focus areas and tasks printed/visible

ENVIRONMENT:
□ Using staging or production? [staging recommended for new features]
□ Device: Desktop / Mobile / Both
□ Browser: Chrome / Safari / Other
□ Internet speed: Normal / Throttled (for mobile testing)
```

---

## Phase 2: Session Notes Template

Use this template DURING the session:

```markdown
# Test Session: [Tester Name] — [Date]

## Session Info
- Tester: [name] ([role], [grade if student])
- Device: [desktop/mobile/both]
- Duration: [total minutes]
- Focus areas: [2-3 areas]
- Session number: [1st, 2nd, etc.]

## Task Results

### Task 1: [Task name]
- Completed: Yes / No / Partial
- Time: [mm:ss]
- Path taken: [page → page → page]
- Struggled with: [specific element or concept]
- Verbatim quotes: "[what they said while doing it]"
- Severity: Blocker / Friction / Polish / None

### Task 2: [Task name]
...

## Unprompted Observations
(Things the tester said or did without being asked)
- "[quote]" — Context: [what they were looking at]
- ...

## Tester's Summary
(At the end, ask: "Overall, how did that feel? What was confusing? What was good?")
- Positive: [what they liked]
- Negative: [what frustrated them]
- Confused by: [what they didn't understand]
- Wished for: [features they expected but didn't find]

## Screenshotter / Timestamps
(If screen recording, note timestamps for key moments)
- [mm:ss] — [what happened]
```

---

## Phase 3: Synthesis (/test-session synthesize)

After a session, turn raw notes into actionable findings.

### Step 3a — Categorize Findings

```
For each observation from the session, categorize:

FINDING FORMAT:
  ID: [session]-[number] (e.g., anna-s2-003)
  Category: Navigation | Comprehension | Copy | Visual | Flow | Data | Performance | Bug
  Severity: Blocker | Friction | Polish
  Evidence: "[verbatim quote]" + [behavior observed]
  Affected: Page/component/feature
  Frequency: First occurrence | Seen before in [session]
  Recommendation: [specific fix]

SEVERITY DEFINITIONS:
  Blocker: User could not complete the task. Must fix.
  Friction: User completed the task but with difficulty or confusion. Should fix.
  Polish: User noticed something suboptimal but wasn't blocked. Nice to fix.
```

### Step 3b — Pattern Detection

```
After categorizing, look for patterns:

□ Did multiple testers struggle with the same thing? (= systemic issue)
□ Did the same tester struggle with the same TYPE of thing? (= category issue)
□ Are findings clustered on specific pages? (= page needs redesign)
□ Are findings clustered in a specific category? (= systemic pattern)

PATTERN FORMAT:
  Pattern: [descriptive name]
  Occurrences: [list of finding IDs]
  Root cause: [why this keeps happening]
  Fix scope: [number of files/pages affected]
  Priority: P1 / P2
```

### Step 3c — File GitHub Issues

```
For each Blocker finding and each Pattern:
1. Create a GitHub issue with labels: ux, user-testing, P1/P2
2. Include:
   - Session context (who, when, what device)
   - Verbatim quote from tester
   - Observed behavior
   - Expected behavior
   - Screenshot/timestamp if available
   - Recommended fix
3. Cross-reference related findings
```

---

## Phase 4: Cross-Session Comparison (/test-session compare)

When comparing multiple sessions:

```
COMPARISON FORMAT:

| Finding | Session 1 (Anna) | Session 2 (Jason) | Pattern? |
|---------|------------------|-------------------|----------|
| Couldn't find compare | ✅ Struggled | ✅ Struggled | Yes — P1 |
| Financial confusion | ✅ Confused by COA | ❌ No issue | Maybe — retest |
| Coach discoverable | ❌ Found easily | ✅ Couldn't find | Inconsistent |

CROSS-SESSION PATTERNS:
(These are your highest-priority fixes — multiple people hit the same wall)
1. [Pattern] — seen in [N] of [N] sessions
2. ...
```

---

## Phase 5: Session Tracking (/test-session track)

Maintain a running log of all test sessions:

```markdown
# User Testing Sessions Log

## Summary
| # | Date | Tester | Role | Focus | Blockers | Friction | Polish |
|---|------|--------|------|-------|----------|----------|--------|
| 1 | 2026-03-10 | Anna | Student | Onboarding | 2 | 5 | 3 |
| 2 | 2026-03-10 | Jason | Parent | Dashboard | 1 | 3 | 4 |
| 3 | 2026-03-14 | Anna | Student | Schools, Plan | 0 | 4 | 2 |
| 4 | 2026-03-14 | Jason | Parent | Financial | 1 | 2 | 5 |

## Recurring Patterns (across sessions)
| Pattern | Sessions | Status |
|---------|----------|--------|
| Compare page unfindable | S1, S2 | Fixed in PR #1741 |
| Financial jargon confusion | S1, S4 | Open — #1750 |
| Coach not discoverable on mobile | S2, S3 | Open — #1760 |

## Coverage Gaps (what we haven't tested yet)
□ Mobile-only session
□ Returning user (Day 2+)
□ Student-only family (no parent)
□ Parent with multiple students
```

---

## Output Format

```
## Test Session: /test-session [mode] [target]

### Mode
[plan | synthesize | compare | track]

### Session Summary
[Tester name, date, device, focus areas]

### Task Results
| Task | Completed | Time | Severity | Key Observation |
|------|-----------|------|----------|-----------------|
| Find affordable school | Yes | 2:15 | Friction | Used search, didn't notice sort |
| Understand financial plan | Partial | 3:30 | Blocker | Couldn't find cost estimate |

### Findings
| ID | Category | Severity | Page | Finding | Recommendation |
|----|----------|----------|------|---------|----------------|
| anna-s3-001 | Navigation | Friction | /schools | Compare button not visible | Move above fold |
| anna-s3-002 | Copy | Blocker | /plan | "Net Price" unexplained | Replace with "Estimated cost" |

### Patterns Detected
| Pattern | Occurrences | Priority |
|---------|-------------|----------|
| Financial jargon | 3 findings | P1 |

### Issues Filed
| # | Title | Severity |
|---|-------|----------|
| #1750 | Replace financial jargon on plan page | P1 |

### Summary
🧪 Tasks tested: [N]
✅ Completed: [N]
⚠️ Friction: [N]
🔴 Blockers: [N]
📋 Issues filed: [N]
🔄 Patterns: [N]
```

---

## When to Escalate

Stop and discuss if:
- A blocker suggests a **fundamental flow problem** (not just a UI fix)
- Multiple testers independently suggest the **same missing feature**
- Findings contradict existing **product decisions** (e.g., tester says 3-list system is confusing)
- Testing reveals **data quality issues** (wrong school data, stale information)

---

## Key References

- User Testing Sprint 1: PR #1744 (19 issues from Anna & Jason)
- User Testing Sprint 2: PR #1745 (4 UX fixes from Anna & Jason)
- `/run-e2e` — Automated E2E testing (different purpose — tests code, not humans)
- `/ux-ia-auditor` — IA audit (complement: tests structure, not with real users)
- Brand Brief: https://www.notion.so/2ee65d2ef8aa81589e1edb97d43799c2
