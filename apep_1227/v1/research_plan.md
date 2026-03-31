# Research Plan: Unlocking the Gate — Occupational Licensing Deregulation and Hispanic Earnings

## Research Question

Do universal occupational license recognition laws — which allow workers licensed in one state to practice in another without re-licensing — differentially benefit Hispanic workers? Hispanic workers are disproportionately concentrated in licensed trades (construction, personal care, health aides) where credential transfer barriers are highest. If licensing barriers impose a "credential tax" that falls disproportionately on mobile and immigrant-origin workers, deregulation should compress the Hispanic–non-Hispanic earnings gap in licensed industries.

## Identification Strategy

**Design:** Staggered difference-in-differences with triple-difference extension.

**Treatment:** State enactment of universal license recognition laws (2019–2024). Arizona was first in 2019; approximately 26 states have enacted by 2024. Treatment is binary (enacted = 1) at state-year level.

**Treatment timing (from IJ database and legislative records):**
- 2019: Arizona (Apr), Montana (Mar), Pennsylvania (Jul)
- 2020: Utah (Mar), Florida (Jun), Missouri (Jul), Iowa, Idaho, Mississippi
- 2021: Montana expanded, Kansas, Wyoming, New Jersey, Colorado, Wisconsin, West Virginia, North Dakota
- 2022: Ohio, Arkansas, Georgia, Indiana, Louisiana, Nebraska, Virginia (2023)
- Later: Additional states through 2024

**Core DiD:** Compare earnings/employment in treated states (post-enactment) vs never-treated states, using Callaway–Sant'Anna estimator for staggered adoption.

**Triple-difference (preferred):** Reform_s × Post_st × Hispanic_g. This absorbs:
- State-level economic shocks (state × time FE)
- National Hispanic trends (ethnicity × time FE)
- Persistent state-ethnicity differences (state × ethnicity FE)

**Key identifying assumption:** Conditional on state and ethnicity fixed effects, the Hispanic–non-Hispanic earnings gap would have evolved identically in reform and non-reform states absent the policy. Pre-trends (2009–2018) testable with event study.

## Expected Effects and Mechanisms

**Primary hypothesis:** Universal recognition reduces barriers for licensed workers relocating across states. Hispanic workers — who have higher interstate mobility and face additional credential barriers (language, documentation) — should benefit disproportionately.

**Expected sign:** Positive effect on Hispanic earnings relative to non-Hispanic, concentrated in licensed industries (construction, health care, personal care).

**Mechanism channels:**
1. **Mobility channel:** More Hispanic workers can move to higher-wage states
2. **Formalization channel:** Workers in informal/unlicensed roles gain access to licensed positions
3. **Competition channel:** Increased labor supply could compress wages (opposing effect)

**Null hypothesis:** If licensing barriers are not the binding constraint for Hispanic workers, or if universal recognition is poorly implemented/rarely used, we expect a null result.

## Primary Specification

```
Y_{sgt} = α + β(Reform_s × Post_st × Hispanic_g) + γ(Reform_s × Post_st)
          + δ(Reform_s × Hispanic_g) + θ(Post_st × Hispanic_g)
          + μ_sg + λ_gt + τ_st + ε_{sgt}

where:
  s = state, g = ethnicity (Hispanic/non-Hispanic), t = quarter
  Y = log average monthly earnings (EarnS from QWI)
  μ_sg = state × ethnicity FE
  λ_gt = ethnicity × quarter FE
  τ_st = state × quarter FE
  Clustering: state level (51 clusters)
```

## Data Sources

1. **QWI race×ethnicity panel** (Azure: `derived/qwi/rh/ns/*.parquet`)
   - County × quarter × NAICS sector × ethnicity (Hispanic A2 vs Non-Hispanic A1)
   - Outcomes: EarnS (avg monthly earnings), Emp (employment), HirA (hires)
   - Coverage: 2001–present, all 51 states
   - Aggregate county → state for state-level analysis (treatment is state-level)

2. **Treatment timing:** Constructed from IJ legislative advocacy page + state session law citations
   - Binary: state enacted universal recognition (year-quarter)
   - ~26 treated states, ~25 never-treated

3. **Industries of interest:**
   - Construction (NAICS 23) — heavily licensed
   - Health Care (NAICS 62) — heavily licensed
   - Other Services incl. personal care (NAICS 81) — heavily licensed
   - Retail (NAICS 44-45) — lightly licensed (placebo)
   - Accommodation/Food (NAICS 72) — lightly licensed (placebo)

## Fetch Strategy

1. Query Azure QWI rh/ns Parquet for all states, NAICS sectors 23/62/81/44-45/72, ethnicity A1/A2, all quarters 2009–2024
2. Aggregate county-level data to state level (weighted by employment)
3. Construct treatment timing from web-sourced legislative dates
4. Merge treatment timing with QWI panel

## Robustness

- Event study (Callaway–Sant'Anna group-time ATTs)
- Placebo industries (retail, food services — low licensing)
- Placebo outcomes (employment in non-licensed manufacturing)
- Leave-one-state-out (jackknife)
- Wild cluster bootstrap (few-cluster inference)
- HonestDiD sensitivity bounds for parallel trends violations
