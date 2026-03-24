# /metrics-planner Skill

A one-time strategic planning skill for defining UX metrics and KPIs before the project beta launch. Use this to answer: **"How will we know if the product is working for users?"**

This is NOT an audit skill. It produces a **metrics plan** — the list of things to measure, how to measure them, and what "good" looks like. Run it once before beta, then reference the output to build instrumentation.

## Usage

```
/metrics-planner plan                — Generate the full metrics plan
/metrics-planner review              — Review existing metrics for gaps
/metrics-planner instrument [metric] — Suggest implementation for a specific metric
```

---

## The HEART Framework

We use Google's HEART framework (adapted for the project) to organize metrics by what they tell us about the user experience:

| Dimension | What It Measures | the project Example |
|-----------|-----------------|---------------------|
| **H**appiness | User satisfaction, perceived quality | "Do users feel the plan was worth the 30-min onboarding?" |
| **E**ngagement | Depth and frequency of interaction | "How often do users check their school list or talk to coach?" |
| **A**doption | New user conversion | "What % of signups complete onboarding?" |
| **R**etention | Users coming back | "What % of users return within 7 days?" |
| **T**ask Success | Can users accomplish their goals? | "Can a student add schools and download their plan?" |

---

## Phase 1: Define Goals

For each HEART dimension, define what success looks like for the project:

```
HAPPINESS Goals:
□ Users feel the plan is personalized (not generic)
□ Financial estimates feel trustworthy (not misleading)
□ Coach feels helpful (not annoying)
□ Parents feel informed (not anxious)

ENGAGEMENT Goals:
□ Students interact with school list regularly
□ Students use coach for real questions
□ Parents check progress periodically
□ Users download/share their plan

ADOPTION Goals:
□ High onboarding completion rate
□ Users add schools during or after onboarding
□ Parents link to student accounts
□ Users return after first session

RETENTION Goals:
□ Users return within 7 days
□ Users return monthly through junior year
□ Users update profile as grades/scores change
□ Coach messages drive re-engagement

TASK SUCCESS Goals:
□ Users can complete onboarding without getting stuck
□ Users can find and add relevant schools
□ Users can download their plan as PDF
□ Users can understand their financial fit
```

---

## Phase 2: Define Metrics

For each goal, define a specific, measurable metric:

### Adoption Metrics (New User Funnel)

```
METRIC: Onboarding Completion Rate
  Definition: % of users who sign up and complete all 8 onboarding phases
  Data source: onboarding_progress table
  Target: ≥ 70%
  Signal: < 50% = onboarding is too long or confusing
  Breakpoints: measure completion at each phase to find drop-off

METRIC: Time to First Value
  Definition: Time from signup to first personalized plan view
  Data source: user_profiles.created_at → first plan page view
  Target: < 35 minutes (onboarding is ~30 min)
  Signal: > 45 min = users are getting stuck

METRIC: School List Population Rate
  Definition: % of users who add ≥ 1 school within first session
  Data source: school_list_items table
  Target: ≥ 80%
  Signal: < 60% = school discovery isn't working

METRIC: Parent Link Rate
  Definition: % of student accounts with a linked parent
  Data source: family_accounts table
  Target: ≥ 40% (not all families will use parent features)
  Signal: < 20% = parent invitation flow is broken or invisible
```

### Engagement Metrics

```
METRIC: Weekly Active Users (WAU)
  Definition: Unique users who log in and take ≥ 1 action per week
  Data source: auth session logs + any write action
  Target: ≥ 50% of registered users (during school year)
  Signal: < 30% = product isn't sticky enough

METRIC: Coach Engagement Rate
  Definition: % of active users who send ≥ 1 coach message per month
  Data source: coach_conversations table
  Target: ≥ 30%
  Signal: < 15% = coach isn't discoverable or useful enough

METRIC: School List Activity
  Definition: Average schools added/moved/compared per active user per month
  Data source: school_list_items + compare page views
  Target: ≥ 3 actions/month
  Signal: < 1 = school management isn't driving value

METRIC: Plan Views per User
  Definition: Average plan page views per user per month
  Data source: page view events
  Target: ≥ 2/month
  Signal: < 1 = plan isn't being referenced/used
```

### Happiness Metrics

```
METRIC: Plan Quality Perception
  Definition: User rating of plan personalization (future: in-app survey)
  Data source: Not yet instrumented — needs NPS-style prompt
  Target: ≥ 4/5 average
  Signal: < 3/5 = plan feels generic

METRIC: Coach Satisfaction
  Definition: Thumbs up/down ratio on coach responses (future feature)
  Data source: Not yet instrumented — needs feedback UI
  Target: ≥ 80% thumbs up
  Signal: < 60% = coach quality issues

METRIC: Financial Trust
  Definition: % of users who report financial estimates as "helpful" or "accurate"
  Data source: Not yet instrumented — needs survey
  Target: ≥ 70%
  Signal: < 50% = financial data needs disclaimers or improvement
```

### Retention Metrics

