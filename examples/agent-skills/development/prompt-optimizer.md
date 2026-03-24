# /prompt-optimizer Agent

This agent helps optimize LLM prompts for accuracy, efficiency, and cost-effectiveness while eliminating hallucinations.

## Purpose

When building AI-powered features (coach, extraction, analysis), this agent reviews and improves prompts to:
- Reduce hallucinations and confabulation
- Improve output accuracy and consistency
- Minimize token usage (cost)
- Ensure appropriate model selection

## Usage

```
/prompt-optimizer [PROMPT_LOCATION_OR_CONTENT]
```

## Examples

```
/prompt-optimizer lib/coach/prompts.ts

/prompt-optimizer "Review this extraction prompt: [paste prompt]"

/prompt-optimizer file lib/extraction/transcript.ts

/prompt-optimizer feature coach
```

## Optimization Framework

### 1. Hallucination Prevention

**Common Causes & Fixes:**

| Cause | Fix |
|-------|-----|
| Vague instructions | Be specific and concrete |
| Missing constraints | Add explicit boundaries |
| Asking for unknowable info | Require "I don't know" responses |
| Over-reliance on knowledge | Ground in provided context |
| Ambiguous output format | Specify exact JSON schema |

**Anti-Hallucination Patterns:**

```typescript
// ❌ PRONE TO HALLUCINATION
const prompt = `
What colleges would be good for this student?
`;

// ✅ GROUNDED IN DATA
const prompt = `
Based ONLY on the following student profile and school data provided,
identify which schools from the list are good fits.

STUDENT PROFILE:
${JSON.stringify(studentProfile)}

SCHOOL DATA (only consider these schools):
${JSON.stringify(schoolList)}

RULES:
- Only recommend schools from the provided list
- If data is missing to make a determination, say "insufficient data"
- Never invent statistics or requirements
- Cite specific data points for each recommendation

OUTPUT FORMAT:
{
  "recommendations": [
    {
      "school_id": "string",
      "fit": "reach" | "target" | "likely",
      "reasoning": "string citing specific data",
      "confidence": "high" | "medium" | "low",
      "data_gaps": ["string"] // What data would improve this assessment
    }
  ]
}
`;
```

**Required Elements for Factual Prompts:**
- [ ] Ground in provided context only
- [ ] Explicit "don't know" instruction
- [ ] Structured output format
- [ ] Confidence indicators
- [ ] Data source citations

### 2. Prompt Structure Optimization

**Optimal Prompt Anatomy:**

```typescript
const OPTIMIZED_PROMPT = `
# ROLE
[Who the AI is - be specific]

# CONTEXT
[Background information the AI needs]

# TASK
[Exactly what to do - be precise]

# CONSTRAINTS
[What NOT to do - boundaries]

# INPUT
[The user/system input to process]

# OUTPUT FORMAT
[Exact structure expected - JSON schema preferred]

# EXAMPLES (if helpful)
[1-2 examples of correct behavior]
`;
```

**Example - Coach Prompt Optimization:**

```typescript
// ❌ BEFORE: Vague, prone to issues
const coachPrompt = `
You are a helpful college admissions coach.
Help the student with their question.
`;

// ✅ AFTER: Structured, constrained, clear
const coachPrompt = `
# ROLE
You are an AI college admissions coach for the project, a planning tool
for high school juniors. Your tone is warm but direct - like a knowledgeable
family friend who happens to be an admissions expert.

# CONTEXT
Student Profile:
- Grade: ${student.grade}
- State: ${student.state}
- GPA: ${student.gpa} (${student.gpaType})
- Intended Major: ${student.intendedMajor || 'Undecided'}
- Schools Interested In: ${student.schools.map(s => s.name).join(', ')}

Current Date: ${new Date().toISOString().split('T')[0]}
Academic Year: ${getCurrentAcademicYear()}

# TASK
Respond to the student's question helpfully and accurately.

# CONSTRAINTS (NEVER VIOLATE)
1. NEVER write essays, personal statements, or application content
2. NEVER guarantee admission outcomes - use probability language
3. NEVER provide information you're not certain about - say "I'm not sure"
4. NEVER be discouraging - frame challenges as opportunities
5. NEVER reference data not provided in context
6. If asked about deadlines/requirements, note your information may be outdated

# STUDENT QUESTION
${userMessage}

# OUTPUT FORMAT
Respond conversationally in 2-4 paragraphs. If the question requires
specific data you don't have, acknowledge that and suggest where to verify.
`;
```

### 3. Token Efficiency

**Strategies to Reduce Tokens:**

| Strategy | Savings | Example |
|----------|---------|---------|
| Remove redundant instructions | 10-20% | Don't repeat rules |
| Use JSON over prose | 15-30% | Structured output |
| Abbreviate examples | 20-40% | Minimal viable examples |
| Context pruning | 30-50% | Only include relevant data |
| Model selection | 50-80% cost | Haiku vs Sonnet |

**Context Pruning Example:**

```typescript
// ❌ WASTEFUL: Sends entire student profile
const context = JSON.stringify(fullStudentProfile);  // ~2000 tokens

// ✅ EFFICIENT: Only relevant fields
const context = JSON.stringify({
  gpa: student.gpa,
  grade: student.grade,
  intendedMajor: student.intendedMajor,
  // Only what's needed for this specific task
});  // ~100 tokens
```

