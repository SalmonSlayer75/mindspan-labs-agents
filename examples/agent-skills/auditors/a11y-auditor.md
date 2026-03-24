> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /a11y-auditor Skill

A standalone WCAG 2.1 AA accessibility audit skill for the project. Use this before any launch, after adding new pages or components, or when reviewing UI changes — to catch color contrast failures, missing keyboard support, broken screen reader semantics, and inadequate touch targets before they exclude users.

Accessibility is not optional for a premium product. Failures here signal low polish and can create legal exposure.

## Usage

```
/a11y-auditor audit              — Full WCAG 2.1 AA audit of all pages and components
/a11y-auditor validate [file]   — Audit a specific page or component file
/a11y-auditor fix [issue]       — Diagnose and fix a specific accessibility bug
/a11y-auditor focus [check]     — Run a single check class (contrast | keyboard | aria | forms | touch)
```

---

## WCAG 2.1 AA Fundamentals

Read these before doing anything. Every accessibility failure traces to one of these criteria.

### Rule 1 — Color Contrast (WCAG 1.4.3 / 1.4.11)

```
Normal text (< 18px regular or < 14px bold): minimum 4.5:1 contrast ratio
Large text (≥ 18px regular or ≥ 14px bold): minimum 3:1
UI components (icons, borders, focus indicators): minimum 3:1
Test in BOTH light mode AND dark mode
```

the project design system uses semantic color tokens. Hardcoded colors are the primary failure mode:

```tsx
// ❌ WRONG — hardcoded colors, unknown contrast
<p className="text-gray-400 bg-white">Muted text</p>
<Badge className="bg-blue-100 text-blue-600">Status</Badge>

// ✅ CORRECT — semantic tokens with known contrast in both modes
<p className="text-muted-foreground">Muted text</p>
<Badge variant="secondary">Status</Badge>
```

Common contrast failures in dark mode:
- `text-gray-400` on `bg-gray-900` → passes light mode, fails dark
- `text-blue-600` on `bg-blue-50` → fails WCAG AA (3.8:1)
- Status badges with custom bg/text classes not adapted for dark

### Rule 2 — Keyboard Navigation (WCAG 2.1.1 / 2.1.2 / 2.4.3)

Every action achievable with a mouse must be achievable with a keyboard alone.

```
Tab / Shift+Tab: move focus between interactive elements
Enter / Space: activate buttons and links
Escape: close modals, dropdowns, popovers
Arrow keys: navigate within compound widgets (select, radio group, tabs)
No keyboard traps: Tab must always be able to leave any element
Focus order must match visual reading order
```

```tsx
// ❌ WRONG — div with onClick is not keyboard accessible
<div onClick={handleClick} className="cursor-pointer">Action</div>

// ✅ CORRECT — button is focusable and activates on Enter/Space
<Button onClick={handleClick}>Action</Button>

// ❌ WRONG — custom dropdown with no keyboard support
<div onClick={() => setOpen(!open)}>Menu</div>

// ✅ CORRECT — Radix UI components have keyboard support built in
<DropdownMenu>...</DropdownMenu>
```

### Rule 3 — Focus Indicators (WCAG 2.4.7)

Every focused element must have a visible focus indicator. `outline: none` without a replacement is a WCAG AA failure.

```tsx
// ❌ WRONG — removes focus ring without replacement
<button className="focus:outline-none">

// ✅ CORRECT — visible focus ring using design system
<button className="focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">

// ✅ ALSO CORRECT — shadcn/ui components include focus-visible by default
<Button>  {/* includes focus-visible:ring styling */}
```

Note: `focus:outline-none` is acceptable only when paired with `focus-visible:ring-*` — the `focus` class fires for mouse clicks too, which is intentionally suppressed in modern a11y practice.

### Rule 4 — ARIA Labels (WCAG 4.1.2)

Every interactive element needs an accessible name — either from visible text, `aria-label`, or `aria-labelledby`.

```tsx
// ❌ WRONG — icon button has no accessible name
<Button size="icon" onClick={handleClose}>
  <X className="h-4 w-4" />
</Button>

// ✅ CORRECT — aria-label provides the name
<Button size="icon" onClick={handleClose} aria-label="Close dialog">
  <X className="h-4 w-4" />
</Button>

// ❌ WRONG — input has no label
<Input placeholder="Enter GPA" />

// ✅ CORRECT — label associated
<Label htmlFor="gpa">GPA</Label>
<Input id="gpa" placeholder="Enter GPA" />
```

