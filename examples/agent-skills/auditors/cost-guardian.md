> **Portfolio Skill:** This skill was developed for the project but applies across all your company projects. When running against a different project (e.g., the project), adapt the specific pattern references (file names, function names, conventions) to that project's codebase. The methodology and checklist items are universal.

# /cost-guardian Agent

This agent monitors and optimizes variable costs including LLM API calls, web scraping, and external services.

## Purpose

Track, analyze, and optimize costs for:
- LLM API calls (Claude, embeddings)
- Web scraping (Firecrawl, Browserless)
- Data APIs (College Scorecard, IPEDS)
- Document processing
- Storage and compute

## Usage

```
/cost-guardian [COMMAND]
```

## Commands

| Command | Purpose |
|---------|---------|
| `report` | Generate cost report for period |
| `analyze [feature]` | Analyze costs for specific feature |
| `optimize [area]` | Suggest cost optimizations |
| `budget [amount]` | Set/check budget thresholds |
| `alert` | Configure cost alerts |

## Examples

```
/cost-guardian report weekly

/cost-guardian analyze coach

/cost-guardian optimize llm

/cost-guardian budget set monthly 500

/cost-guardian alert when llm > 100/day
```

## Cost Categories

### 1. LLM Costs

**Pricing Reference (as of 2024):**

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|----------------------|------------------------|
| claude-3-5-sonnet | $3.00 | $15.00 |
| claude-3-5-haiku | $0.80 | $4.00 |
| claude-3-opus | $15.00 | $75.00 |

**Cost Tracking Schema:**

```typescript
interface LLMCostEntry {
  id: string;
  timestamp: Date;

  // Operation details
  operation_type: 'coach_chat' | 'transcript_extraction' |
                  'resume_extraction' | 'school_analysis' |
                  'deadline_extraction' | 'plan_generation';
  feature: string;

  // Model info
  model: string;
  tokens_in: number;
  tokens_out: number;

  // Cost
  cost_usd: number;

  // Context
  user_id?: string;  // For per-user analysis (hashed)
  session_id?: string;
}
```

**LLM Cost by Feature (Expected):**

| Feature | Model | Avg Tokens | Est. Cost/Call | Calls/User/Month |
|---------|-------|------------|----------------|------------------|
| Coach Chat | Sonnet | 2,000 in / 500 out | $0.014 | 20 |
| Transcript Extract | Haiku | 3,000 in / 800 out | $0.006 | 1 |
| Resume Extract | Haiku | 2,000 in / 600 out | $0.004 | 1 |
| Plan Generation | Sonnet | 4,000 in / 1,500 out | $0.035 | 4 |
| School Analysis | Haiku | 1,500 in / 400 out | $0.003 | 10 |

**Per-User Monthly LLM Cost Estimate:** ~$0.50-$1.00

### 2. Web Scraping Costs

**Firecrawl Pricing:**

| Plan | Price | Credits | Per Credit |
|------|-------|---------|------------|
| Free | $0 | 500/month | - |
| Starter | $19/month | 3,000 | $0.006 |
| Standard | $99/month | 20,000 | $0.005 |
| Growth | $399/month | 100,000 | $0.004 |

**Scraping Cost Tracking:**

```typescript
interface ScrapeCostEntry {
  id: string;
  timestamp: Date;

  // Operation
  operation_type: 'deadline_crawl' | 'program_info' |
                  'merit_grid' | 'cds_fetch';
  school_id?: string;
  url: string;

  // Usage
  credits_used: number;
  pages_scraped: number;

  // Cost
  cost_usd: number;

  // Result
  success: boolean;
  cached: boolean;  // Did we use cache?
}
```

**Scraping Optimization Strategies:**

| Strategy | Savings | Implementation |
|----------|---------|----------------|
| Aggressive caching | 60-80% | Cache for 24-48 hours |
| Batch requests | 20-30% | Crawl multiple pages together |
| Selective scraping | 40-50% | Only scrape changed pages |
| Schedule off-peak | 10-20% | Run during low-traffic times |

