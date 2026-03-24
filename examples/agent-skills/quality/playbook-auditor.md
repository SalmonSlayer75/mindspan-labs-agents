# /playbook-auditor Skill

A standalone playbook content quality audit skill for the project. Use this after any change to plan generation, LLM prompts, or PDF rendering — to catch placeholder text, generic content, personalization failures, and financial invariant violations before they reach a real student.

The the project playbook is the core product deliverable. Every bug here directly damages the student experience and undermines the "better than a $10K consultant" promise.

## Usage

```
/playbook-auditor audit              — Full quality audit across all generated playbook sections
/playbook-auditor validate [family]  — Audit a specific E2E family's generated playbook artifact
/playbook-auditor check [section]    — Audit a specific section (identity | assessment | schools | financial | essays | activity | action-plan | brag-sheet)
/playbook-auditor compare [a] [b]    — Compare two families' playbooks for problematic similarity (boilerplate detection)
```

---

## the project Playbook Fundamentals

Read these before doing anything. Every recurring playbook bug traces back to one of these.

### Rule 1 — Every Section Must Be Personalized, Not Generic

The test: could this exact text appear in any other student's playbook? If yes, it's a P1 bug.

```
// ✅ CORRECT — references actual student data
"Your startup (CivicTech WA, 2,000+ users) places you in the top 1% of Washington applicants
for demonstrated initiative. Pair this with your 3.85 GPA and UW's CS program becomes
a realistic target, not just a reach."

// ❌ WRONG — generic boilerplate
"Your extracurricular activities demonstrate strong leadership potential. You have a competitive
academic profile that will appeal to many colleges on your list."
```

### Rule 2 — Strategic Identity Binds the Declared Major, Not an Inferred One

```typescript
// ✅ CORRECT — major comes from DB intendedMajors, AUTHORITATIVE directive enforced
// "The Computer Science Path" when student declared CS

// ❌ WRONG — LLM infers major from activities
// "The Civic Leadership Path" when student declared CS but has civic activities
// Root cause: missing MAJOR BINDING directive in SYSTEM_PROMPT
```

The `strategicIdentity.tagline` must match `The [intendedMajors] Path`. Post-processor in `strategic-identity.ts` should rewrite mismatched taglines.

### Rule 3 — Honest Assessment Leads With the Strongest Differentiator

Strength detection order (first match wins):
1. Startup / founder with metrics (users, revenue, growth)
2. Published research or patent
3. State/national award or competition winner
4. Varsity sport (captain/starter)
5. Strong GPA (≥3.8)
6. High test scores (SAT ≥1400 / ACT ≥31)

```
// ❌ WRONG — leads with varsity when founder data is present
"Varsity athletic experience demonstrates time management..."

// ✅ CORRECT — startup leads
"As the founder of CivicTech WA (2,000+ active users), you bring rare technical
entrepreneurship to your application..."
```

### Rule 4 — Financial Values Must Be Non-Negative and Realistic

```typescript
// ✅ CORRECT
netCost = Math.max(0, stickerPrice - scholarships - wueDiscount - needBased)

// ❌ WRONG — negative net cost
netCost = stickerPrice - scholarships  // Can go below $0 if scholarships > sticker
```

All three budget scenarios (conservative/moderate/aggressive) must show different values. If all three are identical, something is broken in the financial calculation engine.

### Rule 5 — Scholarship Relevance Must Be Verified Against Student Profile

```
// ❌ WRONG — shown to wrong student
"National Merit Scholarship (Non-Washington Residents)" shown to a WA resident
"Army ROTC Scholarship" shown to a student with no military activities

// ✅ CORRECT — filtered by:
// 1. scholarship_name + special_eligibility combined residency check
// 2. Activity-based eligibility (military, employer, religion)
```

### Rule 6 — Essay Prompts Must Match the Student's Major/Program

```
// ❌ WRONG — nursing essay shown to pre-law student
"Describe your clinical experience and passion for patient care..."

// ✅ CORRECT — filterEssayPromptsByMajor() applied at all 3 essay sites:
// 1. DB field: applicable_majors
// 2. Text pattern: PROFESSIONAL_PROGRAM_PROMPT_PATTERNS (nursing, pharmacy, BFA)
```