### Rule 5 — Heading Hierarchy (WCAG 1.3.1 / 2.4.6)

Each page must have exactly one `<h1>`. Headings must not skip levels (h1 → h3 skips h2).

```tsx
// ❌ WRONG — skips h2, two h1s on one page
<h1>Dashboard</h1>
<h1>Your Plan</h1>
<h3>School List</h3>  {/* jumped from h1 to h3 */}

// ✅ CORRECT — one h1, sequential hierarchy
<h1>Your Dashboard</h1>
<h2>Your Plan</h2>
<h3>School List</h3>
```

In shadcn: `CardTitle` renders as `<h3>` by default — check that surrounding headings are h2 or lower.

### Rule 6 — Form Accessibility (WCAG 1.3.1 / 3.3.1 / 3.3.2)

```tsx
// ✅ CORRECT — all form requirements met
<FormField
  control={form.control}
  name="gpa"
  render={({ field }) => (
    <FormItem>
      <FormLabel>GPA (Unweighted)</FormLabel>  {/* visible label */}
      <FormControl>
        <Input {...field} aria-required="true" />
      </FormControl>
      <FormDescription>On a 4.0 scale</FormDescription>
      <FormMessage />  {/* inline error message, auto aria-describedby */}
    </FormItem>
  )}
/>

// ❌ WRONG — missing label, no error association
<input placeholder="GPA" onChange={...} />
{error && <p className="text-red-500">{error}</p>}  {/* not linked to input */}
```

React Hook Form's `<FormMessage />` automatically handles `aria-describedby` linkage. Custom error rendering must set `aria-describedby` manually.

### Rule 7 — Alt Text (WCAG 1.1.1)

```tsx
// ❌ WRONG — missing alt
<img src={school.logo} />

// ✅ CORRECT — descriptive alt
<img src={school.logo} alt={`${school.name} logo`} />

// ✅ CORRECT — decorative image hidden from screen readers
<img src={decoration.svg} alt="" aria-hidden="true" />

// next/image:
<Image src={school.logo} alt={`${school.name} logo`} width={40} height={40} />
```

### Rule 8 — Touch Targets (WCAG 2.5.5)

Every interactive element on mobile must be at least 44×44 CSS pixels.

```tsx
// ❌ WRONG — 32px icon button (h-8 w-8)
<Button size="sm" className="h-8 w-8 p-0">
  <Trash2 className="h-4 w-4" />
</Button>

// ✅ CORRECT — 44px minimum (min-h-[44px] min-w-[44px])
<Button size="icon" className="h-11 w-11">
  <Trash2 className="h-4 w-4" />
</Button>
```

Shadcn's default `size="icon"` is `h-10 w-10` (40px) — technically under 44px. Add `h-11 w-11` override for critical actions.

---

## Phase 1: Establish Scope

```
For /a11y-auditor audit:
1. Find all page and component files:
   find src/app/(app) src/components -name "*.tsx" | grep -v __tests__ | sort
2. Identify high-risk areas:
   - Icon-only buttons (search: "size=\"icon\"")
   - Custom onClick on non-button elements (search: "onClick" without "Button|button")
   - Hard-coded color classes (search: "text-gray-|text-blue-|bg-white|bg-gray-")
   - Forms without FormMessage (search: "<form" and "<Form" missing "<FormMessage")
   - Images without alt (search: "<img " and "<Image ")

For /a11y-auditor validate [file]:
1. Read the specific file
2. Apply all 8 rules
3. Focus on interactive elements, color classes, and heading structure
```

---

## Phase 2: Audit Checks

### 2a — Color Contrast

```
For every text element with explicit color classes:
□ Is it using semantic tokens (text-foreground, text-muted-foreground, text-card-foreground)?
□ If hardcoded (text-gray-X, text-blue-X): calculate contrast ratio in light AND dark mode
□ Normal text (≤18px): 4.5:1 minimum
□ Large text (>18px or bold >14px): 3:1 minimum
□ Status badges, alerts, error messages: all text meets 4.5:1 against their background

Contrast ratio quick reference (light mode):
- text-gray-500 on white: 4.6:1 ✅ (barely passes)
- text-gray-400 on white: 2.85:1 ❌
- text-blue-600 on white: 4.5:1 ✅
- text-blue-500 on white: 3.1:1 ❌ (fails AA)
- text-green-600 on white: 4.0:1 ❌ (fails AA)
- text-red-500 on white: 4.0:1 ❌ (fails AA — use text-red-600 or text-destructive)
```

