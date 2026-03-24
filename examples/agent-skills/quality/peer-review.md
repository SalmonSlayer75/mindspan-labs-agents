# /peer-review Agent

This agent processes code review feedback from external sources (Gemini, Codex, human reviewers) and proposes actionable responses.

## Purpose

When you receive code review feedback from other AI tools or human reviewers, this agent:
- Parses and categorizes the feedback
- Evaluates each point against the project patterns
- Identifies valid concerns vs. false positives
- Proposes specific actions or rebuttals
- Maintains consistent code quality across review sources

## Usage

```
/peer-review [PASTE_FEEDBACK]
```

Or provide context:
```
/peer-review from gemini on lib/coach/prompts.ts
[paste feedback]
```

## Examples

```
/peer-review from codex
The function calculateFit lacks error handling for null values.
Consider adding input validation.

/peer-review from human reviewer
- Why are we using Haiku instead of Sonnet for extraction?
- The coach prompt seems too long, can we simplify?
- Missing tests for edge cases in GPA calculation

/peer-review from gemini on components/SchoolCard.tsx
1. Accessibility: Missing aria-label on icon buttons
2. Performance: Consider memoizing the fit calculation
3. Security: User input rendered without sanitization
```

## Feedback Processing Framework

### 1. Parse & Categorize

**Feedback Categories:**

| Category | Examples | Priority |
|----------|----------|----------|
| Security | XSS, injection, auth bypass | Critical |
| Privacy | Data exposure, logging sensitive info | Critical |
| Correctness | Logic errors, wrong calculations | High |
| Performance | N+1 queries, unnecessary rerenders | Medium |
| Accessibility | Missing ARIA, keyboard nav | Medium |
| Code Quality | Naming, structure, duplication | Low |
| Style | Formatting, conventions | Low |

**Parsing Template:**

```typescript
interface ReviewFeedback {
  source: 'gemini' | 'codex' | 'chatgpt' | 'human' | 'other';
  target_file?: string;
  items: FeedbackItem[];
}

interface FeedbackItem {
  id: number;
  category: FeedbackCategory;
  severity: 'critical' | 'high' | 'medium' | 'low';
  original_text: string;
  file?: string;
  line?: number;

  // Analysis
  is_valid: boolean;
  reasoning: string;

  // Action
  action: 'fix' | 'investigate' | 'defer' | 'reject';
  proposed_fix?: string;
  rebuttal?: string;
}
```

### 2. Evaluate Against Patterns

**Cross-Reference with PATTERNS.md:**

```
For each feedback item:

1. Does it relate to a defined pattern?
   - Yes → Check if code violates pattern
   - No → Evaluate on general best practices

2. Does our pattern conflict with the feedback?
   - If our pattern has good reason, document rebuttal
   - If feedback improves on our pattern, consider updating

3. Is this the project-specific context the reviewer missed?
   - Reviewer may not know our coach guardrails
   - Reviewer may not know our privacy requirements
   - Explain context in rebuttal if rejecting
```

**Example Evaluation:**

```
Feedback: "Coach prompt is too long, simplify it"

Evaluation:
- Our PATTERNS.md requires coach guardrails in every prompt
- The "extra length" is our hallucination prevention
- This is intentional, not bloat

Action: REJECT with explanation
Rebuttal: "The prompt length is intentional. Per our PATTERNS.md,
coach prompts must include guardrails for essay-writing prevention,
tone guidance, and grounding constraints. These cannot be removed
without introducing hallucination risk."
```

### 3. Response Templates

**For Valid Feedback:**

```markdown
## Accepted: [Brief Description]

**Source:** [Gemini/Codex/Human]
**File:** [path/to/file.ts]
**Severity:** [Critical/High/Medium/Low]

### Original Feedback
> [Quote the feedback]

### Analysis
[Why this is valid]

### Proposed Fix
```typescript
// Before
[original code]

// After
[fixed code]
```

### Implementation
- [ ] Apply fix
- [ ] Add test to prevent regression
- [ ] Update if pattern should change
```

**For Rejected Feedback:**

```markdown
## Rejected: [Brief Description]

**Source:** [Gemini/Codex/Human]
**File:** [path/to/file.ts]

### Original Feedback
> [Quote the feedback]

### Rebuttal
[Explanation of why we're not implementing this]

### Context Reviewer May Have Missed
- [the project specific context]
- [Reference to PATTERNS.md or ADR]

### No Action Required
This feedback does not apply to our context because [reason].
```

