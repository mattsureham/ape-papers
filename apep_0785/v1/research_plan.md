# Research Plan: apep_0785

## Research Question
Do railroad quiet zone designations — which eliminate mandatory locomotive horn sounding at public crossings — capitalize into residential property values? By exploiting 717 staggered quiet zone designations across 500+ US cities (2005–2024), we provide the first credible causal estimates of noise externality capitalization from rail transport.

## Identification Strategy
**Staggered Difference-in-Differences (Callaway and Sant'Anna 2021)**

- **Treatment:** City-month of first quiet zone designation (from FRA crossing inventory)
- **Control:** Cities with public railroad crossings that never receive quiet zone designation
- **Unit of observation:** City × month
- **Outcome:** Zillow Home Value Index (ZHVI), all homes, smoothed, seasonally adjusted

### Why Timing Is Exogenous to Housing
Quiet zone designation requires: (1) municipal application, (2) FRA review, (3) railroad cooperation, (4) completion of safety upgrades (supplementary safety measures like medians, four-quadrant gates). The approval timeline depends on FRA processing backlogs, engineering construction schedules, and railroad-municipality negotiations — not housing market dynamics. Treatment timing variation is driven by bureaucratic and engineering frictions.

### Threats and Tests
- **Pre-trends:** Event-study coefficients for 24+ months pre-treatment should be flat
- **Anticipation:** Safety upgrades (construction) may signal impending quiet zone; test with leads
- **Selection:** Cities that apply for quiet zones may differ; restrict to eventual-adopter design
- **Spillovers:** Neighboring cities' designations; control for MSA-by-year FE
- **Dose-response:** Cities with more crossings silenced should show larger effects

## Expected Effects and Mechanisms
- **Primary:** Positive effect on ZHVI — noise reduction is a local amenity improvement
- **Mechanism:** Hedonic capitalization of reduced noise externality
- **Magnitude:** Prior cross-sectional literature (Theebe 2004, Clark & Kim 2023) suggests 1–5% noise discount for properties near rail. City-average effects will be attenuated since only properties near crossings benefit directly.
- **Heterogeneity:** Effect should be larger in cities with (a) more crossings, (b) higher baseline train frequency, (c) smaller geographic area (more concentrated treatment)

## Primary Specification
$$Y_{ct} = \alpha_c + \gamma_t + \sum_g \sum_t ATT(g,t) + \varepsilon_{ct}$$

Where $c$ indexes cities, $t$ indexes months, $g$ is the cohort (designation month). Estimate group-time ATTs using `did` package (Callaway-Sant'Anna), aggregate to dynamic event-study and overall ATT.

## Data Sources
1. **FRA Grade Crossing Inventory** (SODA API): All public crossings with quiet zone status, effective dates, city, state, crossing type
2. **Zillow ZHVI** (public CSV): City-level monthly home value index, 2000–2024
3. **Supplementary:** Census CBP for city-level economic controls; FRA highway-rail crossing accident database for safety outcomes

## Exposure Alignment
The treatment (quiet zone designation) occurs at individual railroad crossings, but the outcome (ZHVI) is measured at the city level. This creates a fundamental exposure mismatch: quiet zone benefits accrue to residents within ~0.5 miles of silenced crossings, while city-level ZHVI averages over the entire housing stock. This design will therefore estimate a heavily attenuated city-level average effect. The attenuation is a feature of the available data, not the identification strategy — future work with zip-code or tract-level outcomes could recover sharper local estimates. We quantify the expected attenuation in the paper's discussion section.

## Fetch Strategy
1. Query FRA SODA API for all crossings with quiet zone indicators → identify treated cities and dates
2. Download Zillow ZHVI city-level CSV from Zillow research data
3. Merge on city-state identifiers
4. Construct treatment cohort variable from first quiet zone date per city