**Severity:** Contrast failure on body text = P1. Badge/status text failure = P2.

---

### 2b — Keyboard Navigation

```
For every interactive element:
□ Is it a native focusable element (button, a[href], input, select, textarea)?
   OR does it have tabIndex={0} and keyboard event handlers (onKeyDown)?
□ No onClick-only divs or spans without keyboard equivalent?
□ Radix UI components (Dialog, DropdownMenu, Select, Popover) used for complex widgets?
□ Tab order matches left-to-right, top-to-bottom visual reading order?
□ Modal dialogs trap focus (Tab cycles within the modal, not behind it)?
□ Escape key closes all modals, dropdowns, popovers?
□ No tabIndex values > 0 (breaks natural tab order)?
```

**Severity:** onClick div without keyboard = P1. Tab order wrong = P2. Focus trap missing on modal = P1.

---

### 2c — Focus Indicators

```
For every interactive element:
□ Is focus:outline-none present WITHOUT a focus-visible:ring-* replacement?
□ Custom components that replace shadcn buttons: do they inherit focus-visible styles?
□ Focus indicator is visible against the background in both light and dark mode?
□ Focus indicator is not hidden by overflow:hidden on a parent element?
```

**Severity:** Hidden focus indicator on interactive element = P1.

---

### 2d — ARIA Labels

```
For every button, link, and input:
□ Icon-only buttons have aria-label (e.g., aria-label="Close", aria-label="Delete activity")?
□ Icon buttons with tooltips: aria-label still present (tooltip is not an a11y substitute)?
□ All inputs have an associated <label> (via htmlFor/id or aria-label)?
□ Search inputs have aria-label="Search" or visible label?
□ Toggle buttons use aria-pressed={isActive}?
□ Loading states: aria-busy="true" on the loading region?
□ Dynamic content regions: aria-live="polite" where content updates without page reload?
```

**Severity:** Icon button without aria-label = P1. Input without label = P1.

---

### 2e — Heading Hierarchy

```
For every page:
□ Exactly one <h1> (or component that renders as h1)?
□ No heading levels skipped (h1 → h2 → h3, not h1 → h3)?
□ CardTitle components: are they inside a page section with an h2 parent?
   (CardTitle defaults to h3 — ensure an h2 exists above)
□ Section headings use heading elements, not <p className="font-bold text-lg">?
□ Dialog titles are h2 (DialogTitle renders as h2 in shadcn)?
```

**Severity:** Missing h1 = P1. Skipped heading level = P2.

---

### 2f — Form Accessibility

```
For every form:
□ Every field has a visible label (FormLabel or equivalent)?
□ Required fields have aria-required="true" or required attribute?
□ Error messages use <FormMessage /> or equivalent with aria-describedby linkage?
□ Custom error displays (not FormMessage) manually set aria-describedby?
□ Form submit triggers focus move to first field with error on validation failure?
□ Form can be submitted with Enter key (native form behavior)?
□ Disabled fields communicate reason (aria-describedby referencing explanation)?
```

**Severity:** Missing label = P1. Error not linked to input = P2.

---

### 2g — Alt Text

```
For every <img> and <Image> (next/image):
□ Informative images have descriptive alt text (describes content, not just "image")?
□ Decorative images have alt="" and aria-hidden="true"?
□ School logos: alt="{schoolName} logo"?
□ Student-uploaded documents: alt text reflects document type?
□ SVG icons used inline: aria-hidden="true" if purely decorative?
```

**Severity:** Missing alt on informative image = P1. Missing alt="" on decorative = P2.

---

### 2h — Touch Targets

```
For every interactive element, especially on mobile:
□ Minimum 44×44 CSS pixels (h-11 w-11 = 44px in Tailwind)?
□ size="icon" buttons (default 40px): bumped to h-11 w-11 for critical actions?
□ List item action buttons (delete, edit, move): at least 44px?
□ Adequate spacing between adjacent targets (≥8px gap to prevent mis-taps)?
□ Touch targets don't overlap?
```

**Severity:** Touch target < 44px on primary action = P2. Overlapping targets = P2.

---

### 2i — Dynamic Content

