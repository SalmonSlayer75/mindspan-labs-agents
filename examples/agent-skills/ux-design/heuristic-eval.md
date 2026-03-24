# /heuristic-eval Skill

A page-by-page heuristic evaluation skill for the project using Nielsen's 10 Usability Heuristics. Use this as a **fast, lightweight quality gate** before merging new pages or after significant UI changes.

`/ux-ia-auditor` evaluates the **overall structure** (navigation, IA, journeys).
This skill evaluates the **interaction quality of individual pages** against industry-standard heuristics.

Think of it this way: `/ux-ia-auditor` is the city planner (are the roads in the right places?). `/heuristic-eval` is the building inspector (does each building work well?).

## Usage

```
/heuristic-eval audit                 — Evaluate all pages against Nielsen's 10 heuristics
/heuristic-eval page [path]           — Evaluate a specific page
/heuristic-eval compare [p1] [p2]     — Compare two pages for consistency
/heuristic-eval new [path]            — Pre-merge quality gate for a new page
```

---

## Nielsen's 10 Usability Heuristics (Adapted for the project)

### H1 — Visibility of System Status

The system should always keep users informed about what is going on, through appropriate feedback within reasonable time.

```
CHECK:
□ Loading states visible? (skeleton, spinner, progress bar)
□ Save/submit confirmation shown? (toast, visual change)
□ Progress indicators on multi-step flows? (step X of Y)
□ Active navigation item highlighted?
□ Data freshness communicated? ("Updated 2 hours ago", "As of 2024-25 data")
□ Generation status for LLM operations? ("Generating your plan..." with progress)
□ Upload progress shown? (percentage, bytes transferred)

the project SPECIFICS:
□ Onboarding: does the user know which phase they're on and how many remain?
□ Plan generation: can the user tell it's working, or does it look frozen?
□ School data: is it clear when data is loading vs. when it's not available?
□ Coach: is the typing indicator visible? Does the user know the coach is thinking?
□ **Journey Status (Now/Next/Later)**: Beyond loading states, does the user clearly see where they stand in their overall journey, giving them confidence they have a comprehensive, sequenced plan?
```

**Severity:** No loading state on > 1s operation = P1. No progress on > 5s operation = P2.

---

### H2 — Match Between System and Real World

The system should speak the users' language, with words, phrases, and concepts familiar to the user, rather than system-oriented terms.

```
CHECK:
□ Labels use everyday language? (not database column names)
□ Icons match real-world meaning? (trash = delete, bookmark = save)
□ Metaphors are consistent? (if "My Schools" is a list, it should look/act like a list)
□ Date formats are localized? (March 15, 2026 — not 2026-03-15)
□ Numbers are human-readable? ($45,000 — not 45000)
□ Sort orders match expectation? (A-Z, newest-first, highest-score-first)
□ **Reassurance Check**: Is the tone empathetic, celebrating wins and softening bad news?
□ **Confidence-Building (Dual-Role)**: Does the UI provide the "so what?" (insights) and "what now?" (actions) rather than just raw data, ensuring BOTH the student and parent feel empowered and see the platform's personalized value?

the project SPECIFICS:
□ College admissions terms explained? (see /ux-writer jargon watchlist)
□ Financial figures feel real-world? (annual cost, not per-credit-hour)
□ Phase names match student's mental model? ("Junior Year Planning" not "Phase 4")
□ Fit scores explained? (what does 85/100 MEAN in practical terms?)
□ **Anxiety Reduction**: Are "Reach" schools or warning states presented with constructive, supportive messaging rather than harsh, panic-inducing visuals (e.g., amber instead of red)?
□ **Student Empowerment**: Do we celebrate strengths and provide clear, achievable actions for gaps?
□ **Parent Confidence**: Do we provide the parent with valuable, actionable insights (e.g., financial planning steps, ways to support the student) rather than just a read-only mirror of the student's data?
```

**Severity:** Database term in UI = P1. Unexplained score/metric = P2.

---

### H3 — User Control and Freedom

Users often choose system functions by mistake and need a clearly marked "emergency exit" to leave the unwanted state.

