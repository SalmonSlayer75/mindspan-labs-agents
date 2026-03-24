# /ux-writer Skill

A standalone UI copy audit and writing skill for the project. Use this to systematically review every piece of user-facing text — button labels, error messages, empty states, tooltips, onboarding copy, financial disclaimers, and CTAs — for clarity, consistency, brand voice, and audience-appropriateness.

This skill answers the question: **"Does every word in the product earn its place and speak clearly to the right audience?"**

It does NOT cover:
- Page structure or navigation → use `/ux-ia-auditor`
- Visual design or typography → use `/designer`
- Code-level error handling → use `/frontend-auditor`

## Usage

```
/ux-writer audit              — Full copy audit across all pages and components
/ux-writer review [page]      — Audit copy on a specific page or flow
/ux-writer glossary            — Build the canonical product glossary
/ux-writer rewrite [file]     — Rewrite copy in a specific file for clarity and brand voice
```

---

## the project Copy Principles

Every piece of UI text must pass these tests. Violations are the #1 source of user testing feedback.

### Rule 1 — One Concept, One Name, Everywhere

The same feature or concept must use the same term across every page, tooltip, button, and message.

```
✅ CORRECT — consistent terminology:
  Sidebar: "My Schools"
  Dashboard card: "My Schools"
  Empty state: "You haven't added any schools to My Schools yet."
  Coach: "I see you have 5 schools in My Schools."
  Help article: "How to manage My Schools"

❌ WRONG — same concept, different names:
  Sidebar: "My Schools"
  Dashboard: "School List"
  Coach: "your saved schools"
  Help: "Favorites"
  → Users don't realize these refer to the same thing
```

---

### Rule 2 — No Jargon Without Explanation

Technical terms, acronyms, and industry shorthand must be either replaced with plain language or explained on first use. Remember: students are 16-17 year olds, parents may not have been through US college admissions.

```
✅ CORRECT — plain language or explained:
  "Estimated cost after scholarships" (not "Net Price")
  "EFC (Expected Family Contribution) — what FAFSA says your family can pay"
  "Common Data Set — the standardized report each college publishes"

❌ WRONG — unexplained jargon:
  "Your EFC is $45,000"
  "Based on CDS data"
  "COA minus institutional aid"
  "IPEDS-reported acceptance rate"
```

**the project jargon watchlist** — grep for these and ensure they're explained or replaced:
`EFC`, `COA`, `CDS`, `IPEDS`, `FAFSA`, `CSS Profile`, `SAI`, `WUE`, `RLS`, `merit grid`, `net price`, `sticker price`, `yield rate`, `holistic review`, `demonstrated interest`, `early action`, `early decision`, `rolling admission`, `binding`, `non-binding`

---

### Rule 3 — Brand Voice: Warm, Direct, Like a Knowledgeable Friend

the project speaks like a knowledgeable family friend — warm but honest, encouraging but never hype-y. See Brand Brief for full spec.

```
✅ CORRECT — brand voice:
  "Here's what the data shows about your chances at UW."
  "This is worth considering because merit aid could save you $8,000/year."
  "Your GPA opens doors at several strong schools."

❌ WRONG — too corporate:
  "Analysis indicates a favorable admissions probability."
  "Leveraging institutional aid optimization strategies..."

❌ WRONG — too hype:
  "AMAZING news! You're a PERFECT fit!!! 🎉"
  "You NEED to apply here NOW!!!"

❌ WRONG — too negative:
  "Unfortunately, your GPA makes this school impossible."
  "You're not competitive for this program."

✅ CORRECT — honest but kind:
  "With your current GPA, this school would be a reach. Here's what could change that."
  "This school's average admitted GPA is higher than yours — but they also value leadership, which is a strength for you."
```

---

### Rule 4 — Audience-Appropriate Language

Students (teens) and parents need different tones for the same information.

```
✅ CORRECT — student-facing:
  "Your next step: finish your activity list"
  "You've got 5 schools on your list"
  "Here's your plan"

✅ CORRECT — parent-facing:
  "Anna's next step: complete the activity list"
  "Your student has 5 schools on their list"
  "Anna's plan"

❌ WRONG — student language on parent page:
  "Your next step: finish your activity list" (on parent dashboard)
  → Parent thinks THEY need to do something

❌ WRONG — parent language on student page:
  "Your child's GPA" (on student profile)
  → Student finds this condescending/weird
```