**For Items Needing Investigation:**

```markdown
## Investigate: [Brief Description]

**Source:** [Gemini/Codex/Human]
**File:** [path/to/file.ts]

### Original Feedback
> [Quote the feedback]

### Uncertainty
[Why we can't immediately determine if valid]

### Investigation Steps
1. [Step 1]
2. [Step 2]

### Decision Pending
Will resolve after investigation.
```

### 4. Common Reviewer Blind Spots

**Things External Reviewers Often Miss:**

| Blind Spot | Our Context | Response Pattern |
|------------|-------------|------------------|
| "Use shorter prompts" | Guardrails are required | Explain guardrail necessity |
| "Cache everything" | Some data needs freshness | Explain freshness requirements |
| "Use faster model" | Quality matters for coach | Explain model selection rationale |
| "Add more logging" | Privacy prevents this | Explain data sensitivity |
| "Generic error messages" | We already do this for privacy | Confirm alignment |
| "State-specific logic" | We're intentionally state-agnostic | Explain architecture decision |

### 5. Handling Conflicting Reviews

When different reviewers give conflicting feedback:

```markdown
## Conflict Resolution: [Topic]

### Feedback A (from Gemini)
> [Quote]
Suggests: [approach A]

### Feedback B (from Codex)
> [Quote]
Suggests: [approach B]

### Analysis
| Criterion | Approach A | Approach B |
|-----------|------------|------------|
| Aligns with patterns | ✅/❌ | ✅/❌ |
| Performance | Better/Worse | Better/Worse |
| Maintainability | Better/Worse | Better/Worse |
| Security | Better/Worse | Better/Worse |

### Decision
We will use [Approach X] because [reasoning].

### Rationale
[Detailed explanation]
```

## the project-Specific Review Context

When evaluating feedback, always consider:

### Privacy Constraints
- We CANNOT log GPA, test scores, financial info
- We CANNOT expose student data to other users
- Feedback suggesting "add logging" may violate this

### Coach Guardrails
- We CANNOT shorten prompts that contain guardrails
- We CANNOT use cheaper models if quality suffers
- Feedback about "prompt efficiency" needs careful evaluation

### State-Agnostic Architecture
- We CANNOT hardcode state-specific logic
- We MUST use configuration-driven approaches
- Feedback suggesting "just check for WA" is rejected

### Data Freshness
- We MUST track data staleness
- We CANNOT cache indefinitely
- Feedback about "aggressive caching" needs nuance

## Output Template

```
## Peer Review Analysis

**Source:** [Reviewer]
**Target:** [File(s) or Feature]
**Items Received:** X

### Summary
| Action | Count |
|--------|-------|
| ✅ Accept & Fix | X |
| 🔍 Investigate | X |
| ⏸️ Defer | X |
| ❌ Reject | X |

---

### ✅ Accepted Items

#### 1. [Brief Description]
**Severity:** High
**Original:** "[feedback quote]"
**Fix:**
```typescript
// Proposed change
```
**Action:** Fix in next commit

---

### ❌ Rejected Items

#### 1. [Brief Description]
**Original:** "[feedback quote]"
**Rebuttal:** [Why we're not doing this]
**Reference:** [PATTERNS.md section or ADR]

---

### 🔍 Needs Investigation

#### 1. [Brief Description]
**Original:** "[feedback quote]"
**Question:** [What we need to determine]
**Next Step:** [How to investigate]

---

### Implementation Plan
1. [ ] [Fix item 1]
2. [ ] [Fix item 2]
3. [ ] [Investigate item 1]

### Patterns to Update
- [ ] [If any pattern should change based on valid feedback]

### Response to Reviewer
[Draft response summarizing what we're accepting/rejecting and why]
```

## Checklist

- [ ] All feedback items categorized
- [ ] Each item evaluated against PATTERNS.md
- [ ] Valid items have proposed fixes
- [ ] Rejected items have documented rebuttals
- [ ] Conflicts resolved with rationale
- [ ] Implementation plan created
- [ ] Response to reviewer drafted (if needed)

---

**Note:** Not all feedback is equally valuable. External reviewers lack context about our specific requirements. Always evaluate feedback against our established patterns before implementing. When in doubt, investigate before acting.
