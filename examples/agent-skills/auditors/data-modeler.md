> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /data-modeler Skill

A standalone database design and audit skill for the project. Use this whenever you are adding tables or columns, writing migrations, auditing schema health, or debugging silent data failures traced to the database layer.

The the project database has 57+ tables, 122 migrations, and a history of recurring schema-drift bugs. This skill exists because generic architect reviews miss database-specific failure modes.

## Agent Chain

```
read-schema → audit-checks → design-or-fix → migration → validate → document
```

## Usage

```
/data-modeler audit              — Full schema health check (RLS, FKs, constraints, Zod alignment)
/data-modeler design [feature]   — Design new table(s) or columns for a feature
/data-modeler migrate [change]   — Write a correct, safe migration for a proposed change
/data-modeler validate [file]    — Check a specific file's DB queries against actual schema
/data-modeler fix [issue]        — Diagnose and fix a specific schema or data bug
```

---

## the project Database Fundamentals

Read these before doing anything. Every recurring bug traces back to one of these rules.

### Rule 1 — student_id Always References auth.users(id)

```typescript
// ✅ CORRECT — always
.eq('student_id', user.id)           // user.id = auth.users.id

// ❌ WRONG — never
.eq('student_id', studentProfile.id) // studentProfile.id = student_profiles.id (different UUID)
```

ALL 26+ student data tables use `student_id → auth.users(id)` since migration `20260215200000`. RLS policies use `student_id = auth.uid()`. Never use a subquery or `student_profiles` detour.

**Parent routes:** Use `targetStudentId` / `targetUserId` for all queries, not `user.id`.

### Rule 2 — PostgREST Nested Join Requires a Real FK Constraint

```typescript
// Only works if school_id has a real FK to schools in the DB
supabase.from('school_lists').select('school:schools (id, name)')

// If FK is missing → silently returns null (no error, no warning)
// Fix: verify FK exists in pg_dump, or use a two-step fetch
```

Wrong column names in `.select()` → HTTP 400 → `data = null`. Silent failures, no TypeScript error.

### Rule 3 — RLS INSERT + RETURNING Trap

When a row is inserted with `student_id = null` (e.g., pending invitations), the SELECT RLS policy (`student_id = auth.uid()`) can't see the new row, so `.select().single()` after INSERT returns 0 rows → false error.

**Fix:** Use `adminClient` for inserts where the new row's own data won't satisfy the SELECT policy.

### Rule 4 — DB CHECK Constraints Must Match App Enums

```sql
-- DB constraint
CHECK (fit_category IN ('Safety', 'Target', 'Reach', 'Likely'))

-- If app sends 'Match' → silent rejection or 500
-- Always verify: grep app enum values against DB CHECK
```

Valid `fit_category` values: `Safety`, `Target`, `Reach`, `Likely` (not `match`, `Match`, or anything else).

### Rule 5 — Zod Strip-Mode Silent NULL

Zod's default `strict: false` strips unknown keys silently. A field accepted by the frontend but missing from the Zod schema reaches the API handler as `undefined` → DB column receives `NULL` → 200 OK returned to user → data silently lost.

**Check:** For every new column, verify it's in the Zod schema with the right type and `.optional()` / `.nullable()` accurately reflects the DB `NOT NULL` constraint.

### Rule 6 — Migration Ordering

```sql
-- ✅ CORRECT order
ALTER TABLE ... DROP CONSTRAINT fk_name;  -- drop FK first
UPDATE ... SET column = new_value;         -- then update data
ALTER TABLE ... ADD CONSTRAINT fk_name ...; -- then re-add FK

-- ❌ WRONG — updating data while FK constraint is live causes errors
```

Never reuse migration timestamps. `ON CONFLICT DO UPDATE` silently overwrites. Format: `YYYYMMDDHHMMSS_descriptive_name.sql`.

### Rule 7 — school Data Column Names

Real column names (not what you might guess):
- `sat_math_25`, `sat_math_75`, `sat_reading_25`, `sat_reading_75`
- `act_composite_25`, `act_composite_75`
- School name: `'University of Washington-Seattle Campus'` (NOT `'-Seattle'`)

Wrong names → HTTP 400 → `data = null`. Always verify against `docs/DATA_FIELD_REFERENCE.md`.

### Rule 8 — `last_verified_date` Required for School Data