---

### Rule 5 — Financial Copy Requires Disclaimers

Every financial figure must be marked as estimated, potential, or historical. Never present financial data as guaranteed.

```
✅ CORRECT — properly disclaimed:
  "Est. Merit: $5,000–$12,000/year"
  "Potential savings: up to $8,000/year with WUE"
  "Based on 2024-25 published rates. Actual costs may vary."
  "This school may offer merit scholarships for students with your profile."

❌ WRONG — presented as fact:
  "Merit scholarship: $8,000/year"
  "You will save $8,000 with WUE"
  "Total cost: $32,000/year"
  → Creates legal and trust risk
```

---

### Rule 6 — Error Messages Are Helpful, Not Technical

Error messages must tell users (1) what went wrong, (2) why, and (3) what to do next. Never show raw technical errors.

```
✅ CORRECT — helpful error:
  "We couldn't load your school list. This usually means a connection issue. Try again?"
  "That document format isn't supported. Please upload a PDF, PNG, or JPG."
  "We couldn't find that school. Check the spelling or try searching by city."

❌ WRONG — technical error:
  "Error: ECONNRESET"
  "Supabase storage error: bucket not found"
  "500 Internal Server Error"
  "TypeError: Cannot read properties of undefined"
```

---

### Rule 7 — Empty States Guide, Don't Abandon

Every empty state must (1) explain why it's empty, (2) tell the user what to do, and (3) use encouraging tone.

```
✅ CORRECT — guiding empty state:
  Title: "No schools yet"
  Body: "Start exploring schools that fit your profile. We'll help you find the right ones."
  CTA: "Browse Schools →"

❌ WRONG — abandoning empty state:
  "No data"
  "Nothing here"
  [blank page]
```

---

### Rule 8 — Button Labels Are Specific Actions

Buttons should say what they DO, not just generic words.

```
✅ CORRECT — specific button labels:
  "Save Changes" (not "Submit")
  "Add to My Schools" (not "Add")
  "Download Plan as PDF" (not "Download")
  "Ask Coach" (not "Send")
  "Start Onboarding" (not "Begin")
  "Compare These Schools" (not "Compare")

❌ WRONG — generic labels:
  "Submit"
  "OK"
  "Go"
  "Click here"
  "Continue" (without context of where)
```

---

## Phase 1: Copy Inventory

Before auditing, build a complete inventory of all user-facing text.

```
1. Scan all pages for text content:
   Glob: src/app/(app)/**/page.tsx
   Glob: src/app/(auth)/**/page.tsx
   Glob: src/components/**/*.tsx (exclude __tests__)

2. Categorize text by type:
   - Page titles and headings
   - Body/explanatory text
   - Button labels and CTAs
   - Form labels and descriptions
   - Error messages (toast, alert, inline)
   - Empty states
   - Tooltips (HelpTooltip content)
   - Loading text
   - Navigation labels (sidebar, breadcrumbs)
   - Financial figures and disclaimers
   - Coach-related copy
   - Onboarding instructions and prompts

3. Flag text that appears in multiple places (consistency check candidates)
```

---

## Phase 2: Audit Checks

### 2a — Terminology Consistency

```
Build a glossary by grepping for key terms and their variations:

□ School list naming: grep for "My Schools|School List|Saved Schools|Favorites|Your Schools"
□ Plan naming: grep for "Your Plan|My Plan|Strategic Plan|Playbook|Action Plan"
□ Onboarding naming: grep for "Phase|Step|Section|Stage" (for progress references)
□ Coach naming: grep for "Coach|AI Coach|Advisor|Assistant|Guide"
□ Financial naming: grep for "Cost|Price|Budget|Financial|Expense|Net Price"
□ Activity naming: grep for "Activities|Extracurriculars|Clubs|Involvement"
□ Application naming: grep for "Apply|Application|Submission|Deadline"

For each inconsistency found:
- List every file and line where each variant appears
- Recommend the canonical term
- Estimate scope of fix (how many files need updating)
```

