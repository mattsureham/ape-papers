# Research Plan: The Franc Shock and Retail Desertification in Swiss Border Municipalities

## Research Question
Did the January 2015 Swiss franc floor removal cause permanent retail desertification in border municipalities? The overnight ~15% appreciation made cross-border shopping cheaper, potentially destroying local retail firms. We test whether this initial shock reversed or persisted, creating lasting retail access deserts in border communities.

## Identification Strategy
**Difference-in-Differences with continuous treatment intensity.**

- **Treatment:** Distance from municipality centroid to nearest accessible cross-border shopping location (border crossing with retail on the other side).
- **Dose:** Continuous — municipalities closer to the border experienced larger cross-border shopping shocks.
- **Comparison:** Interior municipalities (>30km from any border crossing) serve as controls.
- **Panel:** 2,136 municipalities × 13 years (2011–2023), annual.
- **Base year:** 2014 (last full pre-treatment year).
- **Event study:** Year-by-year coefficients relative to 2014 base year.

**Exposure alignment:** Treatment exposure is measured at the canton level using a continuous border proximity index (0-1). The treated population is all retail establishments and workers in cantons with border exposure > 0 (15 cantons). The control population is retail establishments in 11 interior cantons with zero border exposure. The treatment variable captures the degree to which a canton's population has access to cross-border shopping destinations. The shock (franc appreciation) is national, but its retail impact is mediated by geographic proximity to foreign retailers.

**Key identifying assumptions:**
1. Parallel trends in retail outcomes between border and interior cantons pre-2015.
2. No other canton-level shocks correlated with border proximity and timed at January 2015.

**Placebo tests:**
- Non-retail services (hospitality, professional services) within the same municipalities — these should be less affected by cross-border shopping.
- French vs. German vs. Italian border regions (different neighboring retail environments).

## Expected Effects and Mechanisms
- **Retail establishments:** Decline in border municipalities, especially in non-food retail (clothing, electronics) where price comparison is easiest.
- **Retail employment:** Decline proportional to establishment losses.
- **Persistence:** If retail firms close and are not replaced, the effect persists long after the exchange rate partially reversed.
- **Mechanism:** Swiss consumers substituting to cheaper EU retailers → reduced revenue → firm exit → remaining consumers must travel further.

## Primary Specification
```
Y_{it} = α_i + γ_t + β_t × BorderProximity_i + X_{it}δ + ε_{it}
```
Where:
- Y_{it}: log retail establishments (or employment) in municipality i, year t
- α_i: municipality fixed effects
- γ_t: year fixed effects
- β_t: year-specific coefficients on border proximity (continuous dose)
- BorderProximity_i: inverse distance to nearest border crossing (or binary <15km)
- X_{it}: optional municipal controls (population, language region)
- Clustering: at canton level (26 cantons)

## Data Sources
1. **STATENT** (BFS): Municipal-level establishment counts, employment, and FTE by NOGA sector. Annual, 2011–2023. Access via BFS PXWeb API (no key needed).
2. **Municipal geography:** BFS Gemeindenummer with centroid coordinates. Distance to border crossings computed from geographic data.
3. **Exchange rate:** SNB daily EUR/CHF rate for context (not needed for estimation).

## Key Risks
- STATENT sector breakdowns may not be available at municipality level via PXWeb (may need cantonal or broader geography). If so, use canton-level retail data with ~2,000+ municipalities providing dose variation.
- Small municipalities with 0-2 retail firms may generate measurement issues → consider log(1+Y) or Poisson specifications.
- The partial franc reversal (1.03 → 1.08 by 2017) may attenuate long-run effects.
