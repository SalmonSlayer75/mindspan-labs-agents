# /run-e2e Skill

Runs one full E2E cycle using the 3-family rotating approach:
- **Family A + B**: Two existing families selected for regression coverage (rotation avoids recent runs)
- **Family C**: One brand-new persona that fills a coverage gap

After running the tests, downloads and reviews PDF exports, then logs any bugs or quality issues as GitHub issues.

## Usage

```
/run-e2e
```

No arguments needed. The skill reads run-history.json to determine the run number and recent family slugs automatically.

---

## Phase 1: Family Selection

### 1a. Read run context

```
1. Read e2e/families/run-history.json
   - Get nextRunNumber
   - Get recentControlSlugs (last 2 runs' A+B families)
2. Read e2e/families/roster.ts
   - Get ROSTER (all existing families)
   - Get COVERAGE_GAPS (dimensions not yet tested)
```

### 1b. Select A+B control families

Apply suggestControlPair() logic from roster.ts:
1. Filter out families in recentControlSlugs
2. Require both families to have a parent linked (catches parent-path regressions)
3. Pick a pair with different academicStrength values
4. Pick a pair with different linkDirection (one A, one B)
5. Pick a pair with different financialTier if possible

State your selection with rationale before proceeding:
```
Control A: hendricks — mid/A/dead-zone/military
Control B: garcia — strong/B/need-eligible/DACA
Rationale: Academic mid+strong, Link A+B, Financial dead-zone+need-eligible, avoids park/morrison/washington
```

### 1c. Design Family C (new persona)

Design a persona that fills the highest-priority gap from COVERAGE_GAPS. As of Run 9, priorities are:
1. `journeyPhase:early` — Grade 9–10 student (no data yet, tests minimal-data experience)
2. `familyStructure:student-only` — no parent account
3. `journeyPhase:late` — Grade 12 application-season student

Choose a realistic WA student with:
- A specific high school in Washington state
- Plausible GPA and test scores for their academic tier
- 3–5 activities with concrete details (not generic)
- 3 schools on their list (Reach / Target / Safety)
- Specific coach questions tied to their situation

**Diversity within the dimension covered:** Vary academic strength, financial tier, and family structure from other recent families.

### 1d. Create persona file

```
1. Copy e2e/families/personas/_template.ts → e2e/families/personas/<slug>.ts
2. Fill in all fields (both provisionConfig and the commented-out PersonaFamily block)
3. Verify TypeScript compiles: npx tsc --noEmit
```

### 1e. Provision auth accounts + DB records

```
npx tsx scripts/create-synthetic-family.ts <slug>
```

For staging only: `TARGET=staging npx tsx scripts/create-synthetic-family.ts <slug>`

**What this script provisions** (required for new accounts to pass middleware gates):
1. **Supabase auth accounts** — student (+ parent if configured)
2. **`user_profiles`** — required by `getUserRole()` in every API route (returns 403 if missing)
3. **`consent_records`** — ToS + Privacy Policy rows required by middleware (returns 403 for ALL API calls if missing)
4. **`age_verifications`** — required by middleware for student API calls (COPPA check, returns 403 if missing)

**If a new family still gets HTTP 403 after provisioning**, check these in order:
```sql
-- 1. Does user_profiles row exist?
select * from user_profiles where user_id = '<student-uuid>';

-- 2. Do both consent records exist?
select consent_type from consent_records where user_id = '<student-uuid>' and revoked_at is null;

-- 3. Does age_verifications row exist?
select * from age_verifications where user_id = '<student-uuid>';
```
If any are missing, the script can be re-run safely — it upserts profiles, deduplicates consents, and skips existing age records.

### 1f. Wire Family C into the test spec

Add the new PersonaFamily object to the `FAMILIES` array in `e2e/family-synthetic-test.spec.ts`.
Place it last in the array (after the existing 12 families).

---

## Phase 2: Run E2E Test

Run the 3 selected families using the `E2E_FAMILIES` env var:

```bash
# Replace slugs with the actual A/B/C slugs
E2E_FAMILIES="<slugA>,<slugB>,<slugC>" \
npx playwright test e2e/family-synthetic-test.spec.ts \
  --reporter=list \
  --timeout=180000
```

**Guard**: The spec refuses to run without `E2E_FAMILIES` set (prevents accidental full-roster runs of all 24 families). Maximum 5 families per run unless `E2E_RUN_ALL=1` is set.

### Capture results per family

