# Research Plan: The Segregation Dividend — Racial Composition and Earnings in American Social Assistance

## Research Question

Black workers in social assistance (NAICS 624) earned at or above parity with White workers circa 1995–2001, then experienced persistent decline to 0.94–0.98 even as Black employment share grew from 18% to 27%. This paper documents this undescribed phenomenon and tests whether Medicaid expansion — by expanding demand for home- and community-based services — drove the compositional shift that depressed relative earnings.

## Identification Strategy

**Primary:** Staggered difference-in-differences exploiting ACA Medicaid expansion (2014–2021, ~38 states) using Callaway & Sant'Anna (2021). Treatment: state adopts Medicaid expansion. Outcome: Black/White earnings ratio in NAICS 624. Unit: county × quarter.

**Triple-difference:** Race (Black vs White) × Medicaid expansion state × Post-expansion. This absorbs:
- State-level shocks common to all races
- National trends in Black employment
- Time-invariant state-race differences

**Placebos:**
1. NAICS 62 excluding 624 (Health Care) — similar sector, different workforce composition
2. NAICS 72 (Accommodation/Food Services) — similar demographics, different policy channel
3. Pre-period falsification (assign treatment 4 years early)

## Expected Effects and Mechanisms

**Hypothesis:** Medicaid expansion increased demand for HCBS (home- and community-based services), creating entry-level social assistance jobs. These new positions were disproportionately filled by Black workers (extensive margin), but at lower average earnings than incumbent Black workers, producing a compositional drag on the Black earnings average.

**Expected signs:**
- Medicaid expansion → ↑ Black employment in 624 (positive, large)
- Medicaid expansion → ↓ Black/White earnings ratio in 624 (negative, moderate)
- Decomposition: within-job earnings stable; between-job composition drives the gap

## Primary Specification

```
Y_{c,t}^{race} = α_c + γ_t + β × 1[MedicaidExpansion_{s(c),t}] + X_{c,t}δ + ε_{c,t}

where:
- Y = ln(average quarterly earnings) or B/W earnings ratio
- c = county, t = quarter, s(c) = state of county c
- MedicaidExpansion = 1 after state s adopts expansion
- X = county-level controls (population, industry mix)
- SEs clustered at state level
```

**CS estimator:** `did::att_gt()` with not-yet-treated as comparison group, state-level clustering, universal base period.

## Data Source and Fetch Strategy

**Primary data:** QWI race/ethnicity × 3-digit NAICS
- Azure path: `az://derived/qwi/rh/n3/*.parquet`
- Variables: `Emp`, `EarnS`, `HirA`, `Sep`, `TurnOvrS`
- Filter: NAICS 624 (Social Assistance) + 621/622/623 (placebo) + 72 (placebo)
- Race: White alone (A1), Black alone (A2)
- Coverage: All states, 2001–present (quarterly)

**Medicaid expansion dates:** KFF state-by-state adoption timeline (well-established in literature)

**Sample:** ~3,000 counties × ~90 quarters × 2 races = ~540,000 potential observations (before suppression)

## Key Risk

QWI cells with few workers are suppressed (flagged). NAICS 624 at the county-race level may have substantial suppression, especially for Black workers in rural counties. If suppression is >40%, aggregate to state level. The smoke test suggests national aggregates are fine, but county-level granularity needs verification.