### Rule 7 — Action Plan Tasks Must Match the Student's Actual Phase

```
// ❌ WRONG — junior tasks shown to submitted Grade 12 senior
"Start building your school list" / "Take the SAT for the first time"

// ✅ CORRECT — isDecisionMode check for application_status = 'submitted'
// Decision mode = 3-phase arc: Evaluate offers → Choose → Transition
```

### Rule 8 — Story Inventory Must Not Contain Unfilled Template Slots

```
// ❌ WRONG — template placeholders in output
"WHAT HAPPENED: [describe the challenge or situation]"
"WHAT YOU LEARNED: [describe your growth]"

// ✅ CORRECT — synthesizeActivityDescription() fills from structured DB fields
// (role_position, impact_description, skills_demonstrated, context_notes)
// If impact_description is null, synthesizes from other fields
```

---

## Phase 1: Establish Scope

```
For /playbook-auditor audit:
1. Find all E2E output artifacts: ls e2e/output/ | grep -E "\.json|\.pdf|playbook"
2. Read src/lib/llm/strategic-identity.ts — identity generation
3. Read src/lib/llm/action-plan-generator.ts — action plan
4. Read src/lib/llm/brag-sheet-generator.ts — brag sheet
5. Read src/app/api/students/plan/playbook-data/route.ts — data assembly
6. Identify the families with generated artifacts to test against

For /playbook-auditor validate [family]:
1. Read the family's playbook JSON from e2e/output/
2. Read the family fixture from e2e/fixtures/families/
3. Cross-reference: does the output match what this specific student's data would produce?

For /playbook-auditor compare [a] [b]:
1. Read both families' playbook artifacts
2. Diff string-by-string on variable sections (recommenders, essays, activity descriptions)
3. Flag any blocks >40 characters that are identical across both
```

---

## Phase 2: Audit Checks

### 2a — Strategic Identity Personalization

```
For each generated playbook:
□ Does strategicIdentity.tagline match "The [declared major] Path"?
□ Does the identity summary mention specific activities (not just "extracurriculars")?
□ Does it reference actual metrics from the student's activities (users, awards, hours)?
□ Is the tone differentiated — does it read differently than another student's identity?
□ Does "Your Identity At This School" section vary per school (not a copy-paste)?
□ Is "Strategic Positioning" fully written (not a placeholder like "See your full plan for details")?
```

**Severity:** Generic identity = P1. Placeholder text = P1. Wrong major in tagline = P1.

---

### 2b — Honest Assessment Accuracy

```
□ Does the first strength listed match the highest-ranked differentiator (Rule 3 order)?
□ If student has a startup with metrics, is it the FIRST strength? (not buried after sports)
□ Are risks real and specific (not "you should balance your course load")?
□ Does schoolsBestFit / schoolsGenuineReach reference actual schools from the student's list?
□ Does honestSummary contain student-specific data (actual GPA number, actual test score)?
□ Is the tone honest but constructive (not shame-based)?
```

**Severity:** Wrong leading strength = P1. Generic risks = P2.

---

### 2c — School Breakdown and Fit Categories

```
□ School breakdown counter (N Reach / N Target / N Safety) is non-zero and accurate?
□ normalizeFitCategory() was called — values are Title Case ('Reach', not 'reach')?
□ Schools in each category match the student's actual school list?
□ School-by-school strategy pages exist for all "My Schools" list entries?
□ Each school strategy mentions school-specific details (programs, culture, location)?
□ No school strategy is a copy of another school's strategy?
```

**Severity:** Zero breakdown counter = P1. Copy-paste strategies = P1.

---

### 2d — Financial Invariants

```
□ Net cost for every school is ≥ $0 (Math.max(0, ...) applied)?
□ The three budget scenarios (conservative/moderate/aggressive) show different values?
□ WUE discount only shown to students in WUE-eligible states at WUE-participating schools?
□ Non-resident scholarships excluded for in-state students?
□ Merit scholarship estimates are within the school's documented H2A range?
□ Pell Grant guidance only shown to students with income below the threshold?
```

**Severity:** Negative net cost = P1. Wrong WUE eligibility = P1. Three identical scenarios = P2.

