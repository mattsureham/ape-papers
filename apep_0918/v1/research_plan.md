# Research Plan: Clearing the Air at the Circular

## Research Question

Does expanding a Low Emission Zone reduce local air pollution? We estimate the causal effect of London's October 2021 ULEZ expansion on nitrogen dioxide (NO2) concentrations using station-level monitoring data and a difference-in-differences design.

## Why It Matters

Over 320 Low Emission Zones operate across European cities, yet causal evidence of their air quality effects remains contested. Existing evaluations of London's ULEZ rely on weather-detrending models or aggregate city-level comparisons, not formal econometric designs with proper counterfactuals. This paper provides the first station-level DiD estimate using modern heterogeneity-robust methods.

## Identification Strategy

**Design:** Station-level difference-in-differences.

- **Treatment group:** ~52 monitoring stations inside the expanded ULEZ zone (within the North/South Circular roads), newly treated October 25, 2021.
- **Control group:** ~160 monitoring stations outside the ULEZ boundary (in outer London), untreated until August 29, 2023.
- **Panel:** Station × month, January 2018 through August 2023.
- **Estimator:** Callaway-Sant'Anna (2021) with event study. All stations share the same treatment date (Oct 2021), so this is a two-group DiD — but CS provides clean event-study estimates and avoids forbidden comparisons if we later incorporate the 2023 expansion as a second treatment cohort.

**Key assumption:** Parallel trends in NO2 between inner and outer London stations, conditional on station fixed effects and month-of-sample fixed effects.

## Expected Effects and Mechanisms

- **Primary:** Reduction in NO2 at treated (inner London) stations relative to outer London controls. ULEZ charges £12.50/day for non-compliant vehicles, incentivizing fleet upgrade or route diversion.
- **Dose-response:** Larger effects at stations closer to the ULEZ boundary (where traffic composition changes most), with attenuation at greater distances.
- **Spillovers:** Possible increase in NO2 at control stations near the boundary (traffic diversion).

## Primary Specification

$$NO2_{it} = \alpha_i + \gamma_t + \beta \cdot \text{Post}_t \times \text{Inner}_i + X_{it}'\delta + \varepsilon_{it}$$

Where $\alpha_i$ are station FE, $\gamma_t$ are year-month FE, Inner_i = 1 for stations inside the expanded ULEZ, Post_t = 1 for months after October 2021. Standard errors clustered at station level.

## Robustness

1. **Placebo:** Use the August 2023 London-wide expansion as a replication shock (outer London stations become treated).
2. **Event study:** Pre-trend test for 12+ months before October 2021.
3. **HonestDiD:** Rambachan-Roth sensitivity bounds for pre-trend violations.
4. **Leave-one-out:** Drop each station and re-estimate.
5. **Weekend/weekday:** Traffic volume differs; effects should be larger on weekdays.
6. **Distance dose-response:** Estimate effects by distance from ULEZ boundary.

## Data Sources

1. **LAQN (London Air Quality Network):** Hourly NO2 from ~219 stations via KCL API (`api.erg.ic.ac.uk`). Aggregate to monthly means.
2. **Station metadata:** Latitude, longitude, site type (roadside/background/industrial), borough.
3. **ULEZ boundary:** Classify stations as inside/outside the North/South Circular using coordinates.

## Fetch Strategy

1. Query LAQN API for site metadata (all London stations with NO2).
2. For each station, fetch hourly NO2 from 2018-01-01 to 2023-08-28.
3. Aggregate to station-month means (require ≥75% hourly coverage per month).
4. Classify stations as inner/outer London using boundary coordinates.