For each family, track:
- Phase 1 (data seeding): pass / fail / partial
- Phase 2 (content generation + assertions): pass / fail / partial
- Student coach questions: answered / timeout / error
- Parent coach questions: answered / 404 / timeout / error
- Brag sheet: generated / HTTP 500 / cached
- Playbook: generated / error
- PDF export: success / fail
- Overall: ✅ pass | ❌ fail | ⚠️ partial

---

## Phase 3: Download PDF Exports

After the E2E test completes, download the Playbook PDF and Resume PDF for each of the 3 families.

### Download approach

Run the PDF download spec restricted to the 3 families:

```bash
PDF_RUN_LABEL="run-<N>" \
PDF_BUILD_HASH="$(git rev-parse --short HEAD)" \
npx playwright test e2e/download-pdfs.spec.ts \
  --grep "<slugA>|<slugB>|<slugC>" \
  --reporter=list
```

(The download spec uses `--grep` since it has its own PERSONAS list, separate from the family guard.)

**Note**: If the E2E families are not in `download-pdfs.spec.ts` PERSONAS list, add them temporarily:
```typescript
{ slug: '<slug>', email: '<student-email>' },
```
Use `FamilyTest2026!` as the password (change the PASSWORD const at top of file if needed, or add a per-persona password field).

PDFs will be saved to `output/pdfs/`.

---

## Phase 4: PDF Quality Review

Read each downloaded PDF and evaluate against these criteria.

### For each Playbook PDF — 10-Factor Quality Rubric

Score each factor 1–5. Overall rating = average across all 10 factors (rounded to nearest 0.5).

| # | Factor | What to evaluate | Score |
|---|--------|-----------------|-------|
| 1 | **Personalization** | References THIS student's specific activities, goals, major, school list — not generic advice that could apply to anyone | /5 |
| 2 | **Accuracy** | GPA, test scores, school data, acceptance rates, deadlines are correct; no data from a different student (cross-contamination) | /5 |
| 3 | **Completeness** | All expected sections present (Honest Assessment, school-by-school, financial, action plan); no blank sections, truncated text, or placeholder slots like "[SCHOOL NAME]" | /5 |
| 4 | **Strategic Fit Assessment** | Like a human coach — considers all relevant factors (academic match, extracurricular alignment, family context, financial situation, geographic preferences) to make holistic, school-specific strategic recommendations | /5 |
| 5 | **Balanced & Critical Feedback** | Delivers honest assessment — flags risks, identifies weaknesses, doesn't sugarcoat low admission chances; praises genuine strengths without being a generic cheerleader | /5 |
| 6 | **Financial Awareness** | Cost analysis reflects actual family income tier; scholarships are relevant to this student; net price is realistic (not negative); need-based vs merit advice is income-appropriate | /5 |
| 7 | **Actionability** | Next steps are concrete, time-bound, and specific enough that the student can actually execute them this week — not vague "consider researching..." | /5 |
| 8 | **School-Specificity** | Each school section reflects that school's unique culture, programs, values, and admissions personality — not boilerplate repeated across schools | /5 |
| 9 | **Formatting & Polish** | Professional appearance; no rendering artifacts, mid-sentence cutoffs, or garbled text; clean tables, consistent heading hierarchy; PDF looks premium | /5 |
| 10 | **Overall Consultant Parity** | Would a $10K human consultant produce meaningfully better advice for this student? 5 = "no, this matches or exceeds"; 1 = "yes, a human would be dramatically better" | /5 |

#### Score interpretation

| Average | Rating | Meaning | Action |
|---------|--------|---------|--------|
| **4.5–5.0** | Exceptional | Consultant-quality, highly personalized, genuinely useful | No issues to file |
| **3.5–4.4** | Strong | Specific and accurate with minor gaps | File P2 for gaps |
| **2.5–3.4** | Acceptable | Functional but some generic or missing sections | File P2 for each gap |
| **1.5–2.4** | Needs Work | Generic, inaccurate, or poorly formatted | File P1 per finding |
| **1.0–1.4** | Broken | Error, blank, or major structural failure | File P0/P1 immediately |

#### Red flags (auto-file P1 regardless of average score)