Every school record must have a `last_verified_date`. Stale data must be flagged in the UI. Time-sensitive fields (deadlines, requirements) must be recently verified.

---

## Phase 1: Read Schema

Before any audit, design, or fix — read the actual schema:

```
1. Read docs/DATA_FIELD_REFERENCE.md — the authoritative schema reference
2. Read PATTERNS.md — security and coding patterns
3. For the specific tables involved:
   - Read the most recent migration touching those tables
   - Grep for the table name in src/ to find all query sites
4. If checking RLS: read migration files for the relevant CREATE POLICY statements
```

Never rely on memory or TypeScript types for column names. Always verify against `DATA_FIELD_REFERENCE.md` or the migration files.

---

## Phase 2: Audit Checks

Run these checks for every `/data-modeler audit` invocation. Also run the relevant subset for `design`, `migrate`, `validate`, and `fix`.

### 2a — FK Integrity

```
For each table being audited:
□ Does every foreign key have a real constraint in the DB (not just application-level)?
□ Does student_id reference auth.users(id) — NOT student_profiles(id)?
□ Do PostgREST nested joins (select 'related (cols)') have backing FK constraints?
□ Are FK constraints dropped before data updates in migrations?
```

### 2b — RLS Policy Completeness

```
For each table with student data:
□ SELECT policy: student_id = auth.uid() (simple — no subquery needed)
□ INSERT policy: student_id = auth.uid() OR uses adminClient (if row won't satisfy SELECT at insert time)
□ UPDATE policy: student_id = auth.uid()
□ DELETE policy: student_id = auth.uid()
□ Are there tables missing RLS entirely? (Run: SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false)
□ Parent access: uses family_links join, NOT student_profiles detour
□ Admin access: uses service role / adminClient, not user client
```

### 2c — Column Name Drift

```
For each query site in src/:
□ Do column names in .select(), .eq(), .update(), .insert() match actual DB column names?
□ Are school stat columns using the correct names (sat_math_25, not sat_25)?
□ Are enum values matching DB CHECK constraints (fit_category, list_type, etc.)?
□ Do TypeScript types match actual DB column types (text vs uuid vs jsonb)?
```

Run this grep to find all query sites for a table:
```bash
grep -r "from('TABLE_NAME')" src/ --include="*.ts" --include="*.tsx" -l
```

### 2d — Zod Schema Alignment

```
For each API route handling writes to the audited table:
□ Is every DB column that should be writable present in the Zod schema?
□ Does .optional() in Zod accurately reflect nullable columns in DB?
□ Does .required() in Zod accurately reflect NOT NULL constraints?
□ Are enum values in Zod z.enum([...]) matching DB CHECK constraint values exactly?
□ Are there fields accepted by the frontend but not in Zod (silent strip → NULL)?
```

### 2e — Migration Health

```
□ Are migrations sequential and non-conflicting in timestamp?
□ Do migrations that alter FK-referenced columns drop FKs first?
□ Are there any duplicate timestamps in supabase/migrations/?
□ Has each migration been applied to both staging AND production?
   Run: scripts/apply-migrations.sh --target staging --dry-run
         scripts/apply-migrations.sh --target production --dry-run
□ Do migration comments explain WHY (not just what)?
```

### 2f — Data Integrity

```
□ Are NOT NULL columns being guarded in API routes (not relying on DB to reject)?
□ Are UUIDs generated correctly (gen_random_uuid() in DB, not application-side)?
□ Are timestamps using now() / CURRENT_TIMESTAMP consistently?
□ Are jsonb columns validated (not raw any)?
□ Is last_verified_date present on school data tables?
```

### 2g — Query Pattern Safety

```
For each query site:
□ Is student_id scoped to the authenticated user?
□ Is .single() used where exactly one row is expected (fails loudly on 0 or 2+)?
□ Is .maybeSingle() used where 0 rows is a valid state?
□ Are adminClient queries used only in server-side routes (never client-side)?
□ Are parallel queries using Promise.all() with proper error handling?
□ Are large result sets paginated or limited?
```

---

## Phase 3: Design (for `/data-modeler design`)

When designing a new table or adding columns:

### Table Design Checklist