**Severity:** Same concept with 3+ names = P1. Two variants = P2.

---

### 2b — Jargon Detection

```
Scan all user-facing text for unexplained jargon:

□ Financial: EFC, COA, CDS, FAFSA, CSS Profile, SAI, net price, sticker price
□ Admissions: yield rate, holistic review, demonstrated interest, EA, ED, rolling
□ Academic: weighted/unweighted GPA, AP, IB, dual enrollment, credit hours
□ Technical: any database, API, or code terms that leaked into UI
□ Acronyms: any uppercase abbreviation without parenthetical explanation

For each jargon instance:
- File and line number
- Surrounding context
- Suggested replacement or explanation
```

**Severity:** Financial jargon without explanation = P1. Academic jargon = P2. Technical leak = P1.

---

### 2c — Brand Voice Compliance

```
For each page, evaluate the overall tone:
□ Is the tone warm and direct? (not corporate, not hype, not clinical)
□ Are there any instances of:
  - "leverage", "optimize", "utilize", "facilitate" (corporate-speak)
  - ALL CAPS, excessive exclamation marks, emoji (hype)
  - "Unfortunately", "impossible", "can't" without alternative (negative)
  - Passive voice where active would be clearer
□ Does the text feel like it was written by a person? (not auto-generated boilerplate)
□ For coach-adjacent text: does it match the coach's voice?
```

**Severity:** Corporate-speak on student-facing page = P2. Negative/shaming language = P1. Hype language = P2.

---

### 2d — Audience Appropriateness

```
For student-facing pages (src/app/(app)/ excluding parent/):
□ Is language teen-appropriate? (clear, action-oriented, no talking down)
□ Does it use "you/your" (not "the student" or "your child")?
□ Are instructions short and scannable?
□ No condescending explanations of concepts teens already know?

For parent-facing pages (src/app/(app)/parent/):
□ Is language parent-appropriate? (monitoring-oriented, reassuring)
□ Does it use student's name or "your student" (not "you")?
□ Does it explain what the parent CAN do on this page?
□ Are financial concepts explained (parents may care more about ROI language)?

Cross-check:
□ No student language leaked into parent pages?
□ No parent language leaked into student pages?
```

**Severity:** Wrong audience language = P1. Minor tone mismatch = P2.

---

### 2e — Financial Disclaimer Compliance

```
For every page that shows dollar amounts, percentages, or financial estimates:
□ Is the figure prefixed with "Est.", "Estimated", "Potential", or "Approximate"?
□ Is there a "Based on [year] published rates" note?
□ Does merit scholarship language say "may offer" or "could qualify" (not "will receive")?
□ Is WUE savings gated on student having relevant WUE schools?
□ Are net price calculations clearly labeled as estimates?
□ Does the page include a financial disclaimer footer or tooltip?

Grep targets:
  grep for '\$[0-9]' in src/components/ and src/app/ (find all dollar amounts)
  Verify each one has disclaimer context
```

**Severity:** Financial figure without disclaimer = P1. Missing estimate prefix = P1.

---

### 2f — Error Message Quality

```
For every error message in the codebase:
□ Does it tell the user what happened? (not just "Error")
□ Does it suggest what to do? ("Try again", "Check your connection", "Contact support")
□ Is it free of technical details? (no error codes, stack traces, API paths)
□ Is the tone appropriate? (not alarming, not dismissive)
□ For form validation: does it tell the user what's expected? ("Enter a GPA between 0.0 and 4.0")

Grep targets:
  grep for "toast\(" — check all toast messages
  grep for "setError\(" — check all error state text
  grep for "throw new Error\(" — check error message content
  grep for "variant.*destructive" — check destructive toast messages
  grep for "alert\|Alert" — check alert component text
```

**Severity:** Technical error shown to user = P1. Unhelpful error ("Something went wrong") = P2.

---

### 2g — Empty State Quality

```
For every component/page that displays data:
□ What text appears when there's no data?
□ Does it explain WHY there's no data?
□ Does it tell the user what to do to populate it?
□ Does it include a CTA (button or link)?
□ Is the tone encouraging? (not "No data found")

Grep targets:
  grep for "no data|nothing here|no results|empty|not found" in src/components/
  grep for "no schools|no activities|no plan|no messages" in src/
  Identify components with conditional rendering that might show blank on empty
```

