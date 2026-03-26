# Research Plan: apep_0979

## Research Question

Do Universal Licensing Recognition (ULR) laws narrow the Black-White earnings gap in healthcare? ULR laws allow out-of-state license holders to practice immediately without re-examination. If licensing barriers bind more tightly for Black healthcare workers (due to geographic concentration in states with non-reciprocal agreements), ULR adoption should disproportionately benefit Black workers relative to White workers in healthcare — a "reciprocity dividend."

## Identification Strategy

**Triple Difference (DDD)** exploiting three dimensions of variation:

1. **ULR adoption (staggered DiD):** 11 states adopted comprehensive ULR between 2019-2021
   - Wave 1 (2019): Arizona, Pennsylvania
   - Wave 2 (2020): Idaho, Montana
   - Wave 3 (2021): New Jersey, Ohio, Utah, Colorado, Virginia, Wisconsin, Indiana

2. **Industry:** Healthcare (NAICS 62) vs Manufacturing (NAICS 31-33) placebo
   - Manufacturing workers are not covered by healthcare licensing — ULR should not affect their racial wage gap

3. **Race:** Black vs White workers
   - ULR should disproportionately benefit Black workers if licensing barriers are more binding for them

**Fixed effects:** state×quarter + state×race×industry + quarter×race×industry

The DDD absorbs:
- (a) Any state-specific time trends (e.g., state economic cycles)
- (b) State-level race×industry earnings gaps (structural differences)
- (c) National race×industry trends (e.g., COVID's differential impact on Black healthcare workers)

**Identifying assumption:** Absent ULR, the Black-White healthcare earnings gap would have evolved in parallel across ULR and non-ULR states, relative to manufacturing.

## Expected Effects and Mechanisms

- **Primary hypothesis:** ULR narrows the Black-White wage gap in healthcare (positive DDD coefficient on Black×Healthcare×ULR_post)
- **Mechanism:** Licensing barriers create a "mobility penalty" that disproportionately affects Black workers concentrated in Southern states with restrictive reciprocity agreements. ULR removes this binding constraint.
- **Magnitude prior:** The smoke test found +0.030 log points for Arizona. Expecting SDE in the "small positive" to "moderate positive" range.

## Primary Specification

```
log(avg_wkly_earn) = β(Post_ULR × Black × Healthcare)
                   + state×quarter FE
                   + state×race×industry FE
                   + quarter×race×industry FE
                   + ε

Cluster: state level
Weights: employment count
```

Event study variant replaces Post_ULR with event-time dummies interacted with Black×Healthcare.

## Robustness

1. **Arizona-only (pre-COVID clean):** Arizona adopted 2019, before COVID. Isolates ULR from COVID confounds.
2. **Wild cluster bootstrap:** 11 treated states → inference with few clusters.
3. **Callaway-Sant'Anna on differenced outcome:** Construct state×quarter DDD gap variable, run C-S for heterogeneity-robust staggered DiD.
4. **Alternative placebo industries:** Retail (NAICS 44-45), Finance (NAICS 52) — also not covered by healthcare licensing.
5. **Leave-one-out:** Drop each ULR state in turn.
6. **Pre-trend test:** Event study showing no differential pre-trends in the DDD gap.

## Data Source and Fetch Strategy

- **QWI Race-Hispanic Panel:** Azure `derived/qwi/rh/ns/*.parquet` (~144M rows)
- Filter: NAICS 62 (Healthcare), NAICS 31-33 (Manufacturing), Race: Black & White
- Years: 2015Q1-2022Q4 (32 quarters)
- Unit: state × industry × race × quarter
- Variables: avg_wkly_earn (Emp-weighted mean weekly earnings), Emp (employment)
- Access: DuckDB via `scripts/lib/azure_data.R`

## COVID Pre-emption Strategy

COVID-19 overlaps with ULR adoption (2020-2021). Key defenses:
1. **DDD design:** quarter×race×industry FE absorbs national COVID shocks to Black healthcare workers
2. **Arizona pre-COVID:** Pure pre-COVID adopter for clean identification
3. **Manufacturing placebo:** Manufacturing also hit by COVID but not by healthcare licensing changes
4. **Explicit COVID controls:** Include state-level COVID death rates as robustness
