# Research Plan: The Extortion Tax on Entrepreneurship

## Research Question
What is the economic cost of systematic gang extortion, and does removing it unlock local economic activity? El Salvador's March 2022 estado de excepción arrested 80,000+ gang members, dismantling extortion networks that taxed ~70% of businesses. This provides a rare natural experiment in near-complete organized crime removal.

## Identification Strategy
**Continuous-intensity difference-in-differences.** All 262 Salvadoran municipalities experienced the crackdown simultaneously (March 2022), but treatment intensity varies with pre-crackdown gang violence — municipalities with more gang activity had more extortion to remove.

**Specification:**
Y_{mt} = α_m + γ_t + β × Violence_m × Post_t + ε_{mt}

Where:
- Y_{mt}: mean monthly nighttime radiance (VIIRS VNP46A4) for municipality m in month t
- α_m: municipality fixed effects
- γ_t: month-year fixed effects
- Violence_m: pre-crackdown (2018-2021) ACLED fatality rate per 100K population
- Post_t: indicator for April 2022 onward

**Event study version:** Replace Post_t with month-relative-to-crackdown dummies to test pre-trends.

## Expected Effects and Mechanisms
1. **Direct channel:** Extortion removal reduces business costs → more entry, less exit → higher nighttime economic activity
2. **Security channel:** Reduced violence → higher foot traffic, later business hours → more nightlight
3. **Investment channel:** Reduced uncertainty → capital investment → structural economic growth

We expect β > 0: municipalities with higher pre-crackdown violence show larger nightlight increases post-crackdown.

## Primary Specification
- Unit: municipality-month (262 × ~130 months ≈ 34,000 obs)
- Treatment intensity: ACLED fatalities per 100K (2018-2021 average)
- Outcome: log(mean nighttime radiance + 1) from VIIRS VNP46A4
- Fixed effects: municipality + year-month
- Clustering: municipality level
- Pre-period: January 2014 – March 2022 (99 months)
- Post-period: April 2022 – latest available (~35 months)

## Robustness
1. Placebo cutoffs: July 2019, January 2020 (pre-COVID), January 2021
2. Alternative intensity measures: ACLED event counts (not just fatalities), homicide rates
3. Leave-one-out: drop San Salvador (capital, potential outlier)
4. Conley spatial SEs (50km cutoff)
5. Alternative outcomes: total radiance (not mean), lit-area fraction

## Data Sources
1. **ACLED** (Armed Conflict Location & Event Data): Event-level conflict data for El Salvador, 2018-2025. API access confirmed (ACLED_API_KEY in .env). Provides geocoded violence events with fatality counts for treatment intensity construction.
2. **VIIRS VNP46A4** (NASA Black Marble): Monthly nighttime radiance composites at ~500m resolution, 2012-present. Access via NASA LAADS DAAC (NASA_EARTH token in .env) or direct download. R package `blackmarbler` for extraction.
3. **GADM**: Administrative boundaries for El Salvador's 262 municipalities. Free download, no credentials needed.
4. **World Bank WDI**: Population data for rate construction (SP.POP.TOTL).

## Fetch Strategy
1. Download GADM Level 2 boundaries for El Salvador (municipalities)
2. Query ACLED API for all El Salvador events 2018-2025
3. Spatial join ACLED events to municipalities, compute pre-crackdown violence rates
4. Download VIIRS VNP46A4 monthly composites 2014-2025 for El Salvador extent
5. Zonal statistics: mean nighttime radiance per municipality-month
6. Merge all into municipality-month panel