```
CHECK:
□ Can the user undo recent actions? (remove school after adding)
□ Can the user go back? (back button, breadcrumb, nav link)
□ Can the user cancel mid-operation? (cancel generation, cancel upload)
□ Can the user dismiss modals/dialogs? (X button, Escape key, click outside)
□ Can the user edit after saving? (not locked in after submit)
□ Can the user skip optional steps? (clear "Skip" option)
□ Is there a way to reset/start over? (if the user wants to re-do onboarding)

the project SPECIFICS:
□ Can a student remove a school from "My Schools" easily?
□ Can a student go back to a previous onboarding phase?
□ Can a parent "unlink" from a student?
□ Can a user dismiss the coach's suggestions?
□ Can a user re-generate their plan if they don't like it?
```

**Severity:** No cancel on destructive action = P1. Can't go back in multi-step flow = P1. No edit after save = P2.

---

### H4 — Consistency and Standards

Users should not have to wonder whether different words, situations, or actions mean the same thing.

```
CHECK:
□ Same action, same button style? (all primary actions use Button variant="default")
□ Same type of data, same display format? (all dates, all dollar amounts, all scores)
□ Same position for common elements? (save button always bottom-right, or always top-right)
□ Same terminology throughout? (see /ux-writer Rule 1)
□ Same interaction pattern for similar features? (all cards click the same way)
□ Platform conventions followed? (links look like links, buttons look like buttons)

the project SPECIFICS:
□ All school cards look and work the same across pages?
□ All forms follow the same layout pattern? (label → input → description → error)
□ All loading states use the same skeleton pattern?
□ All error states use the same Alert variant?
□ "My Schools" / "Exploring" / "Not Interested" badges consistent everywhere?
```

**Severity:** Critical inconsistency (button does different things on different pages) = P1. Visual inconsistency = P2.

---

### H5 — Error Prevention

Even better than good error messages is a careful design which prevents a problem from occurring in the first place.

```
CHECK:
□ Confirmation on destructive actions? ("Are you sure you want to remove this school?")
□ Input constraints enforce valid data? (GPA max 4.0, date picker instead of free text)
□ Duplicate prevention? (can't add same school twice to list)
□ Clear indication of required vs. optional fields?
□ Auto-save or draft preservation? (form data not lost on navigation)
□ Disabled states for invalid operations? (can't compare with < 2 schools)
□ **Privacy Visibility**: When asking for sensitive data, is it proactively explained *why* it's needed and *who* sees it?

the project SPECIFICS:
□ Can a student accidentally delete their entire school list?
□ Can a student submit onboarding with critical fields empty?
□ Can a parent accidentally see another family's data?
□ Does the system prevent submitting an incomplete plan for PDF generation?
□ **Data Trust**: Are there visual cues (tooltips, lock icons) near GPA, test scores, or financial info explaining privacy boundaries?
```

**Severity:** No confirmation on data-loss action = P1. No input constraint on critical field = P2.

---

### H6 — Recognition Rather Than Recall

Minimize the user's memory load by making objects, actions, and options visible.

```
CHECK:
□ Important options are visible, not hidden in menus?
□ Recently used items are accessible? (recent searches, recently viewed schools)
□ Labels are on visible elements (not just tooltips or hover states)?
□ Complex fields have examples or placeholders?
□ Users can see their selections without remembering them? (school list visible)
□ Navigation is always visible? (sidebar, not just hamburger on desktop)
□ **Contextual Relevance**: Does the UI anticipate user needs based on their timeline or state?

the project SPECIFICS:
□ Can the user see which schools are on their list without navigating to the schools page?
□ Can the user see their profile data without going to settings?
□ Is the current onboarding phase visible from any onboarding page?
□ Can the user see their plan highlights from the dashboard?
□ **Anticipatory UI**: If it's Fall of Senior year, are deadlines front and center? Does the dashboard dynamically reflect the user's critical path?
```

**Severity:** Important feature hidden behind 3+ clicks = P2. Critical info requires recall = P1.

---

### H7 — Flexibility and Efficiency of Use

Accelerators — unseen by the novice user — may speed up the interaction for the expert user.

