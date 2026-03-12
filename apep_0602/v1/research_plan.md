# Research Plan: apep_0602

## Research Question

Does crossing the federal 30% cohort default rate (CDR) threshold cause for-profit colleges to improve student outcomes, or does it primarily trigger strategic manipulation through forbearance pushing? What happens to enrollment, completions, and institutional survival when for-profit institutions face the credible threat of losing Title IV financial aid eligibility?

## Policy Background

Under 34 CFR 668.187, postsecondary institutions face a regulatory cliff: if their 3-year cohort default rate equals or exceeds 30% for three consecutive years (or 40% in any single year), they lose Title IV eligibility — access to Pell Grants and Direct Loans. For the for-profit sector, Title IV revenue constitutes 70-90% of institutional revenue. Loss of eligibility is effectively a death sentence.

Key cutoffs:
- **30%**: Three consecutive years triggers loss of all Title IV programs
- **40%**: Single year triggers immediate loss
- **25%**: Triggers provisional certification and enhanced monitoring

## Identification Strategy

**Design:** Sharp regression discontinuity at the 30% CDR threshold.

**Running variable:** 3-year cohort default rate, a continuous measure (0-100%) calculated by the Department of Education from administrative loan repayment records. Institutions observe it ex post but cannot precisely control it because it depends on aggregate repayment behavior of thousands of individual borrowers (Lee 2008 imprecise control argument).

**Treatment:** First year an institution's CDR crosses 30%. This triggers enhanced monitoring, provisional certification, reputational damage, and starts the 3-year clock toward eligibility loss.

**Key validity features:**
1. Imprecise control — CDR depends on thousands of individual borrower decisions
2. Manipulation is testable and informative (forbearance pushing creates bunching below 30%)
3. Multiple cutoffs (25%, 30%, 40%) allow for internal replication and placebo tests

## Primary Specification

Sharp RDD with local linear regression:

Y_i = α + β₁ · 1(CDR_i ≥ 0.30) + β₂ · (CDR_i - 0.30) + β₃ · 1(CDR_i ≥ 0.30) · (CDR_i - 0.30) + ε_i

with CCT optimal bandwidth, bias-corrected robust confidence intervals, and triangular kernel.

## Expected Effects and Mechanisms

**Accountability channel (quality improvement):**
- Enrollment changes (tightened admissions)
- Completion rates increase (institutional effort)
- Closure if adjustment fails

**Manipulation channel (forbearance pushing):**
- Institutions near 30% push borrowers into forbearance to delay default counts
- Observable as bunching below 30% in the CDR distribution
- Donut-hole RDD addresses this

**Cream-skimming channel:**
- Institutions admit lower-risk students (demographic composition changes)
- Observable as shifts in Pell recipient shares and student demographics

## Data Sources

1. **IPEDS** (local: `data/ipeds/ipeds.duckdb`) — 23 tables, 2002-2024, 11,458 institutions
   - Enrollment: `effy` table
   - Completions: `c_a` table
   - Closures: `hd` table (`deathyr`, `currently_active`)
   - Financial aid: `sfa` table (Pell recipients, loan recipients)
   - Institution characteristics: `hd` table

2. **College Scorecard API** — CDR running variable
   - Field: `{year}.repayment.3_yr_default_rate`
   - Merge on `unitid`

3. **FSA CDR historical files** — Alternative CDR data from data.gov

## Analysis Pipeline

1. Fetch CDR data from College Scorecard API for all for-profit institutions (2010-2019)
2. Merge with IPEDS using unitid
3. Construct institution-year panel with CDR as running variable
4. McCrary density test at 30%
5. Covariate smoothness tests (institution age, size, geography)
6. Main RDD estimates with CCT bandwidth
7. Robustness: donut-hole, multiple bandwidths, local quadratic, placebo cutoffs
8. Mechanism analysis: demographic composition shifts, Pell shares, completion rates

## Key Risk

Manipulation at the 30% cutoff is expected (forbearance pushing is well-documented). This is both a threat to validity AND an interesting finding. Strategy: (a) document manipulation with McCrary test, (b) use donut-hole RDD excluding 1-2pp around cutoff, (c) frame manipulation as part of the story (accountability induces strategic behavior, not just quality improvement).