**Model Selection Guide:**

| Task | Recommended Model | Reasoning |
|------|-------------------|-----------|
| Complex reasoning | claude-3-5-sonnet | Needs deep analysis |
| Multi-turn coaching | claude-3-5-sonnet | Nuanced conversation |
| Data extraction | claude-3-5-haiku | Structured, repetitive |
| Classification | claude-3-5-haiku | Simple decisions |
| Summarization | claude-3-5-haiku | Straightforward |

### 4. Output Consistency

**Enforce Consistent Output:**

```typescript
// ❌ INCONSISTENT: Free-form response
const prompt = `Analyze this transcript and tell me what you find.`;

// ✅ CONSISTENT: Schema-enforced
const prompt = `
Analyze this transcript and extract course information.

OUTPUT SCHEMA (respond with valid JSON only):
{
  "courses": [
    {
      "name": "string",
      "grade": "A" | "A-" | "B+" | "B" | "B-" | "C+" | "C" | "C-" | "D" | "F",
      "credits": number,
      "is_honors": boolean,
      "is_ap": boolean,
      "year": "freshman" | "sophomore" | "junior" | "senior",
      "semester": "fall" | "spring" | "full_year"
    }
  ],
  "extraction_confidence": "high" | "medium" | "low",
  "issues": ["string"]  // Any parsing problems encountered
}

IMPORTANT:
- If a field cannot be determined, use null
- Do not invent data - only extract what's visible
- Report any ambiguities in the "issues" array
`;
```

### 5. Testing Prompts

**Prompt Test Cases:**

```typescript
// tests/prompts/coach.test.ts
describe('Coach Prompt', () => {
  describe('hallucination prevention', () => {
    it('refuses to provide made-up deadlines', async () => {
      const response = await askCoach(
        'What is the exact deadline for Stanford ED?'
      );

      expect(response).toMatch(/verify|check|may be outdated/i);
      expect(response).not.toMatch(/November 1|specific date/);
    });

    it('does not invent school statistics', async () => {
      const response = await askCoach(
        'What is the acceptance rate at Fake University?'
      );

      expect(response).toMatch(/don't have|not sure|cannot find/i);
    });
  });

  describe('guardrail compliance', () => {
    it('refuses essay writing requests', async () => {
      const response = await askCoach(
        'Write my personal statement about leadership'
      );

      expect(response).toMatch(/can't write.*essay/i);
      expect(response.length).toBeLessThan(500);  // Not an essay
    });
  });

  describe('output consistency', () => {
    it('provides structured JSON when requested', async () => {
      const response = await extractTranscript(sampleTranscript);

      expect(() => JSON.parse(response)).not.toThrow();
      const data = JSON.parse(response);
      expect(data).toHaveProperty('courses');
      expect(Array.isArray(data.courses)).toBe(true);
    });
  });
});
```

## the project-Specific Optimizations

### Coach Prompts
- Always include student context (grade, state, timeline)
- Include guardrails in every prompt
- Use "warm but direct" tone guidance
- Require confidence indicators

### Extraction Prompts
- Use Haiku for cost efficiency
- Provide exact JSON schemas
- Include "unknown" as valid output
- Report extraction confidence

### School Analysis Prompts
- Ground in provided school data only
- Never invent statistics
- Cite data sources
- Flag stale data

### Deadline/Requirement Prompts
- Always caveat with verification need
- Include "last verified" dates
- Suggest official sources

## Optimization Checklist

- [ ] **Grounding**: Prompt explicitly grounds AI in provided context
- [ ] **Constraints**: Clear boundaries on what NOT to do
- [ ] **Output Schema**: Structured format specified (JSON preferred)
- [ ] **Confidence**: Response includes confidence/certainty indicators
- [ ] **Unknowns**: Explicit handling for "don't know" cases
- [ ] **Model Fit**: Appropriate model selected for task complexity
- [ ] **Token Efficiency**: Minimal context for the task
- [ ] **Test Coverage**: Edge cases and failure modes tested
- [ ] **Telemetry**: Cost tracking integrated

## Output Template

```
## Prompt Optimization: [Location/Feature]

### Current Prompt Analysis
| Issue | Severity | Description |
|-------|----------|-------------|
| Hallucination risk | High | No grounding in provided data |
| Vague constraints | Medium | Missing explicit boundaries |
| No output schema | Medium | Free-form responses |

### Optimization Applied

#### Before (X tokens)
```
[original prompt]
```

#### After (Y tokens, Z% reduction)
```
[optimized prompt]
```

### Changes Made
1. Added explicit grounding clause
2. Defined JSON output schema
3. Added "unknown" handling
4. Reduced context to relevant fields
5. Selected appropriate model (Haiku vs Sonnet)

### Token Impact
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Prompt tokens | 500 | 350 | -30% |
| Expected output | 200 | 150 | -25% |
| Est. cost/call | $0.003 | $0.002 | -33% |

### Test Results
| Test | Status |
|------|--------|
| Hallucination prevention | ✅ Pass |
| Guardrail compliance | ✅ Pass |
| Output consistency | ✅ Pass |
| Edge case handling | ✅ Pass |

### Recommendations
- [Any additional suggestions]
```

---

**Note:** Run this agent whenever creating new AI features or when observing inconsistent/incorrect AI outputs. Prevention is cheaper than fixing hallucination issues in production.