### 3. Data API Costs

**API Pricing:**

| API | Cost | Limits |
|-----|------|--------|
| College Scorecard | Free | 1,000 req/hour |
| IPEDS | Free | Reasonable use |
| Data.gov | Free | API key required |

**API Usage Tracking:**

```typescript
interface APICostEntry {
  id: string;
  timestamp: Date;

  api: 'scorecard' | 'ipeds' | 'data_gov';
  endpoint: string;

  // Usage
  requests: number;
  data_points_fetched: number;

  // No direct cost, but track for rate limiting
  rate_limit_remaining?: number;
}
```

### 4. Storage Costs

**Supabase Storage:**

| Tier | Included | Overage |
|------|----------|---------|
| Free | 1 GB | - |
| Pro | 100 GB | $0.021/GB |

**Storage Tracking:**

```typescript
interface StorageCostEntry {
  timestamp: Date;

  // By category
  documents_gb: number;  // Transcripts, resumes
  images_gb: number;
  database_gb: number;

  // Cost
  total_gb: number;
  overage_gb: number;
  cost_usd: number;
}
```

## Cost Dashboard Schema

```typescript
interface CostDashboard {
  period: 'daily' | 'weekly' | 'monthly';
  start_date: Date;
  end_date: Date;

  summary: {
    total_cost: number;
    budget: number;
    budget_remaining: number;
    budget_percent_used: number;
  };

  by_category: {
    llm: {
      total: number;
      by_model: Record<string, number>;
      by_feature: Record<string, number>;
    };
    scraping: {
      total: number;
      credits_used: number;
      pages_scraped: number;
    };
    storage: {
      total: number;
      current_gb: number;
    };
    api: {
      requests: number;
      // Free APIs, just track usage
    };
  };

  trends: {
    daily_average: number;
    projected_monthly: number;
    vs_last_period: number;  // Percentage change
  };

  alerts: CostAlert[];
}
```

## Budget & Alerts

### Budget Configuration

```typescript
interface BudgetConfig {
  monthly_budget: number;  // Total monthly budget

  category_budgets: {
    llm: number;
    scraping: number;
    storage: number;
  };

  alerts: {
    warn_at_percent: number;   // e.g., 75%
    critical_at_percent: number;  // e.g., 90%
  };

  per_user_limits?: {
    daily_llm_calls: number;
    daily_llm_cost: number;
  };
}

// Default configuration
const DEFAULT_BUDGET: BudgetConfig = {
  monthly_budget: 500,

  category_budgets: {
    llm: 300,
    scraping: 100,
    storage: 50,
  },

  alerts: {
    warn_at_percent: 75,
    critical_at_percent: 90,
  },

  per_user_limits: {
    daily_llm_calls: 50,
    daily_llm_cost: 1.00,
  },
};
```

### Alert Types

```typescript
interface CostAlert {
  id: string;
  timestamp: Date;

  type: 'budget_warning' | 'budget_critical' | 'spike' |
        'per_user_limit' | 'anomaly';
  severity: 'info' | 'warning' | 'critical';

  category: 'llm' | 'scraping' | 'storage' | 'total';

  message: string;
  current_value: number;
  threshold: number;

  // For anomaly detection
  expected_value?: number;
  deviation_percent?: number;
}
```

## Cost Optimization Recommendations

### LLM Optimizations

| Optimization | Potential Savings | Implementation |
|--------------|-------------------|----------------|
| Model downgrade | 50-80% | Use Haiku for simple tasks |
| Prompt compression | 20-40% | Reduce context tokens |
| Response caching | 30-50% | Cache common queries |
| Batch processing | 10-20% | Combine similar requests |

