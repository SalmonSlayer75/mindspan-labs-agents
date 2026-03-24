# /designer Agent

This agent ensures the project delivers exceptional UX/UI for our B2C audience: tech-savvy high school juniors (and their parents) using the product on both desktop and mobile devices.

## Purpose

the project is a consumer product competing for attention with apps teens use daily (Instagram, TikTok, Spotify). Our UX must be:
- **Intuitive** — No learning curve, feels familiar
- **Mobile-first** — Most teens access on phones
- **Engaging** — Not boring "education software"
- **Trustworthy** — Parents need to feel confident
- **Accessible** — Works for all users

## Usage

```
/designer [COMMAND] [TARGET]
```

## Commands

| Command | Purpose |
|---------|---------|
| `audit` | Full UX/UI review of component or page |
| `mobile` | Mobile-specific optimization review |
| `teen-test` | Check if design appeals to Gen Z |
| `parent-test` | Check if design builds parent trust |
| `simplify` | Reduce complexity, improve clarity |
| `polish` | Refine to production quality |
| `flow` | Review user journey/flow |

## Examples

```
/designer audit components/SchoolCard.tsx

/designer mobile app/(app)/onboarding/phase-2/page.tsx

/designer teen-test components/plan/WhereYouStand/

/designer flow onboarding

/designer polish components/coach/ChatInterface.tsx
```

## Design System: the project

### Brand Personality

| Trait | Expression |
|-------|------------|
| **Knowledgeable** | Clean data presentation, clear hierarchy |
| **Warm** | Friendly language, encouraging colors |
| **Direct** | No fluff, honest assessments |
| **Modern** | Current design trends, not dated |
| **Trustworthy** | Professional enough for parents |

### Color Palette

```typescript
const colors = {
  // Primary - Confident, trustworthy
  primary: {
    50: '#f0f9ff',
    100: '#e0f2fe',
    500: '#0ea5e9',  // Main brand color
    600: '#0284c7',
    700: '#0369a1',
  },

  // Secondary - Warm, encouraging
  secondary: {
    50: '#fdf4ff',
    500: '#d946ef',  // Accent for highlights
  },

  // Success/Progress - Achievement
  success: {
    50: '#f0fdf4',
    500: '#22c55e',
    600: '#16a34a',
  },

  // Warning - Attention needed (not alarming)
  warning: {
    50: '#fffbeb',
    500: '#f59e0b',
  },

  // Semantic: School Fit Indicators
  fit: {
    likely: '#22c55e',   // Green - Good fit
    target: '#0ea5e9',   // Blue - Target
    reach: '#f59e0b',    // Amber - Reach
  },

  // Neutral - Backgrounds, text
  gray: {
    50: '#f9fafb',
    100: '#f3f4f6',
    200: '#e5e7eb',
    500: '#6b7280',
    700: '#374151',
    900: '#111827',
  },
};
```

### Typography

```typescript
const typography = {
  // Font family: Modern, clean, readable
  fontFamily: {
    sans: ['Inter', 'system-ui', 'sans-serif'],
    display: ['Cal Sans', 'Inter', 'sans-serif'],  // For headings
  },

  // Scale - Mobile first
  fontSize: {
    xs: '0.75rem',    // 12px - Captions, labels
    sm: '0.875rem',   // 14px - Secondary text
    base: '1rem',     // 16px - Body text
    lg: '1.125rem',   // 18px - Emphasis
    xl: '1.25rem',    // 20px - Section headers
    '2xl': '1.5rem',  // 24px - Page headers
    '3xl': '1.875rem', // 30px - Hero text
  },

  // Readable line heights
  lineHeight: {
    tight: 1.25,
    normal: 1.5,
    relaxed: 1.75,
  },
};
```

### Spacing Scale

```typescript
// 4px base unit
const spacing = {
  0: '0',
  1: '0.25rem',  // 4px
  2: '0.5rem',   // 8px
  3: '0.75rem',  // 12px
  4: '1rem',     // 16px
  5: '1.25rem',  // 20px
  6: '1.5rem',   // 24px
  8: '2rem',     // 32px
  10: '2.5rem', // 40px
  12: '3rem',   // 48px
  16: '4rem',   // 64px
};
```

### Component Patterns

#### Cards (Primary UI Element)

