# Research Plan: Mandating Transparency or Mandating Change?

## Research Question
Does mandatory gender-equality disclosure at the 301-employee threshold in Japan's Women's Active Engagement Act (2016) improve women's workplace outcomes — specifically the gender wage gap and female management representation — or does transparency alone fail to close gaps?

## Identification Strategy
**Fuzzy RDD** at the 301-employee threshold.
- **Running variable:** Firm size (number of regular employees)
- **Cutoff:** 301 employees
- **First stage:** Disclosure compliance jumps from ~14% (101-300) to ~92% (301+) for gender wage gap reporting
- **Instrument:** Indicator for firm size ≥ 301
- **Outcomes:** Gender wage gap (female/male ratio), female manager share, female hiring share

Key diagnostic checks:
1. McCrary density test at 301 (test for manipulation/sorting)
2. Covariate balance: industry, prefecture, listed status
3. Placebo cutoffs at 200 and 400 employees
4. Bandwidth sensitivity (CCT optimal, half, double)

## Expected Effects
- **Transparency channel:** If disclosure alone disciplines firms, expect higher female wage ratios and manager shares just above 301 vs just below
- **Null hypothesis:** Disclosure is cheap talk — no meaningful outcome differences at the threshold
- **Alternative:** Firms just above 301 may strategically reduce headcount to avoid disclosure (bunching below 301)

## Primary Specification
Fuzzy RDD:
```
Y_i = α + τ · D̂_i + f(X_i - 301) + ε_i
```
where D̂_i is predicted disclosure from first-stage: D_i = γ + δ·1(X_i ≥ 301) + g(X_i - 301) + u_i

## Data Sources
1. **MHLW Women's Active Engagement Enterprise Database** (positive-ryouritsu.mhlw.go.jp)
   - 61,566 firms, open CSV
   - Variables: firm size, industry, prefecture, female manager share, gender wage gap, hiring ratios, leave take-up
2. **Firm size variable:** Need to verify whether exact employee count or size bins are available. If bins only, will use sharp comparison at 301 boundary with bin-level variation.

## Potential Complications
- Running variable may be categorical (size bins) rather than continuous — if so, adapt to sharp threshold comparison
- Selection: firms that report outcomes are not random — check selection on observables
- Cross-sectional design limits causal claims to contemporaneous effects
