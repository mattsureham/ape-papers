# Research Plan: The Disclosure Deterrent — OSHA Electronic Reporting at 100 Employees

## Research Question

Does mandating public electronic submission of detailed injury logs reduce workplace injuries? We exploit OSHA's 2023 final rule (88 FR 47046), which requires establishments with 100+ employees in high-hazard (Appendix B) industries to submit Forms 300/301 starting January 2024. Establishments with 95-99 employees in the same industries are exempt, creating a sharp regulatory discontinuity.

## Identification Strategy

**Difference-in-discontinuities (DinD):**

1. **Primary RDD:** Sharp discontinuity at 100 employees within Appendix B industries. Compare injury rates for establishments just above vs. just below the threshold.

2. **DinD:** Compare the discontinuity in Appendix B (treated) industries vs. non-Appendix B (control) industries — the latter have no new requirement at 100 employees.

3. **Event study:** The discontinuity should emerge in 2024 data (rule effective Jan 1, 2024), not in 2016-2023 pre-periods. This provides 8 placebo years.

4. **Bunching analysis:** Test whether establishments manipulate employee counts to stay below 100 in Appendix B industries post-2024.

## Expected Effects and Mechanisms

- **Disclosure deterrent:** Establishments facing public reporting of detailed injury logs invest more in safety to avoid reputational damage → lower injury rates above threshold.
- **Magnitude prior:** Small-to-moderate reduction (SDE -0.05 to -0.15). Information mandates typically have smaller effects than direct enforcement.
- **Heterogeneity:** Larger effects expected for establishments in consumer-facing industries (reputational costs higher) and those closer to the threshold (marginal compliance).

## Primary Specification

```
Y_ist = α + β₁ · 1(emp ≥ 100) + f(emp - 100) + γ_s + δ_t + ε_ist
```

Where Y is injury rate (total case rate, DART rate), f() is local polynomial, γ_s = NAICS fixed effects, δ_t = year fixed effects. DinD adds interaction with Appendix B indicator.

## Data Sources

1. **OSHA ITA Summary Data (300A):** 2016-2024, ~394K establishments/year. Annual average employees, NAICS, total injuries by category, hours worked. Freely downloadable from OSHA website.

2. **Appendix B industry list:** NAICS codes with 3-year TCR ≥ 3.5 from BLS SOII. PDF available from OSHA.

## Figures Plan (≥5)

1. McCrary density test at 100 employees (pre vs post)
2. RDD plot: injury rate vs. employees (binscatter) — Appendix B vs non-Appendix B
3. Event study: year-by-year discontinuity estimates
4. Bunching analysis: employee count distribution around 100
5. Covariate balance: pre-determined characteristics across threshold
6. Heterogeneity: consumer-facing vs non-consumer-facing industries
