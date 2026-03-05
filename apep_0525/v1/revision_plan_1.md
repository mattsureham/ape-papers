# Revision Plan 1 — Stage C Response to Referee Reviews

## Overview

Three referee reviews received: GPT-5.2 (MAJOR), Grok-4.1-Fast (MAJOR), Gemini-3-Flash (MINOR).

## Consensus Issues (all 3 reviewers)

1. **Add DDD event study with parallel pre-trends test** — All reviewers want income-group × border-side × year interaction to verify parallel trends assumption for triple-difference.
2. **Report pooled RDD excluding NJ-PA** — NJ-PA has N=30 and drives the pooled result. Report sensitivity.
3. **Reframe cross-sectional RDD as descriptive** — Given placebo/balance failures, stop treating it as causal for taxes.

## Additional Changes (high-value)

4. **Add border-pair–level clustered SEs** for triple-diff — GPT notes ZIP clustering may overstate precision with only 8 border pairs.
5. **Soften welfare/elasticity language for cross-sectional estimate** — Present as explicit upper bound, not a policy parameter.
6. **Discuss SALT exposure heterogeneity** — Acknowledge coarse treatment definition and discuss property tax / itemization channels.

## Implementation

### R Code Changes
- `04_robustness.R`: Add DDD event study (HighTaxSide × HighIncome × Year interactions), save coefficients. Add pooled-excluding-NJ-PA nonparametric RDD. Add border-pair clustered SEs for DDD.
- `05_figures.R`: Add Figure 7 (DDD event study plot).
- `06_tables.R`: Add pooled-ex-NJ-PA row to Table 2. Add DDD event study results table.

### LaTeX Changes
- Reframe cross-sectional RDD language in Identification, Results, and Discussion as "descriptive geography"
- Add DDD event study figure and discussion
- Add pooled-ex-NJ-PA result discussion
- Present cross-sectional elasticity as explicit upper bound
- Add SALT exposure discussion paragraph
- Report border-pair clustered SEs alongside ZIP-clustered
