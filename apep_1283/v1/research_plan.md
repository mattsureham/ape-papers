# Research Plan: Stripping the Floor — Prevailing Wage Law Repeal and the Racial Earnings Gap in Public Construction

## Research Question

Do prevailing wage law repeals widen the Black-to-White earnings gap in construction, and is the effect concentrated in publicly funded subsectors where prevailing wage coverage is densest?

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD** exploiting six state repeals of prevailing wage laws between 2015 and 2018:

| State | Repeal Date | Cohort Quarter |
|-------|-------------|----------------|
| Indiana | July 2015 (SB 518) | 2015Q3 |
| West Virginia | February 2016 (HB 4005) | 2016Q1 |
| Kentucky | January 2017 (HB 3) | 2017Q1 |
| Arkansas | February 2017 (SB 693) | 2017Q1 |
| Wisconsin | September 2017 (Act 59) | 2017Q4 |
| Michigan | June 2018 (HB 4052) | 2018Q2 |

**Control group:** 28 states that maintained prevailing wage laws throughout.

**Unit of analysis:** State × quarter × 3-digit NAICS × race (from QWI rh/n3).

## Mechanism Test (Triple-Difference)

The core identification innovation is the within-state NAICS subsector comparison:

- **NAICS 237** (Heavy/Civil Engineering — roads, bridges, utilities): ~95% publicly funded → densest prevailing wage coverage
- **NAICS 236** (Building Construction — residential/commercial): mostly private → control industry
- **NAICS 238** (Specialty Trades — plumbers, electricians): mixed → partial control

**Prediction:** If prevailing wage laws compress the racial earnings gap by setting above-market floors on public construction wages, repeal should widen the B/W earnings gap primarily in NAICS 237, with attenuated or null effects in NAICS 236/238.

## Expected Effects

- **Main effect:** Negative — repeal widens the B/W earnings ratio (ratio declines by 0.02–0.05)
- **Mechanism:** Effect concentrated in NAICS 237 (public construction)
- **Timing:** Gradual onset over 4–8 quarters as multi-year contracts expire
- **Heterogeneity:** Larger effects in states with higher baseline union density

## Primary Specification

```
Y_{s,t} = ATT(g,t) via Callaway-Sant'Anna
```

Where Y is the Black-to-White average monthly earnings ratio (EarnS race=A2 / EarnS race=A1) in construction (NAICS 23x), estimated at the state-quarter level.

**Clustering:** State level (N=34 states: 6 treated + 28 control).

**Inference:** Wild cluster bootstrap (few-cluster robust) + randomization inference.

## Data Source and Fetch Strategy

**Primary data:** QWI race × 3-digit NAICS files from Azure Blob Storage.
- Path: `az://derived/qwi/rh/n3/*.parquet` (all 51 states confirmed)
- Variables: `EarnS` (average monthly earnings), `Emp` (beginning-of-quarter employment), `race` (A1=White, A2=Black), `industry` (NAICS 3-digit as int64)
- Period: 2010Q1–2023Q4 (12+ pre-quarters before earliest treatment in 2015Q3)

**Technical notes from smoke test:**
- Industry codes stored as int64 — CAST required
- Payroll suppressed (NULL) — use EarnS × Emp as wage bill proxy where needed

## Robustness Checks

1. **Drop concurrent RTW states** (WV, KY): re-estimate on AR, IN, WI, MI only
2. **Placebo industry:** Manufacturing (NAICS 31-33) — no prevailing wage coverage, null expected
3. **Event study:** 12 pre-quarters, 16 post-quarters — test parallel trends visually
4. **Wild cluster bootstrap:** Address few-cluster inference (6 treated states)
5. **Leave-one-out:** Drop each treated state sequentially to check influence

## Key Risks

1. **Few treated clusters (6 states):** Mitigated by wild cluster bootstrap + RI
2. **RTW overlap in WV/KY:** Mitigated by mechanism test (RTW affects all industries equally) and sensitivity analysis dropping concurrent states
3. **QWI suppression:** Some state × race × industry cells may be suppressed for confidentiality. Aggregate to broader categories if needed.
