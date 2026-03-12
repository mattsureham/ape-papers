# Research Plan: Leveling the Tax Field

## Research Question

Did the staggered adoption of economic nexus sales tax laws following *South Dakota v. Wayfair* (2018) slow the structural reallocation of employment from brick-and-mortar retail to warehousing and logistics?

## Background

On June 21, 2018, the Supreme Court ruled that states could require online retailers to collect sales tax without physical presence. This eliminated a 5-10% price advantage that online retailers had enjoyed over local stores. States adopted economic nexus laws in waves: ~32 states in Q3-Q4 2018, ~10 more in Q1-Q2 2019, and remaining states through 2021. Five states (AK, DE, MT, NH, OR) have no statewide sales tax and are never-treated.

During 2016-2023, the retail-to-warehouse employment ratio fell from 3.33 to 2.38 — a massive structural shift. If online tax equalization reduced the competitive disadvantage of physical retail, it should have slowed this reallocation.

## Identification Strategy

**Design:** Callaway-Sant'Anna (2021) staggered DiD exploiting variation in state adoption timing.

**Treatment:** State enacts economic nexus law (binary).

**Primary specification:**
- Outcome: log(retail employment / warehouse employment) at county-quarter level
- Unit: county-quarter
- Fixed effects: county, quarter
- Clustering: state level (51 clusters)
- Estimator: CS-DiD with not-yet-treated + never-treated as control

**Triple-difference:** Retail (NAICS 44-45) vs non-tradeable services (NAICS 62 healthcare, 61 education) within the same county-quarter.

**Dose-response:** State sales tax rate as continuous treatment intensity (range: 2.9% CO to 7.25% CA/IN/TN).

## Expected Effects

1. **Retail employment:** Positive (tax equalization stabilizes retail). Small to moderate effect.
2. **Warehouse employment:** Null or small negative (reduced competitive advantage of online fulfillment).
3. **Retail/warehouse ratio:** Positive (slower structural shift in treated states).
4. **Firm dynamics:** Reduced job destruction in retail (FrmJbLs falls), possible reduced job creation in warehousing.
5. **Age-specific:** Young workers (14-24) in retail most affected — they are the marginal hires.

## Data

- **QWI Parquet on Azure:** `derived/qwi/sa/ns/*.parquet` — 182M rows, 3,144 counties, quarterly 2001-2025
- **Variables:** Emp, HirA, HirN, Sep, FrmJbGn, FrmJbLs, EarnS by county × quarter × industry × age
- **Industries:** NAICS 44-45 (retail), 48-49 (transport/warehousing), 62 (healthcare placebo), 61 (education placebo)
- **Policy timing:** NREL AFDC Transportation Laws API + manual compilation from NCSL

## Placebo/Robustness

1. **Placebo sectors:** Healthcare (62), education (61) — non-tradeable, no online competition
2. **Pre-trends:** Event study 2014 Q1 - treatment quarter
3. **Bacon decomposition:** Verify clean comparisons dominate
4. **HonestDiD:** Sensitivity to parallel trends violations
5. **Permutation inference:** Randomly reassign treatment timing
6. **Exclude COVID period:** Restrict to 2014-2019 Q4 for pre-COVID identification
7. **Dose-response:** Higher tax rate states → larger stabilization effect

## Risks

1. **COVID confound:** Wave 3 states (2020-2021) adopted during pandemic. Mitigation: focus on Wave 1/2 (pre-COVID).
2. **Amazon effect:** Amazon began collecting sales tax in all states by April 2017, BEFORE Wayfair. This affects the largest retailer but not the thousands of smaller online sellers covered by nexus laws.
3. **Concurrent policies:** Some states offered retail incentives. Control for state-time trends.
4. **QWI suppression:** Small counties may have suppressed cells. Drop counties with >20% suppression.