```
□ Primary key: id uuid DEFAULT gen_random_uuid() PRIMARY KEY
□ Student ownership: student_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
□ Timestamps: created_at timestamptz NOT NULL DEFAULT now()
             updated_at timestamptz NOT NULL DEFAULT now()
□ RLS: enabled immediately (ALTER TABLE ... ENABLE ROW LEVEL SECURITY)
□ Policies: SELECT, INSERT, UPDATE, DELETE — all four
□ Indexes: student_id indexed (for RLS performance), plus any frequent filter columns
□ CHECK constraints: for enum columns — validated against app enum values
□ Soft delete: deleted_at timestamptz (if records should be archivable, not hard-deleted)
```

### Column Design Checklist

```
□ Correct type: uuid | text | integer | numeric | boolean | timestamptz | jsonb
□ NOT NULL vs nullable: reflects whether the field is required for the row to be valid
□ Default value: sensible default where applicable (false, now(), etc.)
□ CHECK constraint: if enum — list all valid values
□ FK constraint: if referencing another table — explicit REFERENCES clause
□ Comment: SQL COMMENT ON COLUMN for non-obvious fields
```

### Output Format

When designing, produce:

1. **Schema diagram** (table name, columns, types, constraints, relationships)
2. **Migration SQL** (complete, ready to run — see Phase 4)
3. **TypeScript type** (matching the DB schema exactly)
4. **Zod schema** (with optional/required matching NOT NULL constraints)
5. **RLS policies** (all four operations)
6. **API query pattern** (how to read/write this table correctly)

---

## Phase 4: Migration (for `/data-modeler migrate`)

Every migration must follow this format:

```sql
-- Migration: YYYYMMDDHHMMSS_descriptive_name.sql
-- Purpose: [WHY this change is needed, not just what]
-- Related: GitHub issue #NNN / feature: [name]
-- Tables affected: [list]
-- Breaking: [yes/no — and what breaks if yes]
-- Applied to: staging [date] | production [date]

-- ============================================================
-- Step 1: [description]
-- ============================================================

-- Drop dependent constraints first (if altering FK-referenced columns)
ALTER TABLE ... DROP CONSTRAINT IF EXISTS ...;

-- Make the change
ALTER TABLE ... ADD COLUMN ... ;
-- or
CREATE TABLE ... ;
-- or
ALTER TABLE ... ALTER COLUMN ... ;

-- Re-add constraints after data is clean
ALTER TABLE ... ADD CONSTRAINT ... ;

-- ============================================================
-- Step 2: RLS policies (if new table)
-- ============================================================

ALTER TABLE ... ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_select" ON ...
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "student_insert" ON ...
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "student_update" ON ...
  FOR UPDATE USING (student_id = auth.uid());

CREATE POLICY "student_delete" ON ...
  FOR DELETE USING (student_id = auth.uid());

-- ============================================================
-- Step 3: Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_[table]_student_id ON [table](student_id);
```

### After Writing the Migration

```bash
# Apply to staging first — always
scripts/apply-migrations.sh --target staging

# Verify on staging (query the table/policy)
# Then apply to production
scripts/apply-migrations.sh --target production

# Verify on production
```

**Never apply to production without staging verification.**

---

## Phase 5: Validate (for `/data-modeler validate`)

When validating a specific file or query:

```
1. Extract all table names from .from('...') calls
2. For each table, look up columns in DATA_FIELD_REFERENCE.md
3. For each .select('col1, col2'), verify every column exists on that table
4. For each .eq('col', val), verify the column exists
5. For each .insert({col: val}), verify col exists and type matches
6. Check student_id query pattern (user.id, not studentProfile.id)
7. Check .single() vs .maybeSingle() usage is correct
8. Check enum values against DB CHECK constraints
9. Check Zod schema covers all writable columns
```

Output format:
```
## Validation: [filename]

### Column Name Check
✅ school_lists.school_id — exists
✅ school_lists.student_id — exists, references auth.users(id)
❌ schools.sat_25 — DOES NOT EXIST (should be sat_math_25 + sat_reading_25)

### RLS Pattern Check
✅ .eq('student_id', user.id) — correct

### Zod Alignment
❌ fit_category missing from Zod schema — will silently strip → NULL

### Issues Found
| Severity | Issue | File | Line |
|----------|-------|------|------|
| P1 | Wrong column name: sat_25 → use sat_math_25, sat_reading_25 | coach-context.ts | 192 |
| P1 | Zod schema missing fit_category | school-route.ts | 45 |
```

---