```
METRIC: Day 1 Return Rate
  Definition: % of users who return within 24 hours of signup
  Data source: auth session logs
  Target: ≥ 40%
  Signal: < 20% = first session didn't create enough pull

METRIC: Day 7 Return Rate
  Definition: % of users who return within 7 days of signup
  Data source: auth session logs
  Target: ≥ 30%
  Signal: < 15% = no ongoing value driver

METRIC: Monthly Active Rate
  Definition: % of registered users active in last 30 days
  Data source: auth session logs
  Target: ≥ 50% (during school year)
  Signal: < 25% = retention problem

METRIC: Churn Trigger
  Definition: Last action before a user stops returning
  Data source: last activity timestamp + last action type
  Target: Identify top 3 churn triggers
  Signal: If churn happens right after a specific page/feature = UX problem
```

### Task Success Metrics

```
METRIC: Onboarding Phase Completion Rates
  Definition: % of users who complete each phase (measured individually)
  Data source: onboarding_progress table
  Target: ≥ 85% per phase (some drop-off expected at each phase)
  Signal: Any phase < 70% = that phase has a UX problem

METRIC: Plan Download Rate
  Definition: % of users with a complete plan who download the PDF
  Data source: plan download events
  Target: ≥ 60%
  Signal: < 30% = plan isn't perceived as valuable enough to save

METRIC: School Compare Usage
  Definition: % of users with ≥ 3 schools who use the compare feature
  Data source: compare page views
  Target: ≥ 40%
  Signal: < 20% = compare feature isn't discoverable

METRIC: Error Recovery Rate
  Definition: % of errors where the user retries and succeeds
  Data source: error events followed by success events
  Target: ≥ 70%
  Signal: < 40% = error messages aren't actionable
```

---

## Phase 3: Instrumentation Plan

For each metric, document how to actually collect the data:

```
METRIC: [Name]
  Currently instrumented? Yes / No / Partial
  Data source: [table, event, log]
  Query: [SQL or API call to compute the metric]
  Dashboard: [where to display it]
  Alert threshold: [when to notify]
  Owner: [who monitors this]
```

### Instrumentation Priority

| Priority | Metrics | Reason |
|----------|---------|--------|
| **P0 — Before Beta** | Onboarding completion, Time to first value, Day 1/7 return | Must-have to know if launch is working |
| **P1 — First Week** | WAU, School list activity, Plan download rate | Core engagement signals |
| **P2 — First Month** | Coach engagement, Compare usage, Error recovery | Deeper engagement understanding |
| **P3 — Post-Launch** | NPS, Financial trust, Churn triggers | Requires in-app surveys or longer data collection |

---

## Phase 4: Dashboard Specification

Define what the beta monitoring dashboard should show:

```markdown
## the project Beta Dashboard

### Top Line (refresh daily)
| Metric | Today | 7-Day Avg | Target | Status |
|--------|-------|-----------|--------|--------|
| Daily Signups | — | — | — | — |
| Onboarding Completion | — | — | ≥ 70% | — |
| Day 1 Return | — | — | ≥ 40% | — |
| WAU | — | — | ≥ 50% | — |

### Adoption Funnel (refresh daily)
Signup → Phase 1 → Phase 2 → ... → Phase 8 → Plan View → School Add → Compare

### Engagement (refresh weekly)
- Coach conversations per user
- School list actions per user
- Plan views per user
- PDF downloads

### Retention Curve (refresh weekly)
Day 1 → Day 3 → Day 7 → Day 14 → Day 30 retention

### Alerts
- Onboarding completion drops below 50%
- Day 1 return drops below 20%
- Any onboarding phase drops below 60%
- Error rate spikes above 5%
```

---

## Output Format

```
## Metrics Planner: /metrics-planner [mode]

### Mode
[plan | review | instrument]

### HEART Scorecard
| Dimension | # Metrics | Instrumented | Gaps |
|-----------|-----------|--------------|------|
| Happiness | 3 | 0 | Need survey UI |
| Engagement | 4 | 2 | Need coach events |
| Adoption | 4 | 3 | Need parent link tracking |
| Retention | 4 | 1 | Need session logging |
| Task Success | 4 | 2 | Need error recovery tracking |

### Metrics Defined
[Table of all metrics with definitions, targets, and data sources]

### Instrumentation Plan
[Priority-ordered list of what to build]

### Dashboard Spec
[Dashboard layout specification]

### Gaps & Recommendations
[What's missing, what to build first]

### Summary
📊 Metrics defined: [N]
✅ Already instrumented: [N]
🔧 Need instrumentation: [N]
🔴 Critical for beta: [N]
```

---

## When to Escalate

Stop and discuss if:
- A metric requires new database tables or schema changes
- Instrumentation would add latency to user-facing operations
- Privacy concerns with tracking (session logs, page views)
- Target numbers seem unrealistic given the user base size
- Metrics suggest features that don't exist yet (NPS prompt, thumbs up/down on coach)

---

## Key References

- Google HEART Framework: https://research.google/pubs/pub36299/
- `supabase/migrations/` — Check which tables exist for data collection
- `src/lib/llm/telemetry.ts` — Existing LLM cost telemetry (model for event tracking)
- `src/app/api/` — API routes where events could be instrumented
- CLAUDE.md — Product overview and feature list