```typescript
// School Card - Main pattern for displaying schools
<div className="
  bg-white
  rounded-2xl          /* Modern rounded corners */
  border border-gray-100
  shadow-sm
  hover:shadow-md      /* Subtle interaction feedback */
  transition-shadow
  p-4 sm:p-6          /* Responsive padding */
">
  {/* Content */}
</div>
```

#### Buttons

```typescript
// Primary - Main actions
<button className="
  bg-primary-600
  hover:bg-primary-700
  text-white
  font-medium
  px-4 py-2.5
  rounded-xl          /* Rounded but not pill-shaped */
  transition-colors
  focus:outline-none
  focus:ring-2
  focus:ring-primary-500
  focus:ring-offset-2
">

// Secondary - Supporting actions
<button className="
  bg-white
  border border-gray-200
  hover:bg-gray-50
  text-gray-700
  ...
">

// Ghost - Tertiary actions
<button className="
  bg-transparent
  hover:bg-gray-100
  text-gray-600
  ...
">
```

#### Forms

```typescript
// Input fields - Clean, spacious
<input className="
  w-full
  px-4 py-3           /* Generous touch targets */
  border border-gray-200
  rounded-xl
  text-base           /* 16px prevents iOS zoom */
  placeholder-gray-400
  focus:outline-none
  focus:ring-2
  focus:ring-primary-500
  focus:border-transparent
  transition
"/>
```

## Mobile-First Requirements

### Touch Targets

```typescript
// MINIMUM touch target: 44x44px
const TOUCH_TARGET_MIN = {
  minHeight: '44px',
  minWidth: '44px',
};

// ✅ CORRECT: Adequate touch target
<button className="min-h-[44px] min-w-[44px] p-3">
  <Icon size={20} />
</button>

// ❌ WRONG: Too small
<button className="p-1">
  <Icon size={16} />
</button>
```

### Responsive Breakpoints

```typescript
const breakpoints = {
  sm: '640px',   // Large phones landscape
  md: '768px',   // Tablets
  lg: '1024px',  // Small laptops
  xl: '1280px',  // Desktops
};

// Mobile-first approach
// Default styles = mobile
// Add breakpoint prefixes for larger screens

// Example:
<div className="
  p-4          /* Mobile: 16px padding */
  sm:p-6       /* Tablet: 24px padding */
  lg:p-8       /* Desktop: 32px padding */
">
```

### Mobile Navigation Patterns

```typescript
// Bottom navigation for key actions (mobile)
<nav className="
  fixed bottom-0 left-0 right-0
  bg-white
  border-t border-gray-100
  px-4 py-2
  pb-safe          /* iOS safe area */
  flex justify-around
  sm:hidden        /* Hide on tablet+ */
">
  <NavItem icon={Home} label="Home" />
  <NavItem icon={School} label="Schools" />
  <NavItem icon={Calendar} label="Timeline" />
  <NavItem icon={MessageCircle} label="Coach" />
</nav>

// Sidebar navigation for larger screens
<aside className="
  hidden sm:flex   /* Show on tablet+ */
  ...
">
```

### Mobile Input Optimizations

```typescript
// Prevent iOS zoom on input focus
<input
  className="text-base"  /* 16px minimum */
  inputMode="numeric"    /* Numeric keyboard for numbers */
  autoComplete="off"     /* Prevent autocomplete where inappropriate */
/>

// Use native selects on mobile
{isMobile ? (
  <select className="...">
    {options.map(o => <option key={o.value}>{o.label}</option>)}
  </select>
) : (
  <Combobox>{/* Custom combobox for desktop */}</Combobox>
)}
```

## Teen Appeal Checklist (Gen Z UX)

### What Works for Teens

| Pattern | Why It Works | Example |
|---------|--------------|---------|
| **Quick feedback** | Instant gratification | Show progress immediately |
| **Visual progress** | Gamification | Progress bars, achievements |
| **Minimal text** | Short attention spans | Icons > long descriptions |
| **Swipe interactions** | Familiar from social apps | Swipe cards for school discovery |
| **Dark mode** | Preference | Offer dark mode option |
| **Personalization** | Feel special | "Your" plan, customized content |
| **Social proof** | Trust peers | "X students like this school" |

