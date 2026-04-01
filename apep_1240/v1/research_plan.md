# Research Plan: Paper Tigers or Groundwater Guardians?

## Research Question

Does India's regulatory notification of overexploited groundwater blocks actually slow depletion, or is it a paper tiger? The Central Ground Water Authority (CGWA) has notified 162 blocks as "overexploited" across 14 states, imposing mandatory No-Objection Certificate (NOC) requirements for non-drinking water extraction. A 2021 CAG audit found 77% of industrial units operated without required NOCs, suggesting negligible enforcement. This paper tests whether notification causally reduces groundwater depletion despite weak compliance.

## Identification Strategy

**Design B (primary):** Among blocks classified as overexploited by CGWB assessments, compare notified blocks (162, where CGWA formally imposed NOC requirements) to non-notified overexploited blocks. Only ~14% of overexploited blocks were notified, creating a sharp treatment margin.

**Design A (supplementary):** Staggered DiD exploiting reclassification of blocks across CGWB assessment rounds (2004, 2009, 2011, 2013, 2017). Blocks newly classified as overexploited in different rounds provide staggered treatment timing.

**Estimator:** Callaway-Sant'Anna for staggered adoption (Design A). TWFE with block and year FE for Design B (common treatment timing within notification waves).

**Key assumption:** Conditional on being classified as overexploited, notified blocks would have followed the same depletion trajectory as non-notified overexploited blocks absent notification. Testable with pre-notification groundwater trends.

## Expected Effects and Mechanisms

**Null hypothesis (paper tiger):** No effect — consistent with CAG finding that 77% of units lack NOCs. Regulation exists on paper but is unenforced.

**Alternative 1 (informal deterrence):** Notification reduces depletion even without formal compliance. Mechanism: notification signals government attention, deterring marginal extractors through fear of future enforcement or political pressure on local officials.

**Alternative 2 (selective compliance):** Large industrial users comply (they face higher regulatory risk), reducing aggregate extraction. Small/agricultural users don't, creating heterogeneous effects by sector.

**Alternative 3 (displacement):** Extraction shifts to adjacent non-notified blocks, creating spatial spillovers. The aggregate effect could be zero even if local regulation "works."

## Exposure Alignment

The treatment (overexploitation classification and NOC requirements) applies at the assessment-block level but is measured at the state level (share of overexploited blocks). The population actually affected includes all groundwater extractors in classified blocks: industrial users who legally require NOCs, and agricultural users who are practically exempt. The state-level design captures the regulatory environment — whether a state has significant overexploitation and associated governance attention — rather than block-level notification. This dilutes the treatment effect but allows estimation with available data (well-level data lack block identifiers). The coarseness biases toward the null, which is the paper's main finding.

## Primary Specification

```
ΔW_{bt} = α + β × Notified_b × Post_t + γ_b + δ_t + X_{bt}θ + ε_{bt}
```

Where:
- ΔW_{bt}: change in groundwater level (meters below ground level) in block b, year t
- Notified_b: indicator for CGWA notification
- Post_t: indicator for post-notification period
- γ_b: block fixed effects
- δ_t: year fixed effects
- X_{bt}: time-varying controls (rainfall, temperature, irrigation area)

β < 0 indicates notification reduces depletion (water table rises or falls less quickly).

## Data Sources

1. **CGWB Monitoring Wells:** ~25,000 stations with quarterly depth-to-water-level measurements (1996–2017+). Source: GitHub (craigdsouza/cgwb) and CGWB GW Data portal. Unit: meters below ground level.

2. **CGWB Block Classification:** Assessment rounds classifying blocks as Safe/Semi-critical/Critical/Overexploited. Source: CGWB reports + digitized data.

3. **CGWA Notification List:** 162 notified overexploited blocks. Source: CGWA website/gazette notifications.

4. **SHRUG (local):** Village/district-level Census data, nightlights (1992–2021), Economic Census for economic activity outcomes. Already available at `data/india_shrug/`.

5. **IMD Rainfall:** District-level precipitation as control variable. Source: IMD gridded rainfall data or NOAA GPCC.

## Fetch Strategy

1. Clone/download CGWB monitoring well data from GitHub (craigdsouza/cgwb)
2. Scrape or download CGWB block classification data across assessment rounds
3. Construct block-to-well mapping (wells → blocks → districts)
4. Merge with SHRUG nightlights at district level for economic outcomes
5. Obtain rainfall data for controls

## Key Risks

1. **Data quality:** CGWB well data may have gaps, measurement error, or non-random station placement
2. **Selection into notification:** Notified blocks may differ systematically from non-notified overexploited blocks (e.g., urban/industrial areas notified first). Mitigated by controlling for pre-notification characteristics and testing pre-trends.
3. **Spatial spillovers:** Extraction displacement to adjacent blocks complicates interpretation. Can test with spatial lag models.
4. **Post-2017 data gap:** CGWB GitHub data may end around 2017. Need to verify coverage.