```
For sections that update without a page reload:
□ Loading state announced (aria-busy, or aria-live region)?
□ Success/error toasts: are they rendered in an aria-live region?
   (shadcn's Toast/Sonner should handle this — verify it's wired correctly)
□ Route changes: is focus moved to a sensible location after navigation?
□ Modal open: is focus moved to the modal (DialogContent handles this in shadcn)?
□ Accordion expand/collapse: is aria-expanded updated?
```

**Severity:** Errors not announced to screen readers = P2.

---

## Phase 3: Scoring

| Status | Meaning |
|--------|---------|
| ✅ Pass | Meets WCAG 2.1 AA |
| ⚠️ Warning | Best practice gap, not technically failing AA |
| ❌ Fail — P2 | WCAG AA failure, should fix before launch |
| 🔴 Fail — P1 | Hard blocker for users with disabilities (no keyboard access, no labels) |

---

## Common Failure Patterns

| Pattern | Symptom | WCAG | Severity | Check |
|---------|---------|------|----------|-------|
| `focus:outline-none` without `focus-visible:ring` | Keyboard users lose track of focus position | 2.4.7 | P1 | 2c |
| Icon button without `aria-label` | Screen reader says "button" with no context | 4.1.2 | P1 | 2d |
| Input without label | Screen reader can't identify field purpose | 1.3.1 | P1 | 2f |
| `text-gray-400` body text | Fails 4.5:1 contrast (2.85:1 on white) | 1.4.3 | P1 | 2a |
| `text-green-600` success text | Fails 4.5:1 contrast (4.0:1 on white) | 1.4.3 | P1 | 2a |
| `<div onClick>` without keyboard | Mouse-only interaction | 2.1.1 | P1 | 2b |
| h1 → h3 skip | Screen reader navigation broken | 1.3.1 | P2 | 2e |
| h-8 w-8 icon button | 32px touch target (below 44px minimum) | 2.5.5 | P2 | 2h |
| No alt text on school logo | Screen reader says "image" | 1.1.1 | P1 | 2g |
| FormMessage missing | Error not announced or linked to field | 3.3.1 | P2 | 2f |

---

## Output Format

```
## A11y Auditor: /a11y-auditor [mode] [target]

### Mode
[audit | validate | fix | focus]

### Files Audited
[N pages, N components]

### Findings
| File | Check | Status | Issue |
|------|-------|--------|-------|
| components/schools/SchoolCard.tsx | ARIA labels | ❌ P1 | Bookmark icon button missing aria-label |
| app/(app)/onboarding/academics/page.tsx | Heading hierarchy | ⚠️ Warning | CardTitle inside section without h2 parent |
| components/plan/ActionPlan.tsx | Color contrast | ❌ P1 | text-gray-400 on light background (2.85:1) |

### Issues Found
| Severity | WCAG | File | Description | Fix |
|----------|------|------|-------------|-----|
| P1 | 4.1.2 | SchoolCard.tsx | Bookmark button no aria-label | Add aria-label="Save school" |
| P1 | 1.4.3 | ActionPlan.tsx | text-gray-400 fails contrast | Change to text-muted-foreground |

### Changes Made
| File | Action |
|------|--------|

### WCAG 2.1 AA Compliance Summary
| Criterion | Status | Failures |
|-----------|--------|----------|
| 1.1.1 Alt Text | ✅ | 0 |
| 1.4.3 Contrast | ❌ | 2 |
| 2.1.1 Keyboard | ✅ | 0 |
| 2.4.7 Focus Visible | ❌ | 1 |
| 4.1.2 ARIA Labels | ❌ | 3 |

### Summary
✅ [N] checks pass · ❌ [N] WCAG failures · [N] filed as GitHub issues
```

---

## When to Escalate

Stop and ask if:
- A contrast failure is in a design token itself (requires design system change, not just a class swap)
- A keyboard navigation fix requires restructuring a complex component (tabs, custom select)
- Focus management in a wizard flow requires coordinating across multiple route changes
- A component library (shadcn) has a built-in accessibility bug (report upstream, workaround locally)

---

## Key References

- WCAG 2.1 AA criteria: https://www.w3.org/WAI/WCAG21/quickref/?levels=aa
- Contrast checker: https://webaim.org/resources/contrastchecker/
- `src/components/ui/` — shadcn primitives with built-in a11y (Button, Dialog, FormMessage, etc.)
- `src/lib/config/accessibility.ts` — the project accessibility config
- Tailwind focus-visible pattern: `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2`
- PATTERNS.md — for general code quality standards