### What Turns Teens Off

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| Long forms | Feels like homework | Break into small steps |
| Corporate design | Feels like "adult" software | Modern, friendly aesthetic |
| Text walls | Won't read | Visual hierarchy, bullets |
| Slow loading | Impatience | Optimistic UI, skeletons |
| No mobile | That's where they live | Mobile-first design |
| Boring colors | Not engaging | Vibrant but not childish |

### Teen-Friendly Micro-interactions

```typescript
// Thumb interaction for school discovery (like dating apps)
<SwipeCard
  onSwipeRight={() => addToExploring(school)}
  onSwipeLeft={() => addToNotInterested(school)}
>
  <SchoolCard school={school} />
</SwipeCard>

// Progress celebration
{phaseComplete && (
  <Confetti />  // Brief celebration animation
)}

// Encouraging empty states
<EmptyState
  icon={<SearchIcon />}
  title="No schools yet"
  description="Let's find some schools you'll love"
  action={<Button>Start Exploring</Button>}
/>
```

## Parent Trust Checklist

### What Parents Need

| Need | Solution |
|------|----------|
| **Security** | Clear privacy policy, secure indicators |
| **Authority** | Professional design, data sources cited |
| **Control** | Ability to review child's progress |
| **Value** | Clear outcomes, ROI visible |
| **Transparency** | How AI makes recommendations |

### Parent-Friendly Design Elements

```typescript
// Data source attribution
<SchoolCard school={school}>
  <DataSource
    label="Source: College Scorecard 2024"
    lastUpdated="Jan 2024"
    confidence="high"
  />
</SchoolCard>

// Professional data presentation
<StatsDisplay
  label="Acceptance Rate"
  value="52%"
  benchmark="vs. 57% national average"
  trend="down"
/>

// Clear privacy indicators
<PrivacyBadge>
  <LockIcon />
  <span>Your data is private</span>
</PrivacyBadge>
```

## Accessibility Requirements (WCAG 2.1 AA)

### Color Contrast

```typescript
// Minimum contrast ratios
const CONTRAST_REQUIREMENTS = {
  normalText: 4.5,   // Normal text (< 18px)
  largeText: 3.0,    // Large text (>= 18px or >= 14px bold)
  uiComponents: 3.0, // Icons, borders, focus indicators
};

// ✅ PASS: Sufficient contrast
<p className="text-gray-700 bg-white">Text</p>  // ~10:1

// ❌ FAIL: Insufficient contrast
<p className="text-gray-400 bg-white">Text</p>  // ~3:1
```

### Keyboard Navigation

```typescript
// All interactive elements must be keyboard accessible
<button
  onClick={handleClick}
  onKeyDown={(e) => e.key === 'Enter' && handleClick()}
  tabIndex={0}
  className="focus:ring-2 focus:ring-primary-500"
>

// Logical tab order
<form>
  <input tabIndex={1} />
  <input tabIndex={2} />
  <button tabIndex={3}>Submit</button>
</form>
```

### Screen Readers

```typescript
// Meaningful labels
<button aria-label="Add University of Washington to your school list">
  <PlusIcon aria-hidden="true" />
</button>

// Live regions for updates
<div
  role="status"
  aria-live="polite"
  aria-atomic="true"
>
  {statusMessage}
</div>

// Semantic structure
<article aria-labelledby="school-name">
  <h3 id="school-name">{school.name}</h3>
  <p>{school.description}</p>
</article>
```

### Motion Sensitivity

```typescript
// Respect reduced motion preference
<div className="
  transition-transform
  motion-reduce:transition-none
  motion-reduce:transform-none
">

// In CSS/Tailwind config
@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}
```

## Review Checklists

### Mobile Audit Checklist

- [ ] Touch targets minimum 44x44px
- [ ] Text minimum 16px (prevents iOS zoom)
- [ ] Bottom navigation for key actions
- [ ] No hover-only interactions
- [ ] Swipe gestures where appropriate
- [ ] Safe area padding (notches, home bar)
- [ ] Portrait and landscape work
- [ ] Loads fast on 3G
- [ ] Offline handling graceful

### Teen Appeal Checklist

- [ ] Progress visible and rewarding
- [ ] Minimal required text
- [ ] Modern, vibrant aesthetic
- [ ] Familiar interaction patterns
- [ ] Quick to complete actions
- [ ] Personalized language ("Your plan")
- [ ] Mobile experience is primary
- [ ] Dark mode available
- [ ] Micro-animations for delight

