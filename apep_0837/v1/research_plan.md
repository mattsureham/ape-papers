# Research Plan: Did France's Right to Disconnect Reduce Overwork?

## Research Question

Does mandatory right-to-disconnect (R2D) legislation reduce long working hours among digitally connected workers? France enacted the world's first R2D law (Loi El Khomri, Article L2242-17) effective January 1, 2017, requiring firms with 50+ employees to negotiate annually on modalities of disconnecting from digital work communications. Eight years later, no published economics paper provides a causal evaluation of any R2D law anywhere.

## Identification Strategy

**Triple-difference (DDD):** (France vs 8 EU control countries) × (high-connectivity occupations ISCO 1-3 vs low-connectivity ISCO 7-9) × (post-2017).

The key identifying assumption is that absent the R2D law, the gap in long-hours rates between high-connectivity and low-connectivity occupations in France would have evolved in parallel with the same gap in control countries. This is weaker than requiring parallel trends for France vs controls overall — it only requires parallel *differential* trends.

**Treatment group:** France (Jan 2017)
**Control countries:** Germany, Netherlands, Austria, Finland, Denmark, Czech Republic, Poland, Hungary (EU members with no R2D law during sample period)
**Excluded:** Spain (2018 R2D), Portugal (2021), Belgium (2023), Italy (2017 partial) — contaminated controls

**Occupation dose:**
- High-connectivity (ISCO 1-3): Managers, Professionals, Technicians — most exposed to digital communication norms
- Low-connectivity (ISCO 7-9): Craft workers, Plant operators, Elementary occupations — least affected by R2D

## Expected Effects and Mechanisms

**Prior expectation:** The law may be toothless. France's long-hours rate for managers fell 5.6pp (2016-2024), but Germany's fell 9.7pp without any R2D law. The naive before-after comparison likely overstates the effect.

**Mechanisms to test:**
1. **Hours reduction:** R2D reduces after-hours email → fewer total hours worked
2. **Reporting shift:** R2D changes social norms around reporting hours but not actual hours
3. **Composition effect:** R2D changes which occupations are classified as "high-connectivity"

**Triple-diff coefficient interpretation:** β₃ > 0 means high-connectivity workers in France saw a *larger* decrease in long hours relative to low-connectivity workers, compared to the same occupational gap in control countries. A null β₃ means the law had no differential effect on the workers it most directly targeted.

## Primary Specification

Y_{cot} = α + β₁(France_c × HighConn_o × Post_t) + γ_{co} + δ_{ct} + θ_{ot} + ε_{cot}

Where:
- Y = share working >48h/week (or usual weekly hours)
- c = country, o = occupation group (ISCO major group), t = year
- γ_{co} = country-occupation FE
- δ_{ct} = country-year FE (absorbs all France-specific time trends, including Macron reforms)
- θ_{ot} = occupation-year FE (absorbs EU-wide trends in remote work, digitalization)
- Clustering: country level (9 clusters → wild cluster bootstrap)

## Data Sources

1. **Eurostat lfsa_qoe_3a2:** Long working hours (>48h/week) by ISCO-08 occupation, country, year. 2010-2024.
2. **Eurostat lfsa_ewhais:** Usual weekly hours by occupation, full-time workers. 2010-2024.
3. **Eurostat hlth_silc_17:** Self-perceived health by country. 2010-2024 (secondary outcome).
4. **Eurostat ilc_pw01:** Life satisfaction by country. 2010-2024 (secondary outcome).

## Robustness and Placebo Tests

1. **Placebo treatment in Germany:** Assign fake R2D treatment to Germany in 2017. Coefficient should be zero.
2. **Placebo occupations:** ISCO 5 (service/sales) as "medium-connectivity" — should show intermediate or no effect.
3. **Event study:** Year-by-year β₃ coefficients, 2010-2024. Pre-2017 coefficients should be zero.
4. **Permutation inference:** Randomly assign treatment to control countries, build distribution of placebo β₃ estimates (addresses 9-cluster concern).
5. **Alternative hours thresholds:** >50h, >55h, >60h per week.
6. **Spain as positive control:** Spain adopted R2D in 2018 — should show similar pattern with 1-year lag if effect is real.
