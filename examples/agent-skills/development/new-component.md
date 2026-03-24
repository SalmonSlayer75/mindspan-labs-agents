# /new-component Skill

This skill creates a complete, accessible React component with tests.

## Agent Chain

```
architect → component-builder → security-reviewer → test-writer
```

## What It Does

1. **architect** — Reviews component design against patterns
2. **component-builder** — Generates React component with accessibility
3. **security-reviewer** — Audits for data handling and display
4. **test-writer** — Creates unit tests

## Usage

```
/new-component [ComponentName] [description]
```

## Examples

```
/new-component SchoolCard Display school with fit indicator and estimated cost

/new-component ActivityCard Show activity with hours, years, and edit options

/new-component GPATrendChart Visualize GPA trajectory over time

/new-component CoachMessage Display coach insight with action buttons

/new-component OnboardingProgress Show progress through 8 onboarding phases

/new-component SchoolSwipeCard Tinder-style card for school discovery
```

## Output Structure

```
components/
└── [ComponentName]/
    ├── index.ts                    # Re-export
    ├── [ComponentName].tsx         # Main component
    ├── [ComponentName].test.tsx    # Unit tests
    └── types.ts                    # TypeScript interfaces
```

## Generated Files

### index.ts
```typescript
export { ComponentName } from './ComponentName';
export type { ComponentNameProps } from './types';
```

### types.ts
```typescript
export interface ComponentNameProps {
  // Props based on description
}
```

### ComponentName.tsx
```typescript
import React from 'react';
import type { ComponentNameProps } from './types';

export const ComponentName: React.FC<ComponentNameProps> = (props) => {
  // Implementation with:
  // - Proper accessibility attributes
  // - Keyboard support
  // - Loading and error states
};

ComponentName.displayName = 'ComponentName';
```

### ComponentName.test.tsx
```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ComponentName } from './ComponentName';

describe('ComponentName', () => {
  it('renders correctly', () => { /* ... */ });
  it('handles user interaction', async () => { /* ... */ });
  it('is keyboard accessible', async () => { /* ... */ });
});
```

## Accessibility Requirements

Every component created includes:

- [x] Semantic HTML elements
- [x] Keyboard navigation (Tab, Enter, Space, Escape)
- [x] Focus indicators (visible, not removed)
- [x] ARIA attributes where needed
- [x] Color contrast (4.5:1 minimum)
- [x] Screen reader support
- [x] Reduced motion support

## Component Template

```typescript
'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export interface SchoolCardProps {
  school: {
    id: string;
    name: string;
    location: string;
    fitCategory: 'reach' | 'target' | 'likely';
    estimatedCost: number;
  };
  onAddToList?: () => void;
  onRemove?: () => void;
  className?: string;
}

export const SchoolCard: React.FC<SchoolCardProps> = ({
  school,
  onAddToList,
  onRemove,
  className,
}) => {
  return (
    <article
      className={cn(
        'rounded-lg border bg-card p-4 shadow-sm',
        className
      )}
      aria-labelledby={`school-${school.id}-name`}
    >
      <header>
        <h3
          id={`school-${school.id}-name`}
          className="text-lg font-semibold"
        >
          {school.name}
        </h3>
        <p className="text-sm text-muted-foreground">
          {school.location}
        </p>
      </header>

      <div className="mt-4 flex items-center justify-between">
        <FitBadge category={school.fitCategory} />
        <span className="text-sm">
          ~${school.estimatedCost.toLocaleString()}/yr
        </span>
      </div>

      {(onAddToList || onRemove) && (
        <footer className="mt-4 flex gap-2">
          {onAddToList && (
            <Button
              variant="outline"
              size="sm"
              onClick={onAddToList}
              aria-label={`Add ${school.name} to your list`}
            >
              Add to List
            </Button>
          )}
          {onRemove && (
            <Button
              variant="ghost"
              size="sm"
              onClick={onRemove}
              aria-label={`Remove ${school.name}`}
            >
              Remove
            </Button>
          )}
        </footer>
      )}
    </article>
  );
};

SchoolCard.displayName = 'SchoolCard';
```

## Checklist (Auto-Verified)

- [ ] TypeScript types defined
- [ ] Semantic HTML used
- [ ] ARIA attributes where needed
- [ ] Keyboard accessible
- [ ] Focus states visible
- [ ] Loading state (if async)
- [ ] Error state (if applicable)
- [ ] Responsive design
- [ ] Unit tests written
- [ ] No sensitive data displayed without redaction

## the project Component Patterns

### Data Display Components
- Always show data freshness for school info ("as of Oct 2024")
- Use consistent fit indicators (Reach/Target/Likely)
- Show financial fit with clear color coding

### Interactive Components
- Support both click and keyboard
- Provide clear feedback on actions
- Include undo for destructive actions

### Coach Components
- Use the brand voice (warm but direct)
- Include action + dismiss options
- Never display essay content user didn't write

### Form Components
- Validate on blur, not just submit
- Show inline errors
- Support both upload and manual entry paths

## Workflow

```
User: /new-component SchoolCard Display school with fit indicator and cost

Claude:
1. [architect] Reviewing component design...
   ✅ Follows card pattern
   ✅ Data display compliant

2. [component-builder] Generating component...
   Created: components/SchoolCard/index.ts
   Created: components/SchoolCard/SchoolCard.tsx
   Created: components/SchoolCard/types.ts
   ✅ Accessibility attributes added
   ✅ Keyboard support included

3. [security-reviewer] Auditing...
   ✅ No sensitive data exposed
   ✅ User actions require confirmation

4. [test-writer] Creating tests...
   Created: components/SchoolCard/SchoolCard.test.tsx
   ✅ Render tests
   ✅ Interaction tests
   ✅ Accessibility tests

✅ Component ready at components/SchoolCard/
```

## Integration

After running this skill:

1. Import the component where needed
2. Review and adjust styling to match design
3. Run tests: `npm test components/[Name]/[Name].test.tsx`
4. Add to Storybook if applicable

---

**Note:** All components follow accessibility best practices by default. The security-reviewer ensures no sensitive student data is displayed inappropriately.
