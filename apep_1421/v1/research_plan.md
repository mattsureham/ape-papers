# Research Plan: Mining Wealth for the Mines

## Research Question
Does earmarked redistribution of mineral royalties through India's District Mineral Foundations (DMFs) translate into measurable local economic development in mining-affected districts?

## Policy Background
The 2015 MMDR Amendment (January 12, 2015) mandated DMFs in every mining-affected district. Mining leaseholders contribute 30% of royalty (pre-2015 leases) or 10% (post-2015 auction leases). PMKKKY (September 2015) directs 70% to high-priority sectors (water, health, education) and 30% to infrastructure. Cumulative collections reached Rs 53,830 crore (~$6.5B) across 22 states by September 2021.

## Identification Strategy
**Continuous treatment DiD.** Treatment intensity = pre-2015 district mineral production value (or mining employment share from EC2013). Pure control = non-mining districts. The key insight: all mining districts were treated simultaneously (January 2015), but treatment *intensity* varies enormously based on pre-existing mineral production — creating a dose-response design.

- **Primary specification:** log(nightlights) ~ mining_intensity × post2015 | district FE + year FE
- **Clustering:** State level (22 states)
- **Robustness:** (1) Placebo: non-mining districts adjacent to mining districts, (2) Pre-trend test, (3) Alternative treatment measures (binary mining dummy, mining employment share), (4) Dropping top/bottom mineral producers

## Expected Effects
- **Positive:** DMF funds flow to infrastructure and services → economic activity increases in mining districts
- **Mechanism:** Spending on roads, electrification, water → nightlight intensity as proxy
- **Possible null:** Capture by local elites, implementation delays, fungibility with existing state transfers

## Data Sources
1. **SHRUG nightlights** (shrug_nl.csv): District-level VIIRS annual nightlights, 2012-2021
2. **SHRUG EC2013** (shrug_ec13.csv): Mining employment to identify treatment intensity
3. **SHRUG Census 2011 PCA** (shrug_pc11_pca.csv): Population, literacy, workforce controls
4. **SHRUG geographic crosswalk** (shrug_pc11_td.csv): Village → district → state mapping

## Fetch Strategy
All data from local SHRUG files (already downloaded). No API calls needed.
