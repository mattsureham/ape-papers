# Research Plan: Sovereign Stigma and the Price of Sending Money Home

## Research Question

Does FATF grey-listing raise remittance costs for diaspora families? If so, by how much, and does the stigma persist after delisting?

The FATF grey list ("Jurisdictions under Increased Monitoring") publicly identifies countries with anti-money-laundering deficiencies. Listing triggers enhanced due diligence from global correspondent banks, leading to "de-risking" — withdrawal of banking relationships from perceived high-risk jurisdictions. If this raises the cost of sending remittances, grey-listing imposes a regressive tax on some of the world's poorest families, who depend on diaspora transfers for consumption, education, and healthcare.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD** at the corridor-quarter level.

- **Treatment:** Binary indicator for whether the *receiving* country is on the FATF grey list in quarter $t$. Onset date = plenary announcement (February, June, or October).
- **Cohorts:** 70+ unique entry cohorts (2011–2025). Countries enter and exit at different plenaries, creating rich staggered variation.
- **Controls:** Never-listed and not-yet-listed countries serve as comparison group.
- **Clustering:** Two-way at the corridor and receiving-country level.

**Key identification assumption:** Conditional on corridor and time fixed effects, remittance cost trends in grey-listed corridors would have evolved parallel to non-listed corridors absent the listing. Supported by:
1. Event study showing flat pre-trends in the 8 quarters before listing
2. Plenary timing driven by FATF mutual evaluation cycle, not recipient-country economic conditions
3. Placebo tests using *sending*-country listing (should not affect costs in the same way)

## Expected Effects and Mechanisms

**Primary hypothesis:** Grey-listing raises corridor-level remittance costs by 0.3–1.5 percentage points (on a base of ~7% average cost), driven by:
1. **Correspondent banking withdrawal:** Global banks exit relationships with banks in grey-listed countries → fewer remittance service providers → reduced competition → higher markups
2. **Compliance cost pass-through:** Remaining providers face higher due diligence costs → passed to consumers
3. **Channel substitution:** Formal transfer volumes decline, informal (hawala) channels absorb some flows

**Entry vs. exit asymmetry:** If de-risking involves sunk relationship costs, effects should persist after delisting — the "sovereign stigma" hypothesis. Banks that exited during grey-listing may not return, creating hysteresis.

## Primary Specification

$$Y_{ijt} = \alpha_i + \gamma_t + \sum_g \sum_\ell \theta_{g\ell} \cdot \mathbf{1}[G_j = g] \cdot \mathbf{1}[t - g = \ell] + X_{jt}'\beta + \varepsilon_{ijt}$$

Where $i$ indexes corridor (or corridor-firm), $j$ indexes receiving country, $t$ indexes quarter, $g$ is the cohort (grey-list entry quarter), and $\ell$ is event time.

Implemented via `did` package in R (Callaway and Sant'Anna 2021).

## Data Sources

1. **World Bank Remittance Prices Worldwide (RPW):** Corridor-firm-quarter panel, 377 corridors, 48 sending × 111 receiving countries, 2011Q1–2025Q1. ~250K observations. Variables: total cost (%), exchange rate margin, speed, type (bank, MTO, mobile).
   - Source: https://remittanceprices.worldbank.org/resources

2. **FATF Grey List History:** Scraped from FATF website and academic compilations. Country × plenary date × status (listed/delisted). ~114 countries ever listed.
   - Source: https://www.fatf-gafi.org/en/topics/high-risk-and-other-monitored-jurisdictions.html

3. **BIS Locational Banking Statistics (robustness):** Quarterly cross-border banking claims by counterparty country. 2.8M observations.
   - Source: https://www.bis.org/statistics/bankstats.htm

4. **World Development Indicators (robustness):** Annual remittance volume (% of GDP) via WDI API.

## Analysis Plan

### Scripts
- `00_packages.R` — Load libraries (did, fixest, data.table, ggplot2, readxl, jsonlite)
- `01_fetch_data.R` — Download RPW, construct FATF treatment panel, fetch BIS/WDI
- `02_clean_data.R` — Merge corridor-quarter panel with FATF treatment, construct variables
- `03_main_analysis.R` — CS-DiD estimation, event studies, aggregate ATT
- `04_robustness.R` — Sending-country placebo, BIS banking claims, permutation inference, exit asymmetry
- `05_tables.R` — Generate all tables including SDE appendix

### Key Robustness Checks
1. **Sending-country placebo:** If the *sending* country is grey-listed, should it affect remittance cost to a non-listed receiver? (Expects null or small effect)
2. **Entry vs. exit asymmetry:** Separate CS-DiD for entry and exit episodes
3. **Provider composition:** Does the number of providers in the corridor decline after listing?
4. **Channel heterogeneity:** Banks vs. MTOs vs. mobile money — which channel sees largest cost increase?
5. **Pre-trends:** Event study with 8+ pre-treatment quarters
6. **Wild cluster bootstrap:** Inference robust to few clusters

## Exposure Alignment

The treatment (FATF grey-listing) is assigned at the receiving-country level. The outcome (remittance cost) is measured at the corridor-firm level and aggregated to corridor-quarter. The exposure mapping is direct: grey-listing of the receiving country triggers enhanced due diligence for all financial institutions transacting with that country, affecting all remittance corridors terminating there. The unit of observation (corridor) nests within the treatment unit (receiving country), so exposure is complete and well-defined. There is no partial exposure or geographic spillover concern: a corridor either has a grey-listed destination or it does not.

## Angle Avoidance
No APEP paper has studied FATF grey-listing, remittance costs, or international financial intermediation. This is a novel policy domain for the project.