**Severity:** No empty state text = P1 (covered by `/ux-ia-auditor`). Poor empty state copy = P2.

---

### 2h — Button and CTA Clarity

```
For every button and link in the product:
□ Does the label describe the action? (not "Submit", "OK", "Go")
□ Is the label consistent with similar actions on other pages?
□ For destructive actions: does the label make the consequence clear?
  ("Delete School" not just "Delete")
□ For navigation: does the label say where it goes?
  ("Back to Schools" not just "Back")
□ Are paired buttons clear about which is primary and which is secondary?
  ("Save Changes" + "Cancel" not "Yes" + "No")
```

**Severity:** Generic "Submit" on critical form = P2. Destructive action with ambiguous label = P1.

---

## Phase 3: Deliverables

### The Product Glossary

Every audit should produce or update the canonical glossary:

```markdown
# the project Product Glossary

## Canonical Terms (ALWAYS use these)
| Term | Meaning | Never Say Instead |
|------|---------|-------------------|
| My Schools | Student's chosen school list | School List, Saved Schools, Favorites |
| Your Plan | Personalized strategic plan | Playbook, Strategy, Action Plan |
| Coach | AI planning advisor | AI Coach, Assistant, Advisor, Bot |
| Fit Score | How well a school matches the student | Match Score, Compatibility |
| ...  | ... | ... |

## Financial Terms (require disclaimers)
| Term | Required Context |
|------|-----------------|
| Merit Aid | "Est. Merit:", "may offer", "based on [year] data" |
| Net Price | "Estimated net price", "after estimated aid" |
| WUE Savings | Only shown when student has WUE-eligible schools |
| ... | ... |

## Terms That Need Explanation (first use)
| Acronym | Full Form | Context |
|---------|-----------|---------|
| EFC | Expected Family Contribution | What FAFSA calculates your family can pay |
| CDS | Common Data Set | Standardized report each college publishes |
| ... | ... | ... |
```

---

## Output Format

```
## UX Writer: /ux-writer [mode] [target]

### Mode
[audit | review | glossary | rewrite]

### Scope
[N pages, N components, N text instances reviewed]

### Product Glossary
[Full glossary or link to generated file]

### Findings
| Severity | Rule | File | Text Found | Recommendation |
|----------|------|------|------------|----------------|
| P1 | R1 | SchoolCard.tsx | "Saved Schools" | Change to "My Schools" |
| P1 | R2 | FinancialSection.tsx | "Your EFC is $45K" | Add explanation: "EFC (Expected Family Contribution)" |
| P1 | R5 | MeritTable.tsx | "Merit: $8,000/year" | Add "Est." prefix |
| P2 | R3 | plan/page.tsx | "Optimize your approach" | Rewrite: "Here's how to strengthen your application" |

### Copy Rewrites (for /ux-writer rewrite mode)
| File | Line | Before | After |
|------|------|--------|-------|
| ... | ... | ... | ... |

### Issues Filed
| # | Title | Severity | Labels |
|---|-------|----------|--------|
| ... | ... | ... | ux, copy, P1/P2 |

### Summary
📝 Text instances reviewed: [N]
🔴 P1 copy issues: [N]
⚠️ P2 copy issues: [N]
📖 Glossary terms defined: [N]
✅ Terminology consistency: [X]% (unique terms / total term uses)
```

---

## When to Escalate

Stop and discuss with the user if:
- A terminology change would affect 20+ files
- Financial disclaimer changes might affect legal compliance
- Copy changes would require updating help articles, tours, or coach prompts simultaneously
- Brand voice issues suggest the Brand Brief itself needs updating

---

## Key References

- Brand Brief: https://www.notion.so/2ee65d2ef8aa81589e1edb97d43799c2
- `/ux-ia-auditor` check 2e — Copy & Terminology Consistency (IA-level review)
- `/designer` — Brand voice reference (visual + verbal)
- `src/components/ui/HelpTooltip.tsx` — Contextual help text
- `src/lib/tours/*.ts` — Tour step copy
- User testing Sprint 1 findings — PR #1744 (copy issues that prompted this skill)
