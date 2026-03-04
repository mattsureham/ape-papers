# Initial Research Plan: apep_0495

## Research Question

Does making private schooling more expensive increase the capitalization of state school quality into house prices? We exploit the UK's January 2025 imposition of 20% VAT on private school fees as a large, exogenous price shock to test whether private schools attenuate the capitalization of state school quality — and whether removing this "safety valve" reshapes the housing market geography of educational opportunity.

## Identification Strategy

**Triple-Difference (DDD) Design:**

1. **Treatment intensity (Dimension 1):** Baseline private school pupil share by Local Authority (LA). LAs with higher private school penetration experience a larger "effective treatment" because more families face the fee shock.

2. **Mechanism channel (Dimension 2):** Properties near Outstanding/Good-rated state schools vs. properties near Requires Improvement/Inadequate state schools. The VAT should increase demand for houses near good state schools specifically — not near bad ones.

3. **Time (Dimension 3):** Pre vs. post-VAT shock. We exploit three information dates:
   - Labour election victory: July 4, 2024 (policy becomes likely)
   - Budget confirmation: October 30, 2024 (policy becomes certain)
   - Implementation: January 1, 2025 (fees actually increase)

**Primary estimating equation:**

log(Price)_{ijlt} = α + β₁(HighPrivate_l × NearGoodSchool_j × Post_t) + β₂(HighPrivate_l × Post_t) + β₃(NearGoodSchool_j × Post_t) + γ_l + δ_j + θ_t + X'_{ijlt}Γ + ε_{ijlt}

where i = transaction, j = property postcode, l = LA, t = year-month.

β₁ is the coefficient of interest: the differential increase in the school quality premium in areas with high private school penetration after the VAT shock.

## Expected Effects and Mechanisms

**Mechanism chain:**
1. VAT increases private school fees by ~14-20% (some schools absorb part)
2. Marginal families switch from private to state sector (~37,000 pupils per government estimate)
3. Families seeking good state schools compete for housing near top-rated schools
4. House prices near Outstanding/Good schools rise relative to those near weaker schools
5. Effect is concentrated in areas where private schools were a viable alternative (high-penetration LAs)

**Expected sign:** β₁ > 0 (positive DDD coefficient). The school quality premium in house prices should increase more in high-private-school areas after the VAT shock.

**Magnitude benchmark:** Gibbons & Machin (2003) estimate a 3-4% premium per SD of primary school quality. Fack & Grenet (2010) find this premium is ~50% smaller in areas with dense private schools. If the VAT reverses part of this attenuation, we might expect β₁ ≈ 1-3% of property value.

## Primary Specification

- **Sample:** All residential property transactions in England, 2015-2026 (Land Registry PPD)
- **Treatment measure:** LA-level private school pupil share (from GIAS data, measured pre-2024)
- **School quality:** Ofsted rating (Outstanding/Good vs Requires Improvement/Inadequate) of nearest state secondary school within 3km
- **Outcome:** log(transaction price)
- **Fixed effects:** LA, postcode sector, year-month
- **Clustering:** LA level (~300 clusters)
- **Controls:** Property type (detached/semi/terrace/flat), new-build indicator, freehold/leasehold

## Exposure Alignment

- **Who is actually treated?** Families who would otherwise send children to private school — those near the margin of private vs. state schooling. This is a household-level treatment; we observe it through housing market prices.
- **Primary estimand population:** Properties near state schools in areas with high private school penetration
- **Placebo/control population:** (1) Properties in areas with zero/low private school penetration, (2) Properties near poorly-rated state schools (demand should not shift here), (3) Commercial properties
- **Design:** Triple-difference (DDD)

## Power Assessment

- **Pre-treatment periods:** 108 months (Jan 2015 – Dec 2023, with Jul-Dec 2024 as anticipation)
- **Post-treatment periods:** ~14 months (Jan 2025 – Feb 2026)
- **Treated clusters (high-private LAs):** ~100 LAs with private school share > median
- **Observations:** ~8-10 million transactions over the full period
- **MDE:** With millions of transactions and 300 LA clusters, the MDE for a 1% price differential should be well below 0.5 percentage points. We will compute exact MDE after data assembly.

## Planned Robustness Checks

1. **Pre-trends:** Event study with 10+ years of monthly pre-treatment data + HonestDiD bounds
2. **Zero-treatment placebo:** LAs with no private schools → should show null DDD
3. **Property-type placebo:** Commercial transactions → should show null
4. **Temporal placebo:** Same DDD with fake treatment date (Jan 2020) → should show null
5. **Continuous treatment intensity:** Replace binary high/low with continuous private school share
6. **Alternative school quality measures:** KS2/KS4 test scores instead of Ofsted ratings
7. **Distance cutoffs:** Vary the "near school" radius (1km, 2km, 3km, 5km)
8. **Leave-one-out:** Drop each region in turn
9. **Heterogeneity:** By LA deprivation quintile, property type, London vs. non-London
10. **Within-LA price dispersion:** Does P90/P10 ratio increase more in high-treatment LAs?
11. **Announcement decomposition:** Separate event studies around election (Jul 2024), Budget (Oct 2024), implementation (Jan 2025)
