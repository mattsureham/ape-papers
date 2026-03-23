# Research Plan: apep_0839

## Research Question

Did the October 2021 Thrifty Food Plan (TFP) revision — which permanently increased SNAP benefits by 21% ($36.24/person/month) — reduce household food insecurity? This is the first causal evaluation of the TFP revision, distinct from the temporary COVID-19 Emergency Allotments.

## Identification Strategy

**Primary: Continuous Difference-in-Differences**

Treatment intensity = state pre-TFP SNAP participation rate (2019 ACS). States with higher SNAP shares received a proportionally larger per-capita spending shock. The 3.4:1 ratio between highest and lowest participation states creates meaningful dosage variation.

Specification:
```
FoodInsecurity_{st} = α + β(SNAPShare_s × Post_t) + γ_s + δ_t + ε_{st}
```

Where `SNAPShare_s` is the 2019 state SNAP participation rate (continuous), `Post_t` = 1 for years after October 2021, and `γ_s`, `δ_t` are state and year fixed effects.

**Secondary: Triple-Difference (EA Timing Variation)**

Emergency Allotments (EA) temporarily boosted SNAP to the maximum benefit. States ended EA at different times (April 2021 through March 2023). In states where EA ended before TFP (Oct 2021), the TFP revision had immediate bite. In states where EA continued past Oct 2021, the TFP effect was masked until EA ended.

```
Y_{st} = α + β₁(SNAPShare_s × Post_t) + β₂(SNAPShare_s × Post_t × EarlyEAEnd_s) + FE + ε_{st}
```

Where `EarlyEAEnd_s` = 1 for ~18 states that ended EA before October 2021.

## Expected Effects and Mechanisms

- **Direct mechanism:** Higher benefits → more food purchasing power → reduced food insecurity
- **Expected direction:** Negative (more benefits → less food insecurity)
- **Magnitude prior:** Moderate. A 21% benefit increase is large, but food insecurity is driven by many factors beyond benefit levels
- **Mechanism tests:** (1) Effect should be larger in states with higher SNAP participation, (2) Effect should appear for "low food security" before "very low food security," (3) Triple-diff should show larger effects in early-EA-ending states

## Primary Specification

State-year panel, 50 states + DC, 2018-2023. Outcome: food insecurity rate from USDA ERS (sourced from CPS Food Security Supplement). Treatment: continuous state SNAP participation rate × post-TFP indicator. Standard errors clustered by state.

## Data Sources and Fetch Strategy

| Data | Source | Years | Access Method |
|------|--------|-------|---------------|
| State food insecurity rates | USDA ERS / CPS-FSS | 2018-2023 | Download published tables |
| State SNAP participation | USDA FNS SNAP Data Tables | 2018-2023 | Download CSV/Excel |
| Pre-treatment SNAP share (dosage) | ACS 2019 via Census API | 2019 | Census API |
| EA end dates by state | USDA FNS documentation | 2020-2023 | Published list |
| State-level obesity (secondary) | BRFSS via CDC API | 2018-2023 | CDC PLACES/BRFSS API |
| State controls | FRED / BLS / Census | 2018-2023 | FRED API |

## Key Risks

1. **EA confounding:** Emergency Allotments operated simultaneously. Triple-diff addresses this but requires careful timing documentation.
2. **COVID confounding:** Food insecurity spiked in 2020 regardless of SNAP. Including 2020 may bias estimates. Consider robustness excluding 2020.
3. **Small N:** 50 states × 6 years = 300 observations. Clustering on 50 states is borderline. Will use wild cluster bootstrap.
4. **SUTVA:** Cross-state spillovers unlikely for food security (local consumption).