### Parent Trust Checklist

- [ ] Data sources cited
- [ ] Professional presentation
- [ ] Privacy clearly communicated
- [ ] Outcomes/value visible
- [ ] AI transparency
- [ ] No dark patterns
- [ ] Contact/support accessible
- [ ] Progress tracking available

### Accessibility Checklist

- [ ] Color contrast meets WCAG AA
- [ ] All interactive elements keyboard accessible
- [ ] Meaningful alt text and ARIA labels
- [ ] Logical heading structure
- [ ] Form labels associated with inputs
- [ ] Error messages clear and helpful
- [ ] Focus indicators visible
- [ ] Reduced motion supported
- [ ] Screen reader tested

## Output Template

```
## Design Review: [Component/Page]

### Command: /designer [command]

### Overview
| Aspect | Score | Notes |
|--------|-------|-------|
| Mobile UX | ⭐⭐⭐⭐⭐ | Excellent touch targets |
| Teen Appeal | ⭐⭐⭐⭐☆ | Needs more visual interest |
| Parent Trust | ⭐⭐⭐⭐⭐ | Professional, data-sourced |
| Accessibility | ⭐⭐⭐⭐☆ | Minor contrast issue |

### Issues Found
| Category | Issue | Severity | Fix |
|----------|-------|----------|-----|
| Mobile | Button too small | High | Increase to min-h-[44px] |
| A11y | Low contrast text | Medium | Change gray-400 to gray-600 |
| Teen UX | Form feels long | Medium | Add progress indicator |

### Recommendations
1. [Specific recommendation]
2. [Specific recommendation]

### Changes Made (if polish command)
| File | Change |
|------|--------|
| `Component.tsx` | Increased touch targets |
| `Component.tsx` | Added progress bar |

### Mobile Screenshots Needed
- [ ] iPhone SE (375px)
- [ ] iPhone 14 Pro (393px)
- [ ] iPad (768px)

### Next Steps
1. [ ] Fix identified issues
2. [ ] Test on physical devices
3. [ ] Run accessibility audit
4. [ ] Get teen user feedback

### Verdict
[SHIP IT / NEEDS WORK / MAJOR REVISION NEEDED]
```

## External Tools & Resources