```typescript
// Example: Model selection by task
function selectModel(task: string): string {
  const HAIKU_TASKS = [
    'transcript_extraction',
    'resume_extraction',
    'deadline_extraction',
    'classification',
    'simple_qa',
  ];

  const SONNET_TASKS = [
    'coach_chat',
    'plan_generation',
    'complex_analysis',
    'nuanced_advice',
  ];

  if (HAIKU_TASKS.includes(task)) {
    return 'claude-3-5-haiku-20241022';
  }
  return 'claude-3-5-sonnet-20241022';
}
```

### Scraping Optimizations

```typescript
// Cache strategy for web scraping
const CACHE_DURATIONS = {
  deadlines: 7 * 24 * 60 * 60 * 1000,      // 7 days
  program_info: 30 * 24 * 60 * 60 * 1000,  // 30 days
  merit_grids: 90 * 24 * 60 * 60 * 1000,   // 90 days
  general: 24 * 60 * 60 * 1000,            // 24 hours
};

async function scrapeWithCache(url: string, type: string) {
  const cached = await getFromCache(url);
  if (cached && !isExpired(cached, CACHE_DURATIONS[type])) {
    return cached.data;  // Free!
  }

  const fresh = await firecrawl.scrape(url);
  await saveToCache(url, fresh);
  return fresh;
}
```

## Output Templates

### Cost Report

```
## Cost Report: [Period]

### Summary
| Metric | Value |
|--------|-------|
| Total Cost | $XXX.XX |
| Budget | $XXX.XX |
| Remaining | $XXX.XX (XX%) |
| Daily Average | $X.XX |
| Projected Monthly | $XXX.XX |

### By Category
| Category | Cost | % of Total | Budget | Status |
|----------|------|------------|--------|--------|
| LLM | $XXX | XX% | $XXX | ✅ On Track |
| Scraping | $XX | XX% | $XXX | ⚠️ 80% Used |
| Storage | $X | X% | $XX | ✅ On Track |

### LLM Breakdown
| Feature | Calls | Tokens | Cost | Avg/Call |
|---------|-------|--------|------|----------|
| Coach Chat | 500 | 1.2M | $XX | $0.0X |
| Extraction | 100 | 300K | $X | $0.0X |
| Plan Gen | 50 | 200K | $X | $0.0X |

### Trends
- vs Last Period: +X% / -X%
- Anomalies Detected: X
- Users Over Limit: X

### Alerts
| Alert | Severity | Message |
|-------|----------|---------|
| Budget Warning | ⚠️ | LLM at 80% of monthly budget |

### Recommendations
1. [Specific optimization suggestion]
2. [Specific optimization suggestion]
```

### Optimization Analysis

```
## Cost Optimization: [Area]

### Current State
| Metric | Value |
|--------|-------|
| Monthly Cost | $XXX |
| Cost per User | $X.XX |
| Inefficiency Score | X/10 |

### Opportunities Identified
| Opportunity | Current | Optimized | Savings |
|-------------|---------|-----------|---------|
| Model selection | 100% Sonnet | 60% Haiku | $XX/mo |
| Prompt compression | 2K tokens | 1.2K tokens | $XX/mo |
| Response caching | 0% | 30% | $XX/mo |

### Implementation Plan
1. [Step 1]
2. [Step 2]

### Projected Impact
- Monthly savings: $XX-$XX
- Percentage reduction: XX%
- Implementation effort: Low/Medium/High
```

## Checklist (Auto-Verified)

- [ ] All LLM calls have telemetry
- [ ] Scraping uses caching
- [ ] Budget thresholds configured
- [ ] Alerts set up
- [ ] Per-user limits enforced
- [ ] Cost dashboard accessible
- [ ] Weekly reports generated

## Integration

After running this agent:

1. Review cost report
2. Implement recommended optimizations
3. Set up monitoring alerts
4. Schedule regular cost reviews (weekly recommended)
5. Adjust budgets based on actual usage

---

**Note:** Cost control is critical for a B2C product at scale. A few cents per user adds up quickly. Run `/cost-guardian report weekly` every Monday to stay on top of spending.
