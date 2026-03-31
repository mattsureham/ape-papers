# Research Plan: The Audit Threshold — Sweden's 2017 Pay Equity Mandate and the Within-Firm Gender Wage Gap

## Research Question

Does compulsory written pay equity auditing reduce the within-firm gender wage gap? Sweden's 2016 Discrimination Act amendment (SFS 2016:828) lowered the documentation threshold from 25 to 10 employees effective January 2017, creating a sharp policy discontinuity at the 10-employee cutoff.

## Identification Strategy

**Primary design: Difference-in-Discontinuities (Diff-in-Disc)**

Combine the firm-size discontinuity at 10 employees with the temporal discontinuity at 2017 to form a difference-in-discontinuities estimator. This differences out any pre-existing firm-size effects at the threshold (e.g., other regulations that bind at 10 employees) by comparing the RDD estimate in post-reform years (2017+) to the RDD estimate in pre-reform years (pre-2017).

The identifying assumption: any non-audit-related discontinuity at 10 employees is stable over time. The pre-reform RDD serves as a placebo, netting out confounds.

**Complementary design: Staggered DiD**

Firms with 10–24 employees (newly treated in 2017) vs. firms with 25+ employees (always treated). Pre-period: 2010–2016 (7 pre-periods); post-period: 2017–2023. This is weaker (no sharp cutoff) but useful as a robustness check using Callaway-Sant'Anna.

## Expected Effects and Mechanisms

- **Information channel:** Audits force firms to compute gender wage gaps they previously ignored → awareness leads to voluntary adjustment
- **Accountability channel:** Written documentation reviewable by the Equality Ombudsman → firms adjust proactively to avoid sanctions
- **Expected direction:** Reduction in within-firm gender wage gap (narrowing), concentrated in private sector firms where gaps are larger
- **Expected magnitude:** Small to moderate (SDE 0.02–0.10), consistent with Bennedsen et al.'s finding of ~2pp narrowing in Denmark

## Primary Specification

```
GenderGap_ft = α + β₁·Post2017_t × Above10_f + β₂·f(Size_f - 10) × Post2017_t + β₃·f(Size_f - 10) + γ_t + δ_s + ε_ft
```

Where:
- GenderGap_ft = female-to-male wage ratio within firm-size bin f at time t
- Post2017_t = indicator for 2017 onward
- Above10_f = indicator for firm-size bin ≥ 10 employees
- f(·) = local linear function of running variable (firm size)
- γ_t = year fixed effects
- δ_s = sector fixed effects

Bandwidth selection: CCT (Calonico-Cattaneo-Titiunik 2014) optimal bandwidth around the 10-employee cutoff.

## Data Source and Fetch Strategy

**Statistics Sweden (SCB) API — api.scb.se**

Primary tables:
1. **AM0110 — Wage Structure Survey (Lönestrukturstatistiken):** Annual data on wages by sex, sector, occupation, firm size. Available 2000–2023 via PxWeb API.
2. **AM0207 — Short-term wages and salaries:** Quarterly wage indices by industry and sex.
3. **NV0101 — Structural Business Statistics:** Firm counts by size class and industry.

The key challenge is firm-size granularity. SCB's public PxWeb tables report wages by firm-size bins (1–9, 10–19, 20–49, 50–99, etc.). The 10-employee cutoff falls within the 10–19 bin, so I can construct the RDD as:
- Below threshold: firms with 1–9 employees
- Above threshold: firms with 10–19 employees (newly treated in 2017)
- Control: firms with 20–49, 50–99 (always treated since pre-2017)

This gives a coarse but valid RDD using bin midpoints as the running variable, augmented by the temporal variation for diff-in-disc.

**Fetch approach:**
1. Query SCB PxWeb API for AM0110 wage data by sex × firm-size class × sector × year (2010–2023)
2. Query NV0101 for firm counts by size class × sector × year (denominator for weighting)
3. Construct panel of sector × firm-size-bin × year observations
4. Compute within-bin gender wage ratio as primary outcome

## Robustness Checks

1. **Placebo cutoff at 25 employees** (no policy change in 2017) — should yield null
2. **Placebo timing** (apply diff-in-disc at 2014 or 2015) — should yield null
3. **Sector heterogeneity:** Private vs. public sector; female-dominated vs. male-dominated industries
4. **Occupation controls:** Condition on 1-digit SSYK occupation codes
5. **Alternative outcomes:** Total wage growth by sex (not just ratio)
