# /new-endpoint Skill

This skill creates a complete, production-ready API endpoint by chaining multiple agents.

## Agent Chain

```
architect → api-scaffold → security-reviewer → test-writer
```

## What It Does

1. **architect** — Reviews the endpoint design against ADRs and patterns
2. **api-scaffold** — Generates Next.js API route with Zod validation
3. **security-reviewer** — Audits for privacy, auth, and data handling
4. **test-writer** — Generates API tests

## Usage

```
/new-endpoint [METHOD] [PATH] [DESCRIPTION]
```

## Examples

```
/new-endpoint POST /api/students/profile Create student profile

/new-endpoint GET /api/schools/{id} Get school details by ID

/new-endpoint PUT /api/students/activities/{id} Update an activity

/new-endpoint DELETE /api/students/schools/{id} Remove school from list

/new-endpoint POST /api/coach/message Send message to AI coach
```

## Output Structure

When you invoke this skill, you'll receive:

### 1. Architecture Review
- ADR compliance check
- Pattern compliance check
- Cross-system impact analysis

### 2. Generated Code

```
app/api/
└── [resource]/
    ├── route.ts           # Main route handler (GET, POST)
    └── [id]/
        └── route.ts       # Dynamic route handler (GET, PUT, DELETE)

lib/
└── validators/
    └── [resource].ts      # Zod schemas
```

### 3. Security Review
- User authentication check
- Query scoping verification
- Sensitive data handling audit
- Input validation check

### 4. Generated Tests

```
tests/api/
└── [resource].test.ts     # API route tests
```

## Route Handler Template

```typescript
// app/api/students/profile/route.ts
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import { StudentProfileSchema } from '@/lib/validators/student';

export async function POST(request: Request) {
  try {
    // 1. Auth check
    const supabase = createRouteHandlerClient({ cookies });
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json(
        { success: false, error: { code: 'UNAUTHORIZED' } },
        { status: 401 }
      );
    }

    // 2. Input validation
    const body = await request.json();
    const result = StudentProfileSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: result.error.issues[0].message,
          field: result.error.issues[0].path[0],
        }
      }, { status: 400 });
    }

    // 3. Business logic (user-scoped)
    const { data, error } = await supabase
      .from('student_profiles')
      .insert({
        ...result.data,
        user_id: user.id,  // REQUIRED: user scoping
      })
      .select()
      .single();

    if (error) {
      console.error('Database error:', { code: error.code });  // No sensitive data
      return NextResponse.json(
        { success: false, error: { code: 'DATABASE_ERROR' } },
        { status: 500 }
      );
    }

    // 4. Success response
    return NextResponse.json({ success: true, data });

  } catch (error) {
    console.error('Unexpected error:', error);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR' } },
      { status: 500 }
    );
  }
}
```

## Checklist (Auto-Verified)

- [ ] Authentication check present
- [ ] User scoping on all queries
- [ ] Zod validation for input
- [ ] No sensitive data in logs
- [ ] Standard response format
- [ ] Error handling for all cases
- [ ] Tests cover success and error paths

## the project-Specific Endpoints

Common endpoint patterns for the project:

### Student Profile
- `POST /api/students/profile` — Create profile
- `GET /api/students/profile` — Get current user's profile
- `PUT /api/students/profile` — Update profile

### Academics (Phase 2)
- `POST /api/students/transcript` — Upload transcript for extraction
- `GET /api/students/courses` — Get extracted courses
- `PUT /api/students/courses/{id}` — Edit a course

### Activities (Phase 3)
- `POST /api/students/resume` — Upload resume for extraction
- `GET /api/students/activities` — Get activities
- `POST /api/students/activities` — Add activity manually
- `PUT /api/students/activities/{id}` — Edit activity

### Schools
- `GET /api/schools` — Search schools
- `GET /api/schools/{id}` — Get school details
- `POST /api/students/schools` — Add school to list
- `PUT /api/students/schools/{id}` — Update school (list, notes)
- `DELETE /api/students/schools/{id}` — Remove from list

### Coach
- `POST /api/coach/message` — Send message to coach
- `GET /api/coach/insights` — Get proactive insights
- `PUT /api/coach/insights/{id}/dismiss` — Dismiss an insight

### Documents
- `POST /api/documents/upload` — Upload document
- `GET /api/documents/{id}/status` — Check extraction status
- `GET /api/documents/{id}/result` — Get extraction result

## Workflow

```
User: /new-endpoint POST /api/students/activities Add a new activity

Claude:
1. [architect] Reviewing endpoint design...
   ✅ ADR-001 compliant (Next.js API route)
   ✅ Pattern compliant (user-scoped, validated)

2. [api-scaffold] Generating code...
   Created: app/api/students/activities/route.ts
   Created: lib/validators/activity.ts

3. [security-reviewer] Auditing...
   ✅ Auth check: Present
   ✅ User scoping: Query filtered by user_id
   ✅ Sensitive data: Not logging activity details
   ✅ Input validation: Zod schema enforced

4. [test-writer] Generating tests...
   Created: tests/api/activities.test.ts

✅ Endpoint ready for implementation
```

## Integration

After running this skill:

1. Review the generated code
2. Implement any TODO business logic
3. Run the generated tests: `npm test tests/api/[resource].test.ts`
4. Add to API documentation if needed

---

**Note:** This skill generates the scaffolding with security patterns built in. You may need to add business logic specific to your use case.