---

### 2e — Scholarship Relevance

```
□ No residency-restricted scholarships shown to ineligible residents?
   (Check: scholarship_name + special_eligibility combined for "non-[state]", "out-of-state")
□ No activity-specific scholarships shown to students without the qualifying activity?
   (ROTC → no military activities, Costco → not a Costco employee, etc.)
□ normalizeScholarshipName() deduplicates singular/plural variants?
   ("National Merit Scholarship" and "National Merit Scholarships" → one entry)
□ Best single award shown per scholarship (not sum of multiple amounts)?
```

**Severity:** Wrong scholarship eligibility = P1. Duplicates = P2.

---

### 2f — Essay Prompt Filtering

```
□ filterEssayPromptsByMajor() applied at all 3 essay mapping sites in playbook-data route?
□ No nursing/pharmacy/BFA prompts shown to non-health/arts majors?
□ PROFESSIONAL_PROGRAM_PROMPT_PATTERNS regex covers the common professional programs?
□ If applicable_majors DB field is populated, it takes precedence over text patterns?
```

**Severity:** Wrong-major essay = P1.

---

### 2g — Action Plan Phase Correctness

```
□ For submitted Grade 12 seniors (application_status = 'submitted'):
   - isDecisionMode = true?
   - Plan shows 3-phase arc: "Evaluate Offers" → "Make Your Choice" → "Transition Planning"?
   - No junior-year tasks ("build your school list", "take the SAT for the first time")?

□ For Grade 11 juniors:
   - Plan shows appropriate junior tasks (testing, list building, campus visits)?
   - Action plan has a realistic 90-day horizon?

□ sortedAnchor uses scoreActivityImpact() (not totalHours × getDiffScore())?
   - A 20h/wk barista should NOT anchor the plan over a 5h/wk civic founder
```

**Severity:** Wrong phase tasks = P1. Wrong anchor activity = P1.

---

### 2h — Brag Sheet Quality

```
□ Activity descriptions are written out (not null/empty)?
□ synthesizeActivityDescription() called when impact_description is null?
□ deduplicateBragSheetActivities() called — no duplicate activity entries?
□ Story inventory WHAT HAPPENED / WHAT YOU LEARNED fields contain real text?
   (not template slots: "[describe the challenge]", "[describe your growth]")
□ Brag sheet activities match the student's entered activities (not hallucinated)?
```

**Severity:** Template placeholder slots = P1. Null descriptions = P1. Duplicates = P2.

---

### 2i — Recommender and Essay Strategy Differentiation

```
□ Recommender strategy references the student's actual teachers/advisors/activity context?
□ Recommender strategy is NOT identical boilerplate across multiple students?
   (Run /playbook-auditor compare to verify)
□ Essay approach provides specific advice (not "write about what matters to you")?
□ Essay angle references the student's actual strongest story, not a formula?
```

**Severity:** Identical boilerplate across students = P1. Generic formula = P2.

---

### 2j — PDF Rendering Completeness

```
□ "Strategic Positioning" section has real text (not placeholder)?
□ "Your Identity At This School" has real school-specific text (not garbled formatting)?
□ All activity bullets have description text (not blank second line)?
□ Phase 4 submission tasks include safety school (not only reach/target)?
□ PDF file size is realistic (>50KB for a full playbook, <500KB)?
□ No raw JSON or template variable syntax leaked into PDF output?
```

**Severity:** Placeholder in downloaded PDF = P1. Blank bullets = P2.

---

## Phase 3: Scoring

| Status | Meaning |
|--------|---------|
| ✅ Pass | Section is personalized and accurate |
| ⚠️ Warning | Generic but not incorrect |
| ❌ Fail — P1 | Wrong data shown, placeholder, or wrong student |
| 🔴 Fail — P0 | Financial data wrong sign, wrong student's data shown |

---

## Phase 4: Boilerplate Detection (for `/playbook-auditor compare`)

