# /data-crawler Skill

This skill creates data crawlers for collecting and verifying school information from authoritative sources.

## Agent Chain

```
architect → school-data → extraction → security-reviewer → test-writer
```

## What It Does

1. **architect** — Reviews crawler design and data source selection
2. **school-data** — Defines data schema and storage
3. **extraction** — Implements parsing and extraction logic
4. **security-reviewer** — Audits for data handling and rate limiting
5. **test-writer** — Creates tests with sample data

## Usage

```
/data-crawler [DATA_SOURCE] [DESCRIPTION]
```

## Data Sources (from Data Architecture)

| Source | Type | Priority | Data Retrieved |
|--------|------|----------|----------------|
| College Scorecard | API | High | Costs, outcomes, net price by income |
| IPEDS | API | High | Institutional characteristics, graduation rates |
| Common Data Set | PDF Scrape | High | Admissions stats, merit aid (H2A), selection factors |
| School Websites | Web Crawl | Medium | Deadlines, essay prompts, program info |

## Examples

```
/data-crawler scorecard Fetch school data from College Scorecard API

/data-crawler ipeds Fetch institutional data from IPEDS

/data-crawler cds Parse Common Data Set PDFs for merit aid data

/data-crawler deadlines Crawl school websites for application deadlines

/data-crawler merit-grids Collect automatic merit scholarship data
```

## Output Structure

```
services/crawl/
├── [source]/
│   ├── client.ts           # API client or crawler
│   ├── parser.ts           # Data parsing/extraction
│   ├── types.ts            # TypeScript interfaces
│   └── index.ts            # Main export
├── scheduler.ts            # Job scheduling
└── utils/
    ├── rate-limiter.ts
    └── cache.ts

lib/school-data/
├── normalizer.ts           # Entity resolution
├── freshness.ts            # Staleness detection
└── types.ts

supabase/migrations/
└── [timestamp]_[source]_data.sql
```

## Crawler Patterns

### API Crawler (Scorecard, IPEDS)
```typescript
// services/crawl/scorecard/client.ts
import { RateLimiter } from '../utils/rate-limiter';

const SCORECARD_API = 'https://api.data.gov/ed/collegescorecard/v1';
const rateLimiter = new RateLimiter({ maxRequests: 100, windowMs: 60000 });

export async function fetchSchoolData(unitId: string): Promise<ScorecardData> {
  await rateLimiter.waitForSlot();

  const response = await fetch(
    `${SCORECARD_API}/schools?id=${unitId}&api_key=${process.env.SCORECARD_API_KEY}`
  );

  if (!response.ok) {
    throw new CrawlError(`Scorecard API error: ${response.status}`);
  }

  const data = await response.json();
  return parseScorecardResponse(data);
}
```

### PDF Parser (CDS)
```typescript
// services/crawl/cds/parser.ts
import { PDFDocument } from 'pdf-lib';

export async function parseCDSPdf(pdfBuffer: Buffer): Promise<CDSData> {
  const doc = await PDFDocument.load(pdfBuffer);

  // Extract Section C (Admissions)
  const admissionsData = extractSection(doc, 'C');

  // Extract Section H (Financial Aid) - especially H2A
  const financialAidData = extractSection(doc, 'H');

  // Validate extracted data
  const validated = validateCDSData({
    admissions: admissionsData,
    financialAid: financialAidData,
  });

  return validated;
}

// Key CDS Section H2A extraction
function extractH2A(section: string): MeritAidData {
  // H2A: Non-need-based merit aid to students without need
  // This is the core "Buyer/Seller" signal
  return {
    numberOfStudents: extractNumber(section, 'H2A(n)'),
    averageAward: extractNumber(section, 'H2A(o)'),
  };
}
```

### Web Crawler (Deadlines, Programs)
```typescript
// services/crawl/deadlines/client.ts
import Firecrawl from '@anthropic-ai/firecrawl';

const firecrawl = new Firecrawl({ apiKey: process.env.FIRECRAWL_API_KEY });

export async function crawlDeadlines(schoolUrl: string): Promise<DeadlineData> {
  // Crawl admissions page
  const result = await firecrawl.scrape({
    url: `${schoolUrl}/admissions/apply`,
    formats: ['markdown'],
  });

  // Extract deadline information
  const deadlines = await extractDeadlinesWithLLM(result.markdown);

  return {
    ...deadlines,
    sourceUrl: result.url,
    crawledAt: new Date(),
  };
}

async function extractDeadlinesWithLLM(markdown: string): Promise<Deadlines> {
  // Use Haiku for cost-effective extraction
  const response = await anthropic.messages.create({
    model: 'claude-3-5-haiku-20241022',
    messages: [{
      role: 'user',
      content: `Extract application deadlines from this admissions page:

${markdown}

Return JSON with this structure:
{
  "early_action": { "date": "YYYY-MM-DD", "type": "EA" | "REA" | null },
  "early_decision": { "date": "YYYY-MM-DD", "type": "ED" | "ED2" | null },
  "regular": { "date": "YYYY-MM-DD" },
  "rolling": boolean
}`
    }],
  });

  // Record telemetry
  await recordLLMTelemetry({
    model: 'claude-3-5-haiku-20241022',
    operationType: 'deadline_extraction',
    tokensIn: response.usage.input_tokens,
    tokensOut: response.usage.output_tokens,
  });

  return JSON.parse(response.content[0].text);
}
```

## Entity Resolution

All crawled data must be linked to canonical school entities:

```typescript
// lib/school-data/normalizer.ts

// Cross-reference table
interface SchoolEntity {
  id: string;                    // Internal ID
  ipeds_unit_id: string;         // Federal ID (primary key for linking)
  ceeb_code?: string;            // College Board code
  act_code?: string;             // ACT code
  opeid?: string;                // FSA code
  name: string;
  name_variants: string[];       // "UW", "University of Washington", etc.
}

export async function resolveSchool(
  identifier: { type: 'ipeds' | 'ceeb' | 'name'; value: string }
): Promise<SchoolEntity | null> {
  // Look up in crosswalk table
  const query = supabase.from('school_entities');

  switch (identifier.type) {
    case 'ipeds':
      query.eq('ipeds_unit_id', identifier.value);
      break;
    case 'ceeb':
      query.eq('ceeb_code', identifier.value);
      break;
    case 'name':
      query.ilike('name', `%${identifier.value}%`);
      break;
  }

  const { data } = await query.single();
  return data;
}
```

## Data Freshness

```typescript
// lib/school-data/freshness.ts

interface DataFreshness {
  school_id: string;
  data_type: 'scorecard' | 'ipeds' | 'cds' | 'deadlines' | 'programs';
  last_updated: Date;
  source_url: string;
  confidence: 'high' | 'medium' | 'low';
  next_refresh_due: Date;
}

// Freshness thresholds by data type
const FRESHNESS_THRESHOLDS = {
  scorecard: 180,      // 6 months (annual release)
  ipeds: 365,          // 1 year (annual release)
  cds: 365,            // 1 year (annual release)
  deadlines: 60,       // 2 months (critical, verify often)
  programs: 90,        // 3 months
  merit_grids: 180,    // 6 months
};

export function isStale(freshness: DataFreshness): boolean {
  const threshold = FRESHNESS_THRESHOLDS[freshness.data_type];
  const daysSinceUpdate = differenceInDays(new Date(), freshness.last_updated);
  return daysSinceUpdate > threshold;
}
```

## Scheduler

```typescript
// services/crawl/scheduler.ts

interface CrawlJob {
  id: string;
  source: 'scorecard' | 'ipeds' | 'cds' | 'deadlines';
  school_ids?: string[];        // Specific schools, or all if empty
  priority: 'high' | 'normal' | 'low';
  scheduled_at: Date;
  status: 'pending' | 'running' | 'completed' | 'failed';
}

// Schedule refresh for stale data
export async function scheduleRefreshJobs(): Promise<CrawlJob[]> {
  const staleData = await findStaleSchoolData();

  const jobs = staleData.map(item => ({
    source: item.data_type,
    school_ids: [item.school_id],
    priority: item.data_type === 'deadlines' ? 'high' : 'normal',
    scheduled_at: new Date(),
  }));

  await insertCrawlJobs(jobs);
  return jobs;
}
```

## Security & Rate Limiting

```typescript
// services/crawl/utils/rate-limiter.ts

export class RateLimiter {
  private requests: number[] = [];

  constructor(private config: { maxRequests: number; windowMs: number }) {}

  async waitForSlot(): Promise<void> {
    const now = Date.now();
    this.requests = this.requests.filter(t => now - t < this.config.windowMs);

    if (this.requests.length >= this.config.maxRequests) {
      const waitTime = this.config.windowMs - (now - this.requests[0]);
      await sleep(waitTime);
    }

    this.requests.push(Date.now());
  }
}

// Rate limits by source
const RATE_LIMITS = {
  scorecard: { maxRequests: 100, windowMs: 60000 },   // 100/min
  ipeds: { maxRequests: 50, windowMs: 60000 },        // 50/min
  firecrawl: { maxRequests: 10, windowMs: 60000 },    // 10/min (be polite)
};
```

## Checklist (Auto-Verified)

- [ ] Rate limiting implemented
- [ ] Entity resolution to canonical IDs
- [ ] Data freshness tracking
- [ ] Error handling and retries
- [ ] LLM extraction has cost telemetry
- [ ] Crawled data validated before storage
- [ ] Source URLs stored for verification
- [ ] Tests with sample data

## Workflow

```
User: /data-crawler cds Parse Common Data Set PDFs for merit aid data

Claude:
1. [architect] Reviewing crawler design...
   ✅ CDS is authoritative source for H2A merit data
   ✅ PDF parsing approach appropriate

2. [school-data] Defining schema...
   Created: lib/school-data/types.ts (CDSData interface)
   Created: supabase/migrations/xxx_cds_data.sql

3. [extraction] Implementing parser...
   Created: services/crawl/cds/client.ts
   Created: services/crawl/cds/parser.ts
   Created: services/crawl/cds/sections/h2a.ts
   ✅ H2A extraction for Buyer/Seller signal

4. [security-reviewer] Auditing...
   ✅ Rate limiting: Implemented
   ✅ Data validation: Schema enforced
   ✅ No PII in crawled data

5. [test-writer] Creating tests...
   Created: tests/crawl/cds.test.ts
   Created: tests/crawl/cds/sample-cds.pdf (fixture)

✅ CDS crawler ready
```

## Integration

After running this skill:

1. Set up API keys in environment
2. Create initial school entity crosswalk
3. Run initial crawl for MLP schools
4. Set up refresh schedule
5. Monitor data freshness dashboard

---

**Note:** Crawlers should be run on a schedule to keep data fresh. Critical data (deadlines) needs more frequent verification. Reference the [Data Architecture](https://www.notion.so/2ed65d2ef8aa81ad9a4ce70a310fb459) for complete schema definitions.
