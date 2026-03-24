# /ux-ia-auditor Skill

A standalone UX and Information Architecture audit skill for the project. Use this to step back from code-level details and evaluate the **big picture**: Is the app organized in a way that makes sense to users? Can they find what they need? Do the journeys flow logically? Is the experience coherent across roles?

This skill answers the question: **"Does the overall structure and flow of the product work?"**

It does NOT cover:
- Visual design, colors, typography → use `/designer`
- WCAG accessibility compliance → use `/a11y-auditor`
- API/frontend code quality → use `/frontend-auditor`
- Performance → use `/performance-auditor`

## Usage

```
/ux-ia-auditor audit              — Full UX & information architecture audit
/ux-ia-auditor sitemap            — Generate the complete sitemap (routes, nav, role access)
/ux-ia-auditor journey [role]     — Map user journeys for a specific role (student | parent)
/ux-ia-auditor review [page]      — Deep-dive review of a specific page or flow
```

---

## Nielsen's Heuristics Cross-Reference

Our 8 principles below are domain-specific adaptations of [Nielsen's 10 Usability Heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/). Use this mapping when you need to cite industry-standard language:

| Nielsen Heuristic | Our Principle | Check |
|-------------------|---------------|-------|
| 1. Visibility of system status | P2 — Wayfinding | 2a |
| 2. Match between system and real world | P8 — Copy Clarity | 2e |
| 3. User control and freedom | P2 — Wayfinding (back nav) | 2a, 2c |
| 4. Consistency and standards | P4 — Consistent Patterns | 2b, 2e |
| 5. Error prevention | P7 — Empty & Edge States | 2g, 2h |
| 6. Recognition rather than recall | P3 — Progressive Disclosure | 2d |
| 7. Flexibility and efficiency of use | P6 — Mobile-First Flow | 2f |
| 8. Aesthetic and minimalist design | P3 — Progressive Disclosure | 2d |
| 9. Help users recognize and recover from errors | P7 — Empty States + P2 — Wayfinding | 2g, 2h |
| 10. Help and documentation | P8 (help integration) | 2h |

---

## UX & Information Architecture Fundamentals

Read these before doing anything. Every structural UX problem traces to one of these principles.

### Principle 1 — Information Hierarchy & Context Awareness: Organize by User Importance and Timeline

Users don't care how your codebase is organized. They care about finding what they need. Content should be organized by **what matters most to the user right now**, adapting to their specific grade level, timeline, and not by what was easiest to build.

```
✅ GOOD IA:
  Dashboard → shows current phase, next action, recent activity, adapting to time of year (e.g., Deadlines for Senior Fall, Exploration for Sophomore Spring)
  Plan → organized by strategic question ("Where should I apply?", "How do I pay?")
  Schools → organized by decision stage (My Schools, Exploring, Not Interested)

❌ BAD IA:
  Dashboard → shows exactly the same widgets to a 9th grader as a 12th grader in October
  Plan → organized by data source (IPEDS data, LLM output, user input)
  Schools → organized by data freshness (verified, unverified, stale)
```

**Test:** If you explained the page structure to a parent over the phone, would they understand it?

---

### Principle 2 — Wayfinding & Sequenced Planning: Users Know Where They Are (In App & Journey)

Every page must answer questions about both the interface AND the user's admissions journey:
1. **Where am I?** — Active nav item, page title, breadcrumbs
2. **Where can I go?** — Visible navigation, clear CTAs
3. **How do I get back?** — Back button, breadcrumbs, consistent nav
4. **Where am I in the bigger picture?** — Does the user feel they have a comprehensive plan? Is there a clear sequencing of "Now, Next, and Later" so they aren't overwhelmed by everything at once but still feel prepared for the future?

```
✅ GOOD wayfinding:
  - Sidebar highlights current page
  - Page has a clear h1 title
  - "Back to Schools" link at top of school detail page
  - "Next: Activities" button at bottom of academics form

❌ BAD wayfinding:
  - No indication which page you're on in sidebar
  - School detail page has no way back except browser back button
  - Onboarding step 3 has no indication of total steps or progress
```

---

### Principle 3 — Progressive Disclosure: Show Only What's Needed Now

Don't overwhelm users with everything at once. Show the essential information first, and let them dig deeper if they want to.

```
✅ GOOD progressive disclosure:
  - School card shows name, fit score, estimated cost
  - Click to expand → full details, scholarships, deadlines
  - Compare page shows side-by-side summary
  - Click "See details" → full comparison data

❌ BAD progressive disclosure:
  - School card shows 15 data points, 3 charts, and 5 action buttons
  - Plan page shows all 4 sections expanded by default with full text
  - Onboarding form shows all optional fields at once
```

---

### Principle 4 — Consistent Patterns: Same Thing Should Look and Work the Same Way Everywhere

When users learn a pattern on one page, they expect it everywhere. Inconsistency creates confusion and reduces trust.

```
✅ GOOD consistency:
  - All "save" actions use the same button style and position
  - All school cards follow the same layout (name, location, fit, cost)
  - All forms validate inline with the same red text style
  - All loading states use the same skeleton pattern

❌ BAD consistency:
  - "Save" button is top-right on settings, bottom-center on profile
  - School cards look different on the list page vs. the compare page vs. the plan
  - Some forms show errors as toasts, others as inline text, others as alert banners
  - Loading is a spinner on page A, skeleton on page B, blank on page C
```

---

### Principle 5 — Role-Appropriate Experience & Collaboration: Students and Parents Have Different Mental Models

Students think: "What do I need to DO?" (action-oriented)
Parents think: "Is my kid on track?" (monitoring-oriented)

The same data should be presented differently based on who's looking at it. Furthermore, a premium experience facilitates healthy collaboration rather than just surveillance.

```
✅ GOOD role design:
  - Student dashboard: "Your next step: Complete your activity list"
  - Parent dashboard: "Anna has completed 5 of 8 onboarding steps. Here is how you can support her this week."
  - Student plan: editable, action-focused, safe private workspace
  - Parent plan: read-only, insight-focused, clear privacy boundaries, and actionable parent-specific guidance
  - Easy handoffs: Parent can gently "nudge", Student can proudly share a milestone
  - Parent Confidence: The platform provides valuable, personalized insights that validate the strategy and empower the parent.

❌ BAD role design:
  - Parent sees the same dashboard as student but can't edit anything (confusing)
  - Parent has to navigate student-oriented menus to find monitoring features
  - Student feels surveilled rather than supported, with unclear privacy boundaries
```

---

### Principle 6 — Mobile-First Flow: Primary Tasks Must Work on Phone

Over 60% of Gen Z browses on mobile. The primary user journey (onboarding, checking plan, viewing schools) must feel native on a phone screen.

```
✅ GOOD mobile flow:
  - Onboarding forms are single-column, thumb-friendly
  - School cards stack vertically
  - Navigation collapses to hamburger/bottom bar
  - Tables convert to card layouts on mobile

❌ BAD mobile flow:
  - Horizontal scrolling on tables
  - Side-by-side layouts that squeeze to unreadable widths
  - Tiny action buttons that require precision tapping
  - Modals that are wider than the viewport
```

---

### Principle 7 — Empty & Edge States: Every Screen Has a First-Time Experience

The first time a user sees a screen, it may have no data. This is the most critical moment — it sets expectations and reduces anxiety.

```
✅ GOOD empty states:
  - School list (empty): "You haven't added any schools yet. Let's find some that fit."
  - Plan (not generated): "Complete onboarding to unlock your personalized plan."
  - Coach (no messages): "Hi! I'm your college planning coach. Ask me anything."

❌ BAD empty states:
  - School list (empty): blank page
  - Plan (not generated): spinner that never stops
  - Coach (no messages): "No messages" with no explanation of what the coach does
```

---

### Principle 8 — Copy Clarity: No Jargon, Consistent Terms, Brand Voice

Users (especially students) shouldn't need to decode your interface. Use the same word for the same concept everywhere. Match the brand voice (warm, direct, like a knowledgeable friend).

```
✅ GOOD copy:
  - Consistent: always "My Schools" (not sometimes "Saved Schools", "Favorites", "School List")
  - Clear: "Estimated cost after merit aid" (not "Net price projection post-institutional grant")
  - Brand voice: "Here's what the data shows" (not "Analysis indicates")

❌ BAD copy:
  - Same feature called different names on different pages
  - Technical terms without explanation (EFC, COA, CDS, IPEDS)
  - Inconsistent capitalization ("My schools" vs "My Schools" vs "my schools")
```

---

## Phase 0: Scope & Inventory

Before auditing, build a complete inventory of the product surface area.

### Step 0a — Route Discovery

```
1. Find all page routes:
   Glob: src/app/(app)/**/page.tsx
   Glob: src/app/(auth)/**/page.tsx
   Glob: src/app/api/**/route.ts   (for understanding data flow, not auditing APIs)

2. Find all layout files (these define navigation structure):
   Glob: src/app/(app)/**/layout.tsx
   Glob: src/app/(auth)/**/layout.tsx

3. Identify navigation components:
   Grep: "sidebar" OR "nav" OR "navigation" in src/components/
   Read the main layout to find sidebar/nav component imports
```

### Step 0b — Navigation Inventory

```
1. Read the sidebar/navigation component
2. List every navigation link with:
   - Label (what users see)
   - Destination (route path)
   - Role visibility (student only, parent only, both)
   - Icon used
   - Relative position (order in the sidebar)

3. Compare nav links to actual routes — identify:
   - ORPHAN PAGES: routes with no nav link (how does a user get there?)
   - DEAD LINKS: nav items pointing to non-existent routes
   - HIDDEN FEATURES: functionality that exists but isn't discoverable
```

### Step 0c — Role Mapping

```
1. Identify all routes under src/app/(app)/parent/ → parent-facing
2. Identify all routes NOT under parent/ → student-facing (or shared)
3. Check middleware/layout for role-based redirects
4. Map which features each role can access:
   - Student: [list every feature/page]
   - Parent: [list every feature/page]
   - Shared: [list any pages both roles see]
```

### Step 0d — Feature Inventory

```
For each major feature area, list:
- Entry point(s): how does a user get to this feature?
- Core screens: what pages/views does this feature include?
- Actions available: what can the user DO here?
- Data displayed: what information is shown?
- Connections: what other features does this link to/from?

Feature areas to inventory:
1. Onboarding (all 8 phases)
2. Dashboard
3. Plan (all sections)
4. Schools (list, detail, compare)
5. Coach
6. Settings
7. Help
8. Documents/Uploads
9. Resume/Brag Sheet
```

---

## Phase 1: Sitemap Generation

After inventory, produce a **readable sitemap document** with this structure:

```markdown
# the project — Product Sitemap

## Student Experience

### Navigation (Sidebar)
1. Dashboard → /dashboard
2. My Plan → /plan
3. Schools → /schools
4. Coach → /coach (if applicable)
5. Settings → /settings
6. Help → /help

### Onboarding Flow (Sequential)
Phase 1: Welcome → /onboarding/welcome
Phase 2: Academics → /onboarding/academics
...
Phase 8: Review → /onboarding/review

### Deep Pages (Accessed via Links, Not Nav)
- School Detail → /schools/[id]
- Compare Schools → /schools/compare
- ...

### Orphaned Pages (No Clear Entry Point)
- [list any pages with no nav link or obvious link from another page]

## Parent Experience

### Navigation (Sidebar)
1. Dashboard → /parent
2. Student Plan → /parent/plan/[studentId]
...

### Deep Pages
...

## Shared
- Login → /login
- Signup → /signup
...
```

**Critical output:** The sitemap must be **plain English, not code**. A non-technical PM should be able to read it, print it, and mark it up with a pen.

---

## Phase 2: Audit Checks

Run these checks against the sitemap and page inventory from Phase 1.

### 2a — Navigation & Wayfinding

```
For the sidebar/main navigation:
□ Does every major feature have a nav entry? (no hidden features)
□ Is the nav order logical? (most-used features first? grouped by purpose?)
□ Does the active page highlight correctly in the nav?
□ Is the nav consistent across all pages? (same items, same order)
□ On mobile: how does the nav work? (hamburger? bottom bar? hidden?)

For each page:
□ Is there a clear page title (h1 or equivalent)?
□ Does the user know where they are? (breadcrumbs, active nav, page title)
□ Can the user get back to the previous page? (back link, breadcrumbs, nav)
□ Are there clear next steps / CTAs on the page?
□ Are links between related pages present? (e.g., school list → school detail → compare)

For the onboarding flow:
□ Is there a progress indicator? (step X of Y, progress bar)
□ Can users go back to previous steps?
□ Can users skip optional steps? Is this clear?
□ Is the flow linear or branching? Is this communicated?
```

**Severity:** Hidden major feature = P1. No back navigation = P1. Missing progress indicator in multi-step flow = P2.

---

### 2b — Information Architecture & Content Hierarchy

```
For each page, evaluate the content organization:
□ Is the most important information at the top?
□ Are related items grouped together?
□ Are unrelated items separated (with headings, dividers, whitespace)?
□ Does the page structure match the user's mental model?
   (e.g., Plan organized by strategic question, not by data source)
□ Would a first-time user understand what this page is for in 5 seconds?

For the overall product:
□ Is each piece of information in ONE clear location? (no duplication across pages)
□ If data appears on multiple pages, is the "source of truth" clear?
   (e.g., GPA shown on dashboard AND plan — which is the place to edit it?)
□ Are there pages that try to do too much? (should be split into separate pages)
□ Are there pages that are too thin? (could be combined with another page)
□ Is the depth right? (too many clicks to reach important content? too flat with everything on one page?)
```

**Severity:** Key information buried/unfindable = P1. Confusing page purpose = P1. Duplicated controls = P2. Slightly wrong grouping = P2.

---

### 2c — User Journey Coherence

```
Map and evaluate these critical user journeys:

JOURNEY 1: New Student → First Value
  Sign up → Onboarding → Dashboard → Plan (first view)
  □ Is every step clear and motivated?
  □ How many clicks from signup to seeing their personalized plan?
  □ Are there any dead ends where the user gets stuck?
  □ Is progress visible throughout?

JOURNEY 2: Student Explores Schools
  Dashboard → Schools → Browse/Search → Add to list → Compare → Decide
  □ Can the user easily find schools relevant to them?
  □ Is the three-list system (My Schools, Exploring, Not Interested) intuitive?
  □ Can the user compare schools side-by-side?
  □ Is it clear how school recommendations relate to their profile?

JOURNEY 3: Student Uses Plan
  Dashboard → Plan → Read strategy → Take action → Return
  □ Is the plan organized in a way that drives action?
  □ Does each section have a clear "what to do next"?
  □ Can the user tell which parts of the plan are personalized?
  □ Can the user download/export the plan?

JOURNEY 4: Student Talks to Coach
  Dashboard → Coach → Ask question → Get answer → Follow advice
  □ Is the coach easy to find and access?
  □ Does the coach conversation feel natural?
  □ Are coach suggestions actionable and linked to app features?
  □ Can the user access coach from anywhere in the app?

JOURNEY 5: Parent Monitors Progress
  Login → Parent Dashboard → View student progress → Read plan → Understand finances
  □ Does the parent immediately see their student's status?
  □ Can the parent find financial information easily?
  □ Is the parent experience clearly different from the student's?
  □ Does the parent know what they can/can't do (read-only vs. editable)?

JOURNEY 6: Returning User (Day 2+)
  Login → Dashboard → See what's new → Take next action
  □ Does the dashboard surface what's changed since last visit?
  □ Is the "next most important thing" obvious?
  □ Does the user have a reason to come back?
  □ Is the experience different for a returning user vs. first-time?

For each journey:
□ Count total clicks from start to goal
□ Identify any friction points (confusing labels, unexpected redirects, missing links)
□ Note any "moments of delight" (where the experience exceeds expectations)
□ Note any "moments of anxiety" (where users might feel lost, confused, or worried)

EMOTIONAL CURVE — For each journey, track the user's emotional state at each step:

| Step | Action | Emotion | Confidence | Notes |
|------|--------|---------|------------|-------|
| 1 | Sign up | Hopeful (+2) | Medium | Excited to start |
| 2 | Phase 1 welcome | Guided (+3) | High | Knows what's coming |
| 3 | Phase 4 academics | Anxious (-1) | Low | GPA entry feels judgmental |
| ... | ... | ... | ... | ... |

Scale: -3 (frustrated/lost) → 0 (neutral) → +3 (delighted/confident)

Plot the curve to find:
- VALLEYS: Where emotions dip — these are redesign opportunities
- PEAKS: Where emotions spike — these are strengths to protect
- FLAT LINES: Where nothing happens — these are engagement gaps

EMPOWERMENT LOOP — For each critical screen, does it follow the Data → Insight → Action pattern?
- **Data (The "What")**: The raw facts (e.g., GPA 3.6, Cost $45k). Raw data alone causes anxiety.
- **Insight (The "So What?")**: What this means for them contextually (e.g., "You're a strong academic fit for your Target schools").
- **Action (The "What Now?")**: The clear, achievable workflow for the STUDENT or PARENT. This should ideally be sequenced as **"Now, Next, and Later"** so they know exactly what to do immediately, without losing sight of the comprehensive plan.
*Confidence is built when BOTH students and parents understand their position, see the personalized value of the insights, and feel they have a comprehensive roadmap for success.*

MOMENTS OF TRUTH — Identify the 3-5 critical moments that make or break each journey:
(These are the moments where the user decides to continue or abandon)

Example moments of truth for the project:
- First personalized insight (do they feel "this app gets me"?)
- Seeing their school list with fit scores (does it match their expectations?)
- Reading their plan for the first time (does it feel worth the 30 min onboarding?)
- Parent seeing student's progress (does it reduce their anxiety?)
- Returning on Day 2 (is there a reason to come back?)
```

**Severity:** Dead end in critical journey = P1. Excessive clicks (>5) for primary task = P2. Missing journey entirely = P1. Moment of truth fails = P1.

---

### 2d — Cognitive Load & Progressive Disclosure

```
For each page:
□ How many distinct "things" are on the page? (cards, sections, buttons, data points)
   - 1-5: Low cognitive load ✅
   - 6-10: Medium (acceptable if well-organized) ⚠️
   - 11+: High (likely needs reorganization) ❌
□ Are there expandable/collapsible sections for secondary content?
□ Are optional fields clearly marked (or hidden behind "Show more")?
□ Do charts/visualizations have clear labels and legends?
□ Are numbers formatted for readability? ($45,000 not 45000)
□ Are long lists paginated, virtualized, or filtered?

For forms:
□ Are form fields grouped into logical sections?
□ Are there more than 7 visible fields at once? (cognitive overload threshold)
□ Are optional fields separated or grouped at the bottom?
□ Is inline help (tooltips, descriptions) available for complex fields?
□ Does the form show a summary before submission?

For data-heavy pages (plan, compare, school detail):
□ Is there a summary/overview at the top before the full data?
□ Can users filter or sort to reduce what they're looking at?
□ Are the most important metrics highlighted visually?
□ Is there a clear reading order (top-to-bottom, left-to-right)?
```

**Severity:** Page with 15+ undifferentiated items = P1. Form with 10+ fields no grouping = P2. No summary on data-heavy page = P2.

---

### 2e — Copy & Terminology Consistency

```
Scan the entire product for terminology consistency:

□ Build a glossary of key terms used in the UI:
  - What is the school list called? (My Schools? Saved Schools? Favorites? School List?)
  - What is the plan called? (Your Plan? My Plan? Strategic Plan? Playbook?)
  - What are the onboarding steps called? (Phases? Steps? Sections?)
  - What is the AI called? (Coach? AI Coach? Advisor? Assistant?)
  - What is the financial section called? (Cost? Finances? Financial Strategy? Budget?)

□ For each term, grep the codebase for variations:
  Grep: "My Schools" OR "Saved Schools" OR "Your Schools" OR "School List" in src/
  → All should use the SAME term

□ Check button labels for consistency:
  - Save actions: always "Save"? or sometimes "Submit", "Done", "Apply"?
  - Cancel actions: always "Cancel"? or sometimes "Back", "Close", "Dismiss"?
  - Destructive actions: always "Delete"? or sometimes "Remove", "Discard"?

□ Check capitalization consistency:
  - Title Case ("My Schools") vs sentence case ("My schools") — pick one
  - Are headings, buttons, and nav items consistent?

□ Check tone/voice consistency (per Brand Brief):
  - Warm and direct throughout? Or formal in some places, casual in others?
  - Any instances of technical jargon without explanation?
  - Any instances of corporate-speak ("leverage", "optimize", "utilize")?
  - Financial disclaimers present where needed? ("estimated", "may vary")
```

**Severity:** Same feature called 3+ different names = P1. Inconsistent button labels = P2. Jargon without explanation = P2.

---

### 2f — Mobile Layout & Responsive Flow

```
For each page, check the responsive strategy:
□ Read the Tailwind classes — are mobile-first breakpoints used?
   (base classes for mobile, sm: md: lg: for larger screens)
□ Tables: do they convert to cards on mobile? (hidden md:block + md:hidden pattern)
□ Side-by-side layouts: do they stack on mobile? (grid-cols-1 md:grid-cols-2)
□ Navigation: is there a mobile nav pattern? (hamburger, bottom bar, drawer)
□ Modals: are they full-screen on mobile? (DialogContent width classes)
□ Forms: single column on mobile?
□ Touch targets: buttons and links at least h-11 (44px)?
□ Horizontal scrolling: none on mobile (overflow-x check)?

For critical user flows (check mobile journey):
□ Can onboarding be completed entirely on mobile?
□ Can the plan be read comfortably on mobile?
□ Can schools be browsed and compared on mobile?
□ Can the coach be used on mobile?
```

**Severity:** Primary flow broken on mobile = P1. Horizontal scroll on mobile = P2. Non-mobile-friendly table = P2.

---

### 2g — Empty States & First-Run Experience

```
For each page that displays data:
□ What happens when there is NO data yet?
   - Blank page? (BAD — P1)
   - Loading spinner that never resolves? (BAD — P1)
   - Helpful empty state with guidance? (GOOD)
   - Prompt to complete a prerequisite? (GOOD)

□ Does the empty state:
   - Explain WHY there's no data? ("Complete onboarding to see your plan")
   - Guide the user to the NEXT ACTION? ("Add your first school →")
   - Feel welcoming, not broken? (illustration, warm copy, not just "No data")
   - Match the brand voice? (warm, encouraging, not clinical)

For the first-time user experience (FTUE):
□ What does the user see immediately after signup?
□ Is it clear what they should do first?
□ How long before they see personalized value? (time to value)
□ Is the onboarding progress visible and motivating?
□ Are there any "wow moments" early in the experience?

For returning users:
□ Dashboard shows what's changed since last visit?
□ Incomplete tasks are surfaced?
□ New features/content are highlighted?
```

**Severity:** Blank page on first visit = P1. No guidance on empty state = P1. Good empty state = ✅.

---

### 2h — Help & Discoverability Integration

```
For help system integration:
□ Is help accessible from every page? (sidebar link, floating button, or both)
□ Do complex features have contextual help? (HelpTooltip components)
□ Are tours available for key pages? (check useTour integration)
□ Is the coach positioned as a help resource? (Help tab in coach)
□ Are help articles relevant to the current page context?

For feature discoverability:
□ Are new features highlighted or introduced? (not just silently available)
□ Are power-user features (compare, export, coach) easy to find?
□ Is it clear which features are available vs. locked vs. coming soon?
□ Can users discover features through natural exploration? (links, CTAs, tooltips)

For error recovery:
□ When something goes wrong, does the user know what to do?
□ Are error messages actionable? ("Try again" button, not just "Error occurred")
□ Can users recover from mistakes? (undo, edit, re-do)
□ Are destructive actions confirmed? (delete, remove, reset)
```

**Severity:** No help on complex feature = P2. Error with no recovery = P1. Destructive action without confirmation = P1.

---

### 2i — Role-Based Experience Parity & Collaboration

```
For parent vs. student experience:
□ Does each role have a tailored dashboard? (not the same page with some buttons hidden)
□ Is the parent experience clearly monitoring-oriented? (not action-oriented)
□ Can parents easily find student progress, plan, school list?
□ Are permission boundaries clear? (what parents can see vs. what's private to student)
□ Is the parent nav simplified? (fewer items than student, focused on their needs)
□ Are there healthy collaboration loops? (Can a parent nudge? Can a student share?)
□ Does the student feel a sense of safe, private workspace before sharing?

For onboarding:
□ Does the parent onboarding flow make sense? (different from student?)
□ Does the parent have clear "setup complete" indicators?
□ Can the parent invite their student (or vice versa)?

For cross-role consistency:
□ Shared features (schools, plan) look similar but role-appropriate?
□ The same data is presented in role-appropriate language?
   (Student: "Your GPA" → Parent: "Anna's GPA")
□ Navigation between roles is clear? (parent switching between students?)
```

**Severity:** Parent sees student-oriented interface = P1. No clear permission boundaries = P1. Minor language mismatch = P2.

---

### 2j — Redundancy & Consolidation Opportunities

```
Look for:
□ Pages that serve very similar purposes (candidates for merging)
□ Information displayed on multiple pages (which is the "source of truth"?)
□ Actions available from multiple places (is this helpful or confusing?)
□ Sections that have become stale or irrelevant (dead weight)
□ Features that overlap with the coach (could the coach replace a standalone page?)

Document:
□ Which pages could be combined?
□ Which features are under-used or over-built?
□ Which sections feel out of place on their current page?
□ What new pages or features are missing entirely?
```

**Severity:** Redundant pages causing confusion = P2. Missing critical feature = P1. Stale content = P2.

---

## Phase 3: Scoring & Prioritization

| Status | Meaning |
|--------|---------|
| ✅ Pass | Clear, intuitive, well-organized |
| ⚠️ Concern | Works but could be better — monitor |
| ❌ Issue — P2 | Confusing or suboptimal, fix before launch |
| 🔴 Issue — P1 | Users will get lost, stuck, or frustrated — fix now |

### Scoring by Area

Rate each area 1-5:

| Area | Score | Meaning |
|------|-------|---------|
| Navigation & Wayfinding | 1-5 | 5 = always know where you are, 1 = frequently lost |
| Information Architecture | 1-5 | 5 = everything in the right place, 1 = can't find things |
| User Journey Coherence | 1-5 | 5 = smooth flow, 1 = dead ends and confusion |
| Cognitive Load | 1-5 | 5 = just right, 1 = overwhelming |
| Copy Consistency | 1-5 | 5 = one term per concept, 1 = different names everywhere |
| Mobile Experience | 1-5 | 5 = native-feeling, 1 = broken on phone |
| Empty States | 1-5 | 5 = welcoming guidance, 1 = blank pages |
| Help Integration | 1-5 | 5 = help always available, 1 = user on their own |
| Role Experiences | 1-5 | 5 = tailored per role, 1 = same view for everyone |
| Redundancy | 1-5 | 5 = lean and focused, 1 = bloated with duplication |

**Overall UX/IA Score:** Average of 10 areas (1-5 scale)

---

## Phase 4: Recommendations & Restructuring Proposals

After scoring, produce actionable recommendations:

### For each P1 finding:
1. **What's wrong** — in plain English
2. **Who it affects** — which role, which journey
3. **What to change** — specific recommendation
4. **Expected impact** — what improves for the user

### For structural changes:
1. **Current structure** — how it works today
2. **Proposed structure** — how it should work
3. **Migration path** — what needs to change (pages, nav, routes)
4. **Risk** — what could break

### File GitHub issues for every P1 and P2 finding with labels:
- `ux` — UX issue
- `P1` or `P2` — severity
- `ux-ia-audit` — audit round tag

---

## Common UX/IA Failure Patterns

| Pattern | Symptom | Check | Severity |
|---------|---------|-------|----------|
| Orphaned page (no nav link, no inbound link) | Users never discover the feature | 2a | P1 |
| Same concept, 3 different names | Users don't realize it's the same thing | 2e | P1 |
| Page tries to do everything | Users feel overwhelmed, skip important info | 2d | P1 |
| No empty state on data page | First-time users see blank page, think app is broken | 2g | P1 |
| Dead end in critical journey | Users get stuck with no next step | 2c | P1 |
| Student-oriented copy on parent page | Parents feel like they're in the wrong place | 2i | P1 |
| Desktop-only table on mobile | Mobile users can't read the data | 2f | P2 |
| Feature available but unfindable | Users ask "can it do X?" when it already can | 2h | P2 |
| Inconsistent button placement | Users hunt for actions on each page | 2b | P2 |
| No progress indicator in multi-step flow | Users don't know how far they are | 2a | P2 |
| Duplicated info on multiple pages, only one editable | Users edit the wrong one and changes don't stick | 2j | P1 |

---

## Output Format

Every `/ux-ia-auditor` invocation must produce this summary:

```
## UX/IA Auditor: /ux-ia-auditor [mode] [target]

### Mode
[audit | sitemap | journey | review]

### Product Scope
[N pages, N features, N roles covered]

### Sitemap
[Full sitemap as described in Phase 1, or link to generated file]

### User Journeys Evaluated
| Journey | Steps | Friction Points | Dead Ends | Moments of Truth | Score |
|---------|-------|-----------------|-----------|------------------|-------|
| New Student → First Value | 12 clicks | 2 | 0 | 3 pass, 1 fail | 4/5 |
| Parent Monitors Progress | 6 clicks | 1 | 1 | 2 pass, 0 fail | 3/5 |

### Emotional Curve (per journey)
[ASCII representation of the emotional curve for each journey]
```
Journey 1: New Student → First Value
  +3 |         *
  +2 |   *   *   *
  +1 | *           *
   0 |               *
  -1 |     *
     |---+---+---+---+---+---+---
       signup welcome academics plan schools coach day2
```

### UX/IA Scorecard
| Area | Score | Key Finding |
|------|-------|-------------|
| Navigation & Wayfinding | 4/5 | Coach not in sidebar on mobile |
| Information Architecture | 3/5 | Plan sections organized by data source, not user question |
| Copy Consistency | 2/5 | "My Schools" / "School List" / "Saved Schools" used interchangeably |
| ... | ... | ... |
| **Overall** | **3.2/5** | |

### Findings
| Severity | Area | Page/Feature | Description | Recommendation |
|----------|------|--------------|-------------|----------------|
| P1 | Wayfinding | /schools/compare | No back button to school list | Add "← Back to Schools" link |
| P1 | Copy | Product-wide | School list called 4 different names | Standardize to "My Schools" |
| P2 | Cognitive Load | /plan | All 4 sections expanded by default | Collapse secondary sections |

### Structural Recommendations
[Numbered list of proposed changes, with current vs. proposed structure]

### Issues Filed
| # | Title | Severity | Labels |
|---|-------|----------|--------|
| #1750 | Standardize school list terminology across product | P1 | ux, P1, ux-ia-audit |
| #1751 | Add back navigation on school detail pages | P1 | ux, P1, ux-ia-audit |

### Summary
🏗️ Product Scope: [N] pages, [N] features
📊 UX/IA Score: [X.X]/5
🔴 P1 Issues: [N]
⚠️ P2 Issues: [N]
✅ Areas of Strength: [list]
📋 Issues Filed: [N]
```

---

## When to Escalate

Stop and discuss with the user before proceeding if:

- A finding suggests a **major navigation restructure** (adding/removing sidebar items, reorganizing page hierarchy)
- A finding implies a **feature should be removed or consolidated** (could invalidate existing work)
- A finding reveals a **fundamental flow problem** (e.g., onboarding order should change)
- The audit discovers **missing features** that require new development
- The **parent vs. student experience** needs rethinking at a structural level
- Any proposed change would affect **more than 10 files**

---

## Key References

- `src/app/(app)/layout.tsx` — Main layout with sidebar/navigation
- `src/components/` — All UI components (patterns, consistency)
- `src/app/(app)/onboarding/` — 8-phase onboarding flow
- `src/app/(app)/plan/` — Plan pages
- `src/app/(app)/schools/` — School list and detail pages
- `src/app/(app)/parent/` — Parent-facing pages
- `src/hooks/useTour.ts` — Tour system (help/discoverability)
- `src/components/ui/HelpTooltip.tsx` — Contextual help component
- `CLAUDE.md` — Brand voice, product overview
- `PATTERNS.md` — Security and coding patterns
- Brand Brief: https://www.notion.so/2ee65d2ef8aa81589e1edb97d43799c2

## Methodology References

- **Nielsen's 10 Usability Heuristics** — Industry standard for heuristic evaluation (cross-referenced in our principles above)
- **Jim Kalbach, "Mapping Experiences"** — Journey mapping with emotional curves and moments of truth
- **Jesse James Garrett, "The Elements of User Experience"** — Information architecture and interaction design layers
- **Owl-Listener/designer-skills** (GitHub) — Open-source Claude Code design skills that inspired the journey mapping and heuristic evaluation approaches in this skill