## Phase 6: Document

After any schema change:

### Always Update
- `docs/DATA_FIELD_REFERENCE.md` — Add new tables/columns, update existing entries
- Migration file header (WHY, related issue, tables affected)

### If New Table
- Add to Part 2 (table-by-table reference) with purpose, key columns, RLS, relationships
- Add to Part 3 quick-reference tables
- Add audit gotchas if the table has non-obvious behavior

### If New Column on Existing Table
- Add to the relevant table's column list in DATA_FIELD_REFERENCE.md
- Note if column has a CHECK constraint (list valid values)
- Note if column is NOT NULL (document what happens when missing)

### GitHub Issue
- If the change fixes a bug: comment on and close the issue
- If a new schema issue was found: file a GitHub issue before fixing

---

## Common Failure Patterns (Recurring Bugs)

These have caused real production bugs. Check for them actively.

| Pattern | Symptom | Check |
|---------|---------|-------|
| Wrong `student_id` source | Data not visible to user, wrong user's data returned | Always `user.id`, never `studentProfile.id` |
| PostgREST join missing FK | Nested join returns `null` silently | Verify real FK in DB, not just in migration intent |
| Wrong column name in query | `data = null`, no error thrown | Grep `DATA_FIELD_REFERENCE.md` for actual column names |
| Enum mismatch (app vs DB CHECK) | 500 on insert/update, sometimes silent | Grep DB migration for CHECK constraint values |
| Zod strip-mode | Field accepted in UI, NULL in DB | Every new column must be in Zod schema |
| INSERT + RETURNING + RLS | "not found" error after successful insert | Use `adminClient` when row's student_id = null at insert time |
| Missing RLS policy | Wrong user's data returned or unauthorized access | Check all four policies (SELECT/INSERT/UPDATE/DELETE) |
| Migration FK ordering | Migration fails with FK violation | DROP constraint → update data → re-add constraint |
| Timestamp reuse | Migration silently overwrites prior migration | Never reuse timestamps; always increment |
| `.single()` on 0 rows | 406 error thrown as if server error | Use `.maybeSingle()` when 0 rows is valid |

---

## Output Format

Every `/data-modeler` invocation must produce this summary:

```
## Data Modeler: /data-modeler [mode] [target]

### Mode
[audit | design | migrate | validate | fix]

### Schema Findings
| Check | Status | Details |
|-------|--------|---------|
| FK integrity | ✅ / ❌ | [details] |
| RLS completeness | ✅ / ❌ | [details] |
| Column name drift | ✅ / ❌ | [details] |
| Zod alignment | ✅ / ❌ | [details] |
| Migration health | ✅ / ❌ | [details] |

### Issues Found
| Severity | Issue | Table/File | Fix |
|----------|-------|------------|-----|
| P0 | [description] | [location] | [fix] |
| P1 | [description] | [location] | [fix] |

### Changes Made
| File | Action |
|------|--------|
| supabase/migrations/YYYYMMDDHHMMSS_name.sql | Created |
| docs/DATA_FIELD_REFERENCE.md | Updated |
| src/path/to/file.ts | Fixed column name |

### Migration Status
- [ ] Applied to staging
- [ ] Verified on staging
- [ ] Applied to production
- [ ] Verified on production

### Open Questions
| Question | Impact |
|----------|--------|
| [question] | [what depends on the answer] |

### Summary
✅ [N] checks passed · ❌ [N] issues found · [N] fixed · [N] filed as GitHub issues
```

---

## When to Escalate

Stop and ask the user if:
- A schema change would drop or rename a column that has existing data
- A migration needs to backfill data on a large table (performance risk)
- An RLS change would expose previously private data or block previously accessible data
- Adding a NOT NULL column to an existing table with rows (needs a DEFAULT or backfill)
- A foreign key change affects more than 5 tables
- The fix contradicts something in `DATA_FIELD_REFERENCE.md` (may be stale — verify before changing)

---

## Key References

- `docs/DATA_FIELD_REFERENCE.md` — Authoritative schema reference (57+ tables)
- `PATTERNS.md` — Security and coding patterns (§1 Privacy, §4 School Data Integrity)
- `supabase/migrations/` — All 122 migrations (ordered by timestamp)
- `scripts/apply-migrations.sh` — Migration deployment script
- GitHub Issues — All known schema bugs are tracked here
