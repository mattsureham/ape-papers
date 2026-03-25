# Research Plan: apep_0960

## Research Question
Does confiscatory mining taxation destroy local economic activity? Zambia's January 2019 royalty reform raised effective tax rates to 86–105%, triggering mine closures and 21,000 job losses. We estimate the causal effect on nighttime light intensity—a proxy for local economic activity—in mining-dependent vs. non-mining districts.

## Identification Strategy
**Treatment-intensity DiD.** Treatment = pre-reform district-level mining employment share (continuous) or binary mining-district indicator. Treatment timing is common (January 1, 2019), avoiding staggered-adoption complications. TWFE with district and month fixed effects is appropriate here since all treated units are treated simultaneously.

- **Treated districts:** ~10 mining-intensive districts in Copperbelt Province (Kitwe, Ndola, Mufulira, Chingola, Luanshya, Kalulushi, Chililabombwe) and Northwestern Province (Solwezi, Kalumbila)
- **Control districts:** ~100+ non-mining districts
- **Pre-period:** April 2012–December 2018 (81 months of VIIRS nightlights)
- **Post-period:** January 2019–December 2023
- **Partial reversal:** September 2019 (non-deductibility removed) — serves as dose-response test

Key threats: (1) copper price confounding — address by controlling for global copper prices and showing event-study coefficients; (2) COVID-19 in 2020 — present results for Jan–Aug 2019 (pre-reversal) separately; (3) few treated clusters — use wild cluster bootstrap and randomization inference.

## Expected Effects and Mechanisms
- **Primary:** Negative effect on nightlights in mining districts (economic contraction from mine closures and investment halts)
- **Mechanism:** Tax burden → mine closures/curtailment → direct job losses → reduced spending → local economic collapse
- **Magnitude:** Expect large negative SDE given the extreme nature of the tax shock (effective rates 86–105%)
- **Reversal test:** Post-September 2019 partial reversal should attenuate negative effects

## Exposure Alignment
The treatment is the January 2019 mining tax reform, which raises effective tax rates on copper mining to 86–105%. **Who is affected:** All mining firms operating in Zambia, concentrated in Copperbelt and North-Western provinces. The 21 districts in these two provinces constitute the treated group, as mining activity directly sustains local employment, procurement, and services. Non-mining districts in the remaining 8 provinces serve as controls. The reform affects all mining operations simultaneously (common treatment timing), with a partial reversal in September 2019 removing the non-deductibility provision.

## Primary Specification
```
asinh(NTL_it) = α_i + γ_t + β(MiningProvince_i × Post_t) + ε_it
```
Where MiningProvince_i is binary (=1 for districts in Copperbelt or North-Western provinces). Cluster SEs at district level + wild cluster bootstrap + randomization inference.

## Data Sources
1. **VIIRS nightlights:** NASA Black Marble VNP46A4 (annual) or VNP46A3 (monthly) via `blackmarbler` R package + NASA Earthdata token
2. **District boundaries:** GADM Level 2 for Zambia
3. **Mining district classification:** Known mining districts from Copperbelt/Northwestern provinces
4. **World Bank indicators:** GDP, mining rents, copper prices for context
5. **Copper prices:** IMF commodity data or World Bank Pink Sheet

## Robustness
1. Event study (monthly) with pre-trend inspection
2. Wild cluster bootstrap p-values (few clusters)
3. Randomization inference
4. Synthetic control for Copperbelt Province aggregate
5. Placebo: non-mining agricultural districts as treatment
6. Controlling for copper price × mining district interaction