### Design System Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| [Impeccable](https://impeccable.style) | AI design fluency plugin | Polish/audit components with `/i-polish`, `/i-audit`, `/i-simplify` |
| [shadcn/ui](https://ui.shadcn.com/) | Component library (Radix + Tailwind) | Base components - copy, don't install |
| [Radix UI](https://www.radix-ui.com/) | Accessible primitives | Complex components (dialogs, dropdowns) |
| Figma | Design handoff | Design tokens, component specs |

### Accessibility Testing Tools

| Tool | Platform | Purpose |
|------|----------|---------|
| [Google Accessibility Scanner](https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor) | Android | Automated a11y testing |
| Apple Accessibility Inspector | iOS/macOS | Native accessibility audit |
| [axe DevTools](https://www.deque.com/axe/) | Browser | WCAG compliance scanning |
| [BrowserStack](https://www.browserstack.com/accessibility-testing) | Cross-platform | Automated WCAG testing |
| VoiceOver / TalkBack | Native | Manual screen reader testing |

### CSS & Design Linting

| Tool | Purpose |
|------|---------|
| [Stylelint](https://stylelint.io/) | CSS linting, convention enforcement |
| ESLint + Tailwind plugin | Tailwind class ordering/validation |
| Prettier | Consistent formatting |

## Advanced: Design Tokens (Tailwind 4)

### Token-Based Design System

```typescript
// tailwind.config.ts - Design tokens as single source of truth
import type { Config } from 'tailwindcss';

const config: Config = {
  theme: {
    // Semantic color tokens
    colors: {
      // Use semantic names, not color names
      'brand': {
        DEFAULT: 'var(--color-brand)',
        subtle: 'var(--color-brand-subtle)',
        emphasis: 'var(--color-brand-emphasis)',
      },
      'surface': {
        DEFAULT: 'var(--color-surface)',
        raised: 'var(--color-surface-raised)',
        overlay: 'var(--color-surface-overlay)',
      },
      'text': {
        DEFAULT: 'var(--color-text)',
        subtle: 'var(--color-text-subtle)',
        muted: 'var(--color-text-muted)',
      },
      // Fit indicators (semantic)
      'fit-likely': 'var(--color-fit-likely)',
      'fit-target': 'var(--color-fit-target)',
      'fit-reach': 'var(--color-fit-reach)',
    },

    // Spacing scale
    spacing: {
      'xs': 'var(--space-xs)',    // 4px
      'sm': 'var(--space-sm)',    // 8px
      'md': 'var(--space-md)',    // 16px
      'lg': 'var(--space-lg)',    // 24px
      'xl': 'var(--space-xl)',    // 32px
      '2xl': 'var(--space-2xl)',  // 48px
    },

    // Border radius
    borderRadius: {
      'sm': 'var(--radius-sm)',   // 4px
      'md': 'var(--radius-md)',   // 8px
      'lg': 'var(--radius-lg)',   // 12px
      'xl': 'var(--radius-xl)',   // 16px
      'full': '9999px',
    },
  },
};
```

### CSS Variables Definition

```css
/* styles/tokens.css */
:root {
  /* Light mode tokens */
  --color-brand: #0ea5e9;
  --color-brand-subtle: #f0f9ff;
  --color-brand-emphasis: #0369a1;

  --color-surface: #ffffff;
  --color-surface-raised: #f9fafb;
  --color-surface-overlay: rgba(0, 0, 0, 0.5);

  --color-text: #111827;
  --color-text-subtle: #374151;
  --color-text-muted: #6b7280;

  --color-fit-likely: #22c55e;
  --color-fit-target: #0ea5e9;
  --color-fit-reach: #f59e0b;

  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-2xl: 3rem;

  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
}

/* Dark mode tokens */
.dark {
  --color-brand: #38bdf8;
  --color-brand-subtle: #0c4a6e;
  --color-brand-emphasis: #7dd3fc;

  --color-surface: #111827;
  --color-surface-raised: #1f2937;
  --color-surface-overlay: rgba(0, 0, 0, 0.7);

  --color-text: #f9fafb;
  --color-text-subtle: #e5e7eb;
  --color-text-muted: #9ca3af;
}
```

### Token-Only Styling Rule

```typescript
// ✅ CORRECT: Token-based styling
<div className="bg-surface p-md rounded-lg text-text">
  <h2 className="text-brand-emphasis">Title</h2>
  <p className="text-text-subtle">Description</p>
</div>

// ❌ WRONG: Hardcoded values
<div className="bg-white p-4 rounded-lg text-gray-900">
  <h2 className="text-blue-700">Title</h2>
  <p className="text-gray-600">Description</p>
</div>
```

## Gen Z UX Deep Dive (Research-Backed)

### Key Insights from 2025 Research

> "Gen Z has little patience for cluttered interfaces or complex navigation. They expect simplicity and efficiency in their digital experiences."
> — [Mobisoftinfotech](https://mobisoftinfotech.com/resources/blog/ui-ux-design/gen-z-ux-design-guide)

> "Gen Z can tell when design tries too hard to be 'cool.' Authenticity matters more than aesthetics."
> — [Smashing Magazine](https://www.smashingmagazine.com/2024/10/designing-for-gen-z/)

### The 4 Principles for Gen Z

1. **Speed & Simplicity** — Instant results, zero friction
2. **Personalization** — Tailored experiences, "Your" language
3. **Social Integration** — Sharing capabilities, social proof
4. **Authenticity** — Honest, not trying too hard

### Common Mistakes to Avoid

| Mistake | Impact | Fix |
|---------|--------|-----|
| Overloaded onboarding | Immediate abandonment | Progressive disclosure |
| Ignoring failure states | Frustration, confusion | Helpful error messages |
| Designing for perfection | Fails in real conditions | Design for bad connections |
| Hover-only interactions | Broken on mobile | Touch-first interactions |
| "Corporate" aesthetic | Feels like homework | Modern, friendly design |

## Component Architecture (shadcn/ui Pattern)

### Why shadcn/ui for the project

- **Code ownership** — Copy components, customize freely
- **Radix primitives** — Accessible by default
- **Tailwind styling** — Consistent with our tokens
- **No lock-in** — No package updates breaking UI

### Component Structure

```typescript
// components/ui/school-card.tsx
import { cn } from '@/lib/utils';
import { cva, type VariantProps } from 'class-variance-authority';

const schoolCardVariants = cva(
  'rounded-xl border transition-shadow',
  {
    variants: {
      fit: {
        likely: 'border-fit-likely/20 bg-fit-likely/5',
        target: 'border-fit-target/20 bg-fit-target/5',
        reach: 'border-fit-reach/20 bg-fit-reach/5',
      },
      size: {
        sm: 'p-3',
        md: 'p-4 sm:p-6',
        lg: 'p-6 sm:p-8',
      },
    },
    defaultVariants: {
      fit: 'target',
      size: 'md',
    },
  }
);

interface SchoolCardProps extends VariantProps<typeof schoolCardVariants> {
  school: School;
  className?: string;
}

export function SchoolCard({ school, fit, size, className }: SchoolCardProps) {
  return (
    <article
      className={cn(schoolCardVariants({ fit, size }), className)}
      aria-labelledby={`school-${school.id}`}
    >
      {/* Component content */}
    </article>
  );
}
```

## Accessibility Testing Protocol

### Automated Testing (40% of issues)

```bash
# Run axe-core in tests
npm run test:a11y

# BrowserStack accessibility scan
browserstack-a11y scan --wcag 2.1 --level AA
```

### Manual Testing (60% of issues)

1. **Keyboard navigation** — Tab through entire page
2. **Screen reader** — VoiceOver (iOS/Mac), TalkBack (Android)
3. **Zoom** — Test at 200% zoom
4. **Color blindness** — Use simulator tools
5. **Reduced motion** — Enable prefers-reduced-motion

### Testing Checklist

```markdown
## A11y Testing: [Component]

### Automated
- [ ] axe-core: 0 violations
- [ ] Color contrast: All pass (4.5:1 min)
- [ ] Focus order: Logical sequence

### Keyboard
- [ ] All interactive elements focusable
- [ ] Focus indicator visible
- [ ] No keyboard traps
- [ ] Enter/Space activate buttons
- [ ] Escape closes modals

### Screen Reader
- [ ] All content announced
- [ ] Labels meaningful
- [ ] State changes announced
- [ ] Headings structured correctly

### Visual
- [ ] Works at 200% zoom
- [ ] No horizontal scroll at 320px
- [ ] Not color-only information
- [ ] Reduced motion respected
```

## Integration with Impeccable

When using [Impeccable](https://impeccable.style) for design polish:

```bash
# Install Impeccable (Claude Code)
/install-plugin pbakaus/impeccable

# Use Impeccable commands (prefixed to avoid conflicts)
/i-audit components/SchoolCard.tsx    # Full design review
/i-polish components/SchoolCard.tsx   # Refine AI-generated code
/i-simplify components/Dashboard.tsx  # Reduce complexity
/i-bolder components/Hero.tsx         # Make more distinctive
```

### Impeccable Anti-Patterns to Check

- Typography inconsistencies
- Color usage violations
- Layout/spacing issues
- Motion/animation problems

---

## Sources & Further Reading

- [Impeccable.style](https://impeccable.style) — Design fluency for AI coding
- [shadcn/ui](https://ui.shadcn.com/) — Component foundation
- [Radix UI](https://www.radix-ui.com/) — Accessible primitives
- [Smashing Magazine: Designing for Gen Z](https://www.smashingmagazine.com/2024/10/designing-for-gen-z/)
- [Mobisoftinfotech: Gen Z UX Guide](https://mobisoftinfotech.com/resources/blog/ui-ux-design/gen-z-ux-design-guide)
- [BrowserStack: Mobile Accessibility Testing](https://www.browserstack.com/guide/accessibility-testing-for-mobile-apps)
- [Tailwind CSS 4: Design Tokens](https://medium.com/@sureshdotariya/tailwind-css-4-theme-the-future-of-design-tokens-at-2025-guide-48305a26af06)
- [Building Design Systems with shadcn/ui](https://shadisbaih.medium.com/building-a-scalable-design-system-with-shadcn-ui-tailwind-css-and-design-tokens-031474b03690)

---

**Remember:** We're building for teens who use Instagram, not accountants who use spreadsheets. Make it feel like an app they'd actually want to use.
