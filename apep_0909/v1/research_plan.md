# Research Plan: The Electoral Constable — PCC Election Cycles and Crime Investigation Quality

## Research Question

Do directly elected Police and Crime Commissioners (PCCs) generate political budget cycles in criminal investigation quality? Specifically, do charge/summons rates rise and no-suspect-identified rates fall in the quarters leading up to PCC elections, only to revert afterward?

## Policy Context

The Police Reform and Social Responsibility Act 2011 replaced appointed police authorities with directly elected PCCs across 41 police force areas in England and Wales. PCCs set strategic priorities, control police budgets, and hire/fire chief constables. Elections occurred in November 2012, May 2016, May 2021, and May 2024. The Metropolitan Police and City of London Police did NOT receive PCCs, serving as natural placebo controls.

## Identification Strategy

**Within-force stacked event study** around 4 PCC elections.

- **Unit of analysis:** Force × offence group × quarter
- **Treatment:** Proximity to PCC election (quarters relative to election date)
- **Specification:** Event study with quarterly leads/lags around each election, stacked across all 4 elections to avoid forbidden comparisons
- **Fixed effects:** Force × offence group FE (absorb time-invariant heterogeneity), calendar quarter FE (absorb seasonality and macro trends), election-cohort FE
- **Clustering:** Force level (41 PCC forces + 2 placebos = 43 clusters)

**Key identification assumption:** Absent electoral incentives, investigation quality follows parallel trends across the electoral cycle. Validated by:
1. Pre-PCC baseline period (2005/06–2011/12) — no elections, should show no cycle
2. Met Police and City of London — no PCCs, should show no cycle
3. Low-discretion offences (e.g., drug possession) — charge decisions less manipulable

## Expected Effects and Mechanisms

**Electoral cycle hypothesis:** PCCs pressure chief constables to show results before elections. This shifts police effort toward "quick wins" — cases that can be charged rapidly — and away from complex investigations.

- **Pre-election (Q-4 to Q-1):** Charge rate ↑, no-suspect rate ↓
- **Post-election (Q+1 to Q+4):** Reversion to mean (or overshoot if effort was diverted)
- **Heterogeneity:** Stronger cycles in competitive seats (marginal PCC races), weaker in safe seats

**Mechanism:** Not more crime solved — rather, reallocation of investigative effort across case types. If total crime volume doesn't change but charge composition shifts toward easier cases, this suggests effort substitution rather than genuine productivity improvement.

## Primary Specification

```
Y_{f,o,q} = α_{f,o} + γ_q + Σ_k β_k × 1[k quarters from election] + ε_{f,o,q}
```

Where:
- Y = charge/summons rate (or no-suspect-identified rate) for force f, offence group o, quarter q
- α_{f,o} = force × offence group fixed effects
- γ_q = calendar quarter fixed effects
- k ∈ {-8, ..., -1, 0, +1, ..., +7} quarters relative to election
- Standard errors clustered at force level

## Data Sources

1. **Home Office Crime Outcomes Data** (primary)
   - Annual files from data.gov.uk / Home Office
   - Format: Force × Offence Group × Outcome Type × Quarter
   - Coverage: 2005/06–2024/25 (varies by file format)
   - ~286K rows for early period, ~674K for later years

2. **PCC Election Results** (for heterogeneity)
   - Electoral Commission data on PCC election results
   - Margin of victory for competitive vs. safe seat classification

## Outcomes

| Outcome | Source | Expected Sign |
|---------|--------|---------------|
| Charge/summons rate | Home Office outcomes | ↑ pre-election |
| No-suspect-identified rate | Home Office outcomes | ↓ pre-election |
| Evidential difficulties rate | Home Office outcomes | Ambiguous |
| Total recorded crime | Home Office outcomes | No change (placebo) |

## Robustness Checks

1. **Pre-PCC placebo:** Same event study specification on 2005–2012 data (no elections → flat coefficients)
2. **Met Police / City of London placebo:** No PCC → no cycle
3. **Low-discretion offence placebo:** Drug possession charges driven by proactive policing, not investigation quality
4. **Stacked vs. pooled:** Compare stacked event study (no forbidden comparisons) with pooled specification
5. **Wild cluster bootstrap:** Inference robust to small number of clusters (43 forces)
6. **Leave-one-out:** Drop each force iteratively to check no single force drives results