```
1. Extract variable sections from both playbooks:
   - strategicIdentity.summary
   - honestAssessment.honestSummary
   - recommenderStrategy text
   - essayApproach text
   - Each school's positioning paragraph

2. For each section pair, compute overlap:
   - Split into sentences
   - Count sentences that appear in both (case-insensitive)
   - If >50% of sentences match → flag as boilerplate (P1)
   - If >25% match → flag as warning (P2)

3. Report: "Recommender strategy for okafor and bjornson share 4/6 sentences — likely boilerplate"
```

---

## Common Failure Patterns

| Pattern | Symptom | Severity | Check |
|---------|---------|----------|-------|
| MAJOR BINDING directive missing | "The Civic Leadership Path" when student declared CS | P1 | 2a |
| Strategic Positioning placeholder | "See your full plan for details" in PDF | P1 | 2j |
| Template slots in story inventory | "WHAT HAPPENED: [describe...]" | P1 | 2h |
| Startup buried under varsity sport | Honest Assessment leads with athletics for a founder | P1 | 2b |
| Non-resident scholarship to WA resident | Scholarship shown that explicitly excludes WA residents | P1 | 2e |
| Nursing essay for pre-law student | filterEssayPromptsByMajor() not applied | P1 | 2f |
| Junior plan tasks for submitted senior | isDecisionMode not set from application_status | P1 | 2g |
| Barista anchors plan over civic founder | sortedAnchor still using hours × diffScore | P1 | 2g |
| Negative net cost | Missing Math.max(0,...) clamp | P1 | 2d |
| Three identical budget scenarios | Financial engine receiving same input for all three | P2 | 2d |
| Identical recommender strategy | PlaybookRecommenders not using student-specific context | P1 | 2i |
| Zero school breakdown counter | normalizeFitCategory() not called in buildSchoolList | P1 | 2c |

---

## Output Format

```
## Playbook Auditor: /playbook-auditor [mode] [target]

### Mode
[audit | validate | check | compare]

### Families / Artifacts Reviewed
[N families, N playbook artifacts]

### Findings
| Section | Check | Status | Issue |
|---------|-------|--------|-------|
| Strategic Identity | Major binding | ✅ Pass | — |
| Honest Assessment | Leading differentiator | ❌ P1 | Barista leads over startup founder |
| Financial | Net cost invariant | ✅ Pass | — |
| Action Plan | Phase correctness | ❌ P1 | Junior tasks shown to submitted senior |

### Issues Found
| Severity | Section | Family | Description | Root Cause |
|----------|---------|--------|-------------|------------|
| P1 | Honest Assessment | okafor | Barista leads over CivicTech startup | detectActivityStrengths checks varsity before startup |
| P1 | Action Plan | callahan | Junior tasks in 90-day plan | isDecisionMode not set for submitted application_status |

### Changes Made
(Only for fix mode)
| File | Action |
|------|--------|

### Summary
✅ [N] checks pass · ❌ [N] issues found · [N] filed as GitHub issues
Consultant parity: [N]% of sections are student-specific
```

---

## When to Escalate

Stop and ask if:
- A personalization failure would require a new DB column (e.g., storing activity impact metrics)
- The financial engine produces wrong values for a specific school combination (may be data issue)
- A placeholder section traces to a missing LLM output (prompt needs redesign)
- Boilerplate detection finds >70% similarity across ALL students (systemic prompt failure)

---

## Key References

- `src/lib/llm/strategic-identity.ts` — SYSTEM_PROMPT, MAJOR BINDING directive, tagline post-processor
- `src/lib/llm/action-plan-generator.ts` — isDecisionMode, phase-aware task generation
- `src/lib/llm/brag-sheet-generator.ts` — synthesizeActivityDescription, deduplicateBragSheetActivities
- `src/app/api/students/plan/playbook-data/route.ts` — data assembly, filterEssayPromptsByMajor, school breakdown
- `src/lib/plan/playbook-helpers.ts` — filterEssayPromptsByMajor generic helper, PROFESSIONAL_PROGRAM_PROMPT_PATTERNS
- `src/lib/plan/financial-fit.ts` — net cost calculation, Math.max(0,...) clamp
- `src/lib/plan/activity-engine.ts` — detectActivityStrengths, scoreActivityImpact
- `docs/DATA_FIELD_REFERENCE.md` — scholarship table schema, application_status values
- E2E output artifacts: `e2e/output/` — generated playbooks to validate against
