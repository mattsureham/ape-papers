# Research Plan: Unshackled but Unequal? Non-Compete Bans and the Racial Worker Mobility Gap

## Research Question

Do state non-compete agreement (NCA) bans reduce racial disparities in worker mobility? NCAs are pervasive in knowledge-intensive sectors and disproportionately constrain minority workers who lack resources to challenge enforcement. We exploit the staggered adoption of NCA bans across five states (2020–2023) using a triple-difference design: ban vs. non-ban states × knowledge-intensive vs. service sectors × Black vs. White workers. If NCAs are more binding for Black workers, bans should disproportionately increase Black worker mobility in covered industries — closing the racial separation rate gap.

## Identification Strategy

**Triple-difference (DDD).** The core design interacts three margins:
1. **Time:** Pre- vs. post-ban periods
2. **Geography:** Ban states (OR, WA, CO, IL, MN) vs. control states
3. **Industry:** Knowledge-intensive sectors (NAICS 51 Information, 54 Professional Services) where NCAs are prevalent vs. NAICS 72 (Accommodation & Food Services) where NCAs are rare

**Race as the fourth dimension:** Within this DDD, we estimate separate effects for Black (A2) vs. White (A1) workers to test whether bans differentially close the racial mobility gap.

**Callaway–Sant'Anna** for staggered adoption, treating each state's ban date as a separate cohort. CA/OK/ND serve as always-treated benchmarks (never enforced NCAs).

**Treatment timing:**
- OR: Jan 2020 (workers earning ≤ state median)
- WA: Jan 2020 (workers earning ≤ $100K)
- CO: Aug 2022 (workers earning ≤ ~$101K)
- IL: Jan 2022 (strengthened restrictions)
- MN: Jul 2023 (complete ban)

## Expected Effects and Mechanisms

1. **Separation rates:** NCA bans should increase voluntary separation (job-to-job transitions) in knowledge sectors. The increase should be larger for Black workers if NCAs were more binding for them.
2. **New hire rates:** Corresponding increase in hiring as previously locked-out workers become available.
3. **Earnings:** Ambiguous direction — mobility may raise earnings through better matching, but increased labor supply could dampen wages.
4. **The racial gap:** If Black workers face differential enforcement (employers more likely to threaten NCA enforcement against minority workers), the ban removes a constraint that binds more for Black workers → racial gap in separations narrows.

## Primary Specification

```
Y_{i,s,t} = α + β₁(Post_s × Ban_s × Knowledge_i) +
            β₂(Post_s × Ban_s × Knowledge_i × Black) +
            γ_{county} + δ_t + θ_{industry} + Controls + ε_{i,s,t}
```

Where:
- i = county × industry × race cell
- s = state
- t = quarter
- Knowledge = 1 for NAICS 51/54, 0 for NAICS 72
- Black = 1 for race code A2, 0 for A1

β₁ = average DDD effect; β₂ = differential effect for Black workers (key coefficient)

**Standard errors:** Clustered at state level (few clusters → wild cluster bootstrap).

## Data Source and Fetch Strategy

**Azure Blob Storage** (confirmed accessible):
- `derived/qwi/rh/ns/*.parquet` — State × quarter × industry × race QWI data
- `derived/qwi/rh/n3/*.parquet` — County × quarter × industry × race QWI data (NAICS 3-digit)

**Key variables:**
- `Emp` — Beginning-of-quarter employment
- `EmpEnd` — End-of-quarter employment
- `Sep` — Separations
- `HirA` — All hires
- `EarnS` — Average monthly earnings
- Race codes: A1 (White), A2 (Black)
- Industry: NAICS 51, 54 (treated), 72 (placebo)

**Sample:** 2016 Q1–2023 Q4, all states. Treatment states: OR, WA, CO, IL, MN. Always-treated: CA, OK, ND. Control: remaining states.

## Risk Assessment

- **Few treatment clusters:** Only 5 treatment states → wild cluster bootstrap for inference. Will also report randomization inference.
- **Income thresholds:** OR/WA/CO bans only cover workers below income thresholds, but QWI doesn't have income-based selection. This attenuates estimates toward zero (conservative).
- **Concurrent policies:** COVID overlaps with OR/WA bans (Jan 2020). Triple-diff helps: COVID affects treated/control industries symmetrically within race, so it nets out.