```
CHECK:
□ Keyboard shortcuts for common actions? (Tab through forms, Enter to submit)
□ Search available where appropriate? (school search)
□ Filters and sorting available on lists?
□ Quick actions available? (add to list from search results, not just detail page)
□ Bulk operations available where appropriate? (select multiple schools to compare)
□ Deep links work? (can the user bookmark a specific school or plan section)
□ **Actionability & Sequencing**: Are actions clearly sequenced (e.g., "Now, Next, and Later") so the user feels they have a comprehensive plan without being overwhelmed by doing everything at once?

the project SPECIFICS:
□ Can a user add a school directly from search results?
□ Can a user quickly switch between school lists (My/Exploring/Not Interested)?
□ Can a user jump to a specific plan section from the dashboard?
□ Can a parent quickly switch between students (if multiple)?
□ **Next Steps (Student)**: When reading the Plan, is it painfully obvious what the student's very next physical action is?
□ **Next Steps (Parent)**: Does the parent have clear, parent-specific actions to take (e.g., "Review Financials", "Discuss target list")?
```

**Severity:** No search on large list = P2. No keyboard navigation on forms = P2.

---

### H8 — Aesthetic and Minimalist Design

Every extra unit of information in an interface competes with the relevant units of information and diminishes their relative visibility.

```
CHECK:
□ Only essential information visible by default?
□ Secondary info available via expand/collapse, tabs, or detail pages?
□ Visual noise minimized? (no unnecessary borders, dividers, backgrounds)
□ White space used effectively to group related items?
□ No redundant information on the same page?
□ Charts/graphs simplified to their key message?
□ **Data Visualization Check**: Could a text-heavy paragraph be replaced by a chart, progress ring, or badge for scannability?

the project SPECIFICS:
□ School card: does it show only what's needed to decide (name, fit, cost)?
□ Plan page: are secondary sections collapsed by default?
□ Dashboard: is it focused on the ONE most important thing?
□ Compare page: is it scannable or overwhelming?
□ **Financial/Probability Data**: Are we forcing users to read tables, or providing visual summaries?
```

**Severity:** Page with 15+ undifferentiated items = P1. Redundant info = P2.

---

### H9 — Help Users Recognize, Diagnose, and Recover from Errors

Error messages should be expressed in plain language, precisely indicate the problem, and constructively suggest a solution.

```
CHECK:
□ Error messages in plain language? (not error codes)
□ Error messages indicate WHAT went wrong specifically?
□ Error messages suggest HOW to fix it?
□ Error messages are visually appropriate? (red for errors, amber for warnings)
□ Recovery is possible? (retry button, fix input, go back)
□ User's work is preserved after error? (form data not cleared)

(This overlaps with /error-ux-auditor — reference that skill for deep error analysis)
```

**Severity:** Technical error message = P1. No recovery path = P1.

---

### H10 — Help and Documentation

Even though it is better if the system can be used without documentation, it may be necessary to provide help.

```
CHECK:
□ Help accessible from every page? (sidebar link, floating button)
□ Contextual help available? (HelpTooltip near complex features)
□ Guided tours for first-time users? (useTour integration)
□ Coach positioned as an always-available help resource?
□ Help content is searchable?
□ Help articles relevant to the current page context?
□ Help content up-to-date with current UI?

the project SPECIFICS:
□ HelpTooltips present on financial metrics, fit scores, and complex fields?
□ Tours available for dashboard, plan, schools, parent pages?
□ Coach Help tab visible and functional?
□ Help center articles cover all major features?
```

**Severity:** No help on complex feature = P2. Help content out of date = P2. No help system at all = P1.

---

## Phase 1: Page Selection

```
For /heuristic-eval audit:
1. List all pages: Glob src/app/(app)/**/page.tsx
2. Prioritize by user importance:
   - Tier 1 (evaluate first): Dashboard, Plan, Schools, Onboarding phases
   - Tier 2: School detail, Compare, Coach, Settings
   - Tier 3: Help, Documents, Parent pages

For /heuristic-eval page [path]:
1. Read the specific page file
2. Read related components imported by the page
3. Check for associated layout.tsx (navigation context)
```

---

## Phase 2: Evaluate Each Page

For each page, score against all 10 heuristics:

```
PAGE: [page name] — [route path]

| Heuristic | Score | Finding |
|-----------|-------|---------|
| H1 System Status | 4/5 | Loading skeleton present, no generation progress |
| H2 Real World Match | 3/5 | "Net Price" jargon, dates formatted correctly |
| H3 User Control | 5/5 | Back button, cancel, undo all present |
| H4 Consistency | 4/5 | Card style matches, button placement inconsistent |
| H5 Error Prevention | 3/5 | No confirmation on school removal |
| H6 Recognition | 4/5 | Nav visible, school list accessible |
| H7 Flexibility | 3/5 | No keyboard shortcuts, search available |
| H8 Minimalism | 2/5 | 14 items on page, no progressive disclosure |
| H9 Error Recovery | 4/5 | Error messages clear, retry available |
| H10 Help | 4/5 | HelpTooltips present, tour available |
| **AVERAGE** | **3.6/5** | |
```

---

## Severity Scale

| Score | Meaning | Action |
|-------|---------|--------|
| 0 | Not a usability problem | None |
| 1 | Cosmetic only — fix if time permits | Polish |
| 2 | Minor usability problem — low priority | P2 |
| 3 | Major usability problem — important to fix | P1 |
| 4 | Usability catastrophe — must fix before launch | P0 |

---

## Output Format

```
## Heuristic Evaluation: /heuristic-eval [mode] [target]

### Mode
[audit | page | compare | new]

### Pages Evaluated
[N pages, organized by tier]

### Heuristic Scorecard (all pages)
| Heuristic | Avg Score | Worst Page | Best Page |
|-----------|-----------|------------|-----------|
| H1 System Status | 3.8 | Plan (generation) | Dashboard |
| H2 Real World | 3.2 | Financial section | Settings |
| ... | ... | ... | ... |
| **Overall** | **3.5/5** | | |

### Per-Page Scores
| Page | H1 | H2 | H3 | H4 | H5 | H6 | H7 | H8 | H9 | H10 | Avg |
|------|----|----|----|----|----|----|----|----|----|----|-----|
| Dashboard | 4 | 4 | 5 | 4 | 3 | 4 | 3 | 3 | 4 | 4 | 3.8 |
| Plan | 2 | 3 | 4 | 4 | 3 | 3 | 2 | 2 | 3 | 4 | 3.0 |
| Schools | 4 | 4 | 4 | 3 | 3 | 4 | 4 | 3 | 4 | 3 | 3.6 |

### Findings
| Severity | Heuristic | Page | Issue | Recommendation |
|----------|-----------|------|-------|----------------|
| 3 (Major) | H5 | Schools | No confirmation on school removal | Add confirm dialog |
| 3 (Major) | H8 | Plan | 14 items visible, no collapse | Progressive disclosure |
| 2 (Minor) | H2 | Plan | "Net Price" jargon | Replace with "Estimated Cost" |

### Cross-Page Patterns
| Pattern | Heuristic | Pages Affected | Priority |
|---------|-----------|----------------|----------|
| No generation progress indicator | H1 | Plan, Coach | P1 |
| Jargon without explanation | H2 | Plan, Schools, Compare | P1 |

### Issues Filed
| # | Title | Heuristic | Severity |
|---|-------|-----------|----------|
| ... | ... | ... | ... |

### Summary
📄 Pages evaluated: [N]
📊 Overall heuristic score: [X.X]/5
🔴 Major issues (severity 3-4): [N]
⚠️ Minor issues (severity 1-2): [N]
✅ Best-performing heuristic: [HN]
🔻 Worst-performing heuristic: [HN]
📋 Issues filed: [N]
```

---

## When to Escalate

Stop and discuss if:
- A page scores below 2.0/5 average (fundamentally needs redesign)
- A single heuristic scores below 2.0 across ALL pages (systemic problem)
- Findings conflict with existing product decisions
- Fixes would require architectural changes (not just UI tweaks)

---

## Key References

- Jakob Nielsen's 10 Usability Heuristics: https://www.nngroup.com/articles/ten-usability-heuristics/
- `/ux-ia-auditor` — Structure-level evaluation (complements page-level heuristic eval)
- `/ux-writer` — Copy quality (deep dive on H2 — Real World Match)
- `/error-ux-auditor` — Error experience (deep dive on H5 + H9)
- `/a11y-auditor` — Accessibility (separate WCAG concern, not a heuristic)
- `/designer` — Visual design evaluation
- Owl-Listener/designer-skills — heuristic-evaluation skill (inspiration)
