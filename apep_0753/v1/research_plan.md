# Research Plan: The Hunger Cliff and the Corner Store

## Research Question

Does the expiration of SNAP Emergency Allotments (EA) cause SNAP-authorized retailers — particularly small-format convenience stores — to exit the market? The EA program provided an additional ~$95/month per household to ~41 million SNAP participants. Its staggered expiration across states created a $46 billion demand shock to the food retail sector that served SNAP households. If so, EA expiration creates a compound welfare loss: households lose both purchasing power AND physical food access.

## Identification Strategy

**Staggered Difference-in-Differences** exploiting political variation in EA opt-out timing.

- **Treatment**: State-level EA expiration. 18 states opted out early between April 2021 (Idaho) and January 2023 (South Carolina). The remaining 32 states + DC saw universal termination in March 2023 (Consolidated Appropriations Act).
- **Estimator**: Callaway-Sant'Anna (2021) for heterogeneity-robust staggered DiD. Treatment is absorbing (once EA expires, it doesn't return).
- **Comparison group**: Not-yet-treated states (states still receiving EA at time of early opt-out).
- **Key insight**: Opt-out decisions were made by Republican governors for political/fiscal reasons, not in response to local retail conditions — providing plausibly exogenous variation.

**Within-system placebo**: Non-SNAP-authorized retailers in the same states/tracts should be unaffected by EA expiration (they don't accept EBT). This is a store-type DDD that addresses state-level confounds.

**Internal replication**: The March 2023 universal termination provides a second natural experiment with a different set of treated states and timing.

## Expected Effects and Mechanisms

1. **Primary**: EA expiration reduces SNAP benefit flows → convenience stores (high SNAP revenue share) lose revenue → marginal stores exit
2. **Heterogeneity**: Effects should be larger for:
   - Convenience stores vs supermarkets (higher SNAP revenue dependence)
   - Rural areas (fewer alternative stores, thinner markets)
   - States with higher pre-EA SNAP participation rates (larger demand shock)
3. **Non-effect**: Non-SNAP retailers should show no response (placebo)
4. **Magnitude**: Effect likely moderate — EA was temporary, so some retailers may have anticipated expiration

## Primary Specification

**Unit of analysis**: State × quarter (or state × month for FNS data)

**Outcome**: SNAP retailer exit rate (deauthorizations per 1,000 authorized stores) by store type

**Model**:
```
Y_{s,t} = α_s + γ_t + β · EA_expired_{s,t} + ε_{s,t}
```

Using Callaway-Sant'Anna with group = EA expiration quarter, time = quarter, unit = state.

**Clustering**: State level (50 clusters — sufficient for conventional CRSEs)

**Event study**: Dynamic ATT estimates for quarters -8 to +8 around EA expiration

## Data Sources

1. **SNAP Retailer Historical Database** (USDA FNS): 703K+ SNAP-authorized retailers with store type, authorization date, end date, location (lat/lon, state, county, tract). Bulk CSV download.

2. **FNS State-Monthly SNAP Data** (USDA FNS): State × month participation counts and benefit amounts. Used to (a) confirm exact EA expiration dates from cost-per-person drops and (b) construct treatment intensity measures.

3. **EA Opt-Out Dates**: Documented in Lakhani et al. (2024, Health Affairs) supplementary materials and USDA/CBPP publications.

## Robustness Checks

1. Event study pre-trends (flat pre-trend validation)
2. Store-type DDD (SNAP convenience stores vs non-SNAP businesses)
3. Heterogeneity by store type (convenience, small grocery, supermarket)
4. Urban vs rural split
5. Treatment intensity (pre-EA SNAP benefit share of state retail sales)
6. Bacon decomposition to verify clean comparisons
7. Randomization inference for p-values

## Key Risks

- **COVID confound**: EA operated during pandemic. Early opt-out states (2021) overlap with early reopeners. Mitigation: store-type DDD, later opt-outs (2022-2023) are post-pandemic, state-level COVID controls.
- **Anticipation**: Retailers may have anticipated EA expiration. Mitigation: check for pre-trend divergence.
- **Aggregation**: State-level analysis may wash out tract-level effects. Mitigation: county-level analysis as robustness.