- Any factor scored 1 = automatic P1 issue for that factor
- Cross-contamination (wrong student's data) = P0
- Blank or error PDF = P0

### For each Resume (Brag Sheet) PDF

**Completeness**:
- [ ] All activities listed with descriptions
- [ ] Awards/recognition present where applicable
- [ ] Contact/header info present
- [ ] No blank sections

**Quality**:
- [ ] Descriptions are specific and achievement-focused (not just "participated in...")
- [ ] Language is polished, not generic
- [ ] Appropriate length (not padded, not truncated)

**Formatting**:
- [ ] Clean layout, no overflow or clipping
- [ ] Consistent spacing
- [ ] Professional appearance

### Resume rating scale

| Score | Rating | Action |
|-------|--------|--------|
| **5** | Exceptional — polished, achievement-focused, professional | None |
| **4** | Strong — minor wording or formatting polish needed | P2 |
| **3** | Acceptable — functional but generic descriptions | P2 |
| **2** | Needs Work — missing sections, vague content | P1 |
| **1** | Broken — blank, error, or major structural failure | P0/P1 |

---

## Phase 5: Log GitHub Issues

For every problem found (in E2E results OR PDF review), file a GitHub issue.

### Issue creation pattern

Use the standardized 8-section template (`.github/ISSUE_TEMPLATE/bug_report.md`).
E2E issues are **discovery issues** — sections 2–8 may be "TBD — fill before implementation."
The E2E context block (run number, family, repro steps) goes in section 1 as evidence.

```bash
gh issue create \
  --title "[Area] Run <N>/<slug>: <problem description>" \
  --body "$(cat <<'EOF'
**Severity:** P0 / P1 / P2
**Found by:** /run-e2e run #<N> (2026-XX-XX)
**File(s):** TBD — identify before implementation

## 1. Root Cause

**What failed at the system level?**
[One paragraph: what failed, in which family, in which phase]

**E2E Run Context:**
- Run: #<N> (2026-XX-XX)
- Family: <slug> (<one-liner from roster>)
- Phase: Phase 2 / PDF review / E2E test

**Steps to reproduce:**
1. [Step]
2. [Step]

**Expected:** [What should happen]
**Actual:** [What actually happened — paste exact error or quote from PDF]

**Why did existing guardrails/tests not catch it?**
TBD

## 2. Proposed Fix
TBD — fill before implementation

## 3. Scope / Non-Goals
TBD — fill before implementation

## 4. Affected Files / Interfaces / Data
TBD — fill before implementation

## 5. Security / Privacy Checks
N/A (unless flagged)

## 6. Test Plan
TBD — fill before implementation

## 7. Rollout + Rollback
TBD — fill before implementation (if DB/auth/perf change)

## 8. Ownership + Execution
**Owner:** Claude Code
**Definition of done:**
- [ ] Code merged
- [ ] Tests merged and passing
- [ ] Staging verified
- [ ] Production verification complete
EOF
)" \
  --label "bug,P1"
```

### Priority guidelines

| Severity | Label | Examples |
|----------|-------|---------|
| Critical | `P0,bug` | HTTP 500, coach returning wrong student's data, coach 404 |
| High | `P1,bug` | Timeout, brag sheet 500, PDF blank, major content error |
| Medium | `P2,bug` | Generic instead of specific recommendations, minor formatting issues |
| Low | `P2,enhancement` | Polish improvements, wording suggestions |
| Deferred | `P2,post-beta` | Nice-to-have improvements not blocking launch |

### What to file vs. what to skip

**Always file:**
- HTTP 5xx errors
- Wrong data / cross-contamination between students
- Broken PDF (blank, error, won't download)
- Playbook sections missing entirely
- Coach returning "I don't have access" when it should have access

**File if consistent across 2+ families:**
- Generic recommendations (not family-specific)
- Missing school-specific details in playbook

**Skip or note informally:**
- Subjective tone differences
- Minor formatting preferences
- One-off wording that could go either way

---

## Phase 6: Update Records

### 6a. Update run-history.json

Add a new entry for this run:

```json
{
  "runNumber": <N>,
  "date": "<YYYY-MM-DD>",
  "approach": "3-family (controlA + controlB + new)",
  "controlA": "<slugA>",
  "controlB": "<slugB>",
  "newFamily": "<slugC>",
  "familiesRun": ["<slugA>", "<slugB>", "<slugC>"],
  "codeState": "post-R<NN>",
  "results": {
    "bragSheet": "<pass/fail/partial — one line>",
    "coachStudent": "<pass/fail/partial>",
    "parentCoach": "<pass/fail/partial>",
    "playbook": "<pass/fail/partial>",
    "pdfExports": "<pass/fail/partial>"
  },
  "issuesFiled": [<issue numbers>],
  "notes": "<one paragraph summary>"
}
```

Update `nextRunNumber` and `rotationGuidance.recentControlSlugs`.

### 6b. Add Family C to roster.ts

Append to the ROSTER array in `e2e/families/roster.ts`:

```typescript
{
  slug: '<slugC>',
  studentEmail: '<email>',
  parentEmail: '<email or null>',
  academicStrength: '<tier>',
  financialTier: '<tier>',
  journeyPhase: '<early|mid|late>',
  familyStructure: '<structure>',
  linkDirection: '<A|B|null>',
  notableFeatures: ['<feature-1>', '<feature-2>'],
  oneLiner: '<Student Name> — one-sentence description',
},
```

Update `COVERAGE_GAPS` if the new family fills one of the listed gaps.

### 6c. Commit

Stage and commit all changes:
```bash
git add e2e/families/personas/<slugC>.ts
git add e2e/families/run-history.json
git add e2e/families/roster.ts
git add e2e/family-synthetic-test.spec.ts
# Commit new family + run history + roster
git commit -m "e2e: Run <N> — <slugA>/<slugB>/<slugC> results + new <slugC> persona"
```

Then commit any bug fixes separately (fix: commits), then push.

---

## Phase 7: Run Report

Produce a summary for the user:

```
## E2E Run <N> Report — <DATE>

### Families
| Role | Slug | Academic | Financial | Structure |
|------|------|----------|-----------|-----------|
| Control A | <slug> | <str> | <tier> | <str> |
| Control B | <slug> | <str> | <tier> | <str> |
| New (C) | <slug> | <str> | <tier> | <str> |

### Test Results
| Family | Ph1 Seed | Ph2 Content | Coach(S) | Coach(P) | Brag | Playbook | PDF |
|--------|----------|-------------|----------|----------|------|----------|-----|
| <slug> | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| <slug> | ✅ | ⚠️ | ❌ | — | ✅ | ✅ | ✅ |
| <slug> | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### Playbook Quality (5-Star Rubric)

| Factor | <slugA> | <slugB> | <slugC> |
|--------|---------|---------|---------|
| 1. Personalization | /5 | /5 | /5 |
| 2. Accuracy | /5 | /5 | /5 |
| 3. Completeness | /5 | /5 | /5 |
| 4. Strategic Fit | /5 | /5 | /5 |
| 5. Balanced & Critical | /5 | /5 | /5 |
| 6. Financial Awareness | /5 | /5 | /5 |
| 7. Actionability | /5 | /5 | /5 |
| 8. School-Specificity | /5 | /5 | /5 |
| 9. Formatting & Polish | /5 | /5 | /5 |
| 10. Consultant Parity | /5 | /5 | /5 |
| **Average** | **/5** | **/5** | **/5** |
| **Rating** | | | |

### Resume Quality
| Family | Score | Key Notes |
|--------|-------|-----------|
| <slug> | /5 | |
| <slug> | /5 | |

### Issues Filed
| # | Severity | Description |
|---|----------|-------------|
| #NNN | P1 | Coach timeout — <slug> |
| #NNN | P2 | Brag sheet activity descriptions generic |

### Delta vs. Run <N-1>
- [Regressions since last run]
- [Improvements since last run]
- [No change in]

### Coverage Added
- New gap filled: <dimension>
- Remaining gaps: [list]

### Next Run Guidance
- Avoid as controls: <slugA>, <slugB>, <slugC>
- Suggested new family: <dimension to fill>
```

---

## Checklist

- [ ] Run number read from run-history.json
- [ ] Control pair selected with rationale (avoids recent runs, parent linked, diverse)
- [ ] New family designed and fills a coverage gap
- [ ] Persona file created and TypeScript-clean
- [ ] Auth accounts provisioned (student + parent) AND DB records created (user_profiles, consent_records, age_verifications)
- [ ] Family C added to FAMILIES array in spec
- [ ] E2E test run for all 3 families
- [ ] PDF exports downloaded for all 3 families
- [ ] Each PDF reviewed against quality criteria and rated
- [ ] GitHub issues filed for all bugs and quality failures
- [ ] run-history.json updated with results and nextRunNumber incremented
- [ ] roster.ts ROSTER updated with Family C
- [ ] COVERAGE_GAPS updated if a gap was filled
- [ ] All changes committed
- [ ] Run report presented to user
- [ ] memory/MEMORY.md updated with current state
