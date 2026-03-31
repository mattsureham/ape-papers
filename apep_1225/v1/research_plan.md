# Research Plan: Relaxed and Searching — Section 60 Stop-and-Search Relaxation and Knife Crime in England

## Research Question

Did the April 2019 relaxation of Section 60 stop-and-search authorization powers reduce knife crime, or did it merely displace it to neighboring police force areas?

## Policy Background

On 31 March 2019, the Home Secretary announced a pilot relaxation of Section 60 Criminal Justice and Public Order Act 1994 powers in 7 police forces: Metropolitan Police, West Midlands, Greater Manchester, Merseyside, South Yorkshire, South Wales, and West Yorkshire. The relaxation lowered the authorization rank from chief officer to inspector, reduced the certainty threshold from "will" to "may" occur, and extended the maximum duration. In August 2019, the pilot was extended to all 43 territorial police forces in England and Wales plus British Transport Police.

This is the most politically contested question in British policing. Stop-and-search disproportionately affects Black and ethnic minority communities, yet proponents argue it deters knife carrying. The key empirical question is not just whether S60 relaxation affects knife crime levels, but whether any local deterrence effect is offset by spatial displacement to neighboring jurisdictions.

## Identification Strategy

**Two-cohort staggered difference-in-differences:**
- Cohort 1 (April 2019): 7 pilot forces
- Cohort 2 (August 2019): Remaining 36 forces
- Pre-period: January 2017 – March 2019 (27 months)
- Clean post-period: April 2019 – February 2020 (11 months for Cohort 1, 7 for Cohort 2, before COVID lockdowns)

**Estimator:** Callaway and Sant'Anna (2021) group-time ATT, robust to staggered treatment timing and treatment effect heterogeneity.

**Spatial displacement test:** Using police force contiguity matrix, test whether knife crime in forces neighboring Cohort 1 forces increased during the April–July 2019 window (when only 7 forces had relaxed powers and the remaining 36 had not).

## Expected Effects

1. **S60 stops increase:** Relaxation should mechanically increase S60-authorized stops (first stage)
2. **Knife crime effect (ambiguous):** Could decrease (deterrence) or show no effect (if S60 was already used at discretion)
3. **Spatial displacement:** If deterrence works, knife crime may shift to neighboring non-pilot forces during April–July 2019

## Primary Specification

$$Y_{ft} = \alpha_f + \gamma_t + \beta \cdot \text{Treated}_{ft} + \epsilon_{ft}$$

Where $Y_{ft}$ is knife crime rate per 1,000 population in force $f$ at month $t$. Callaway-Sant'Anna ATT estimates $\beta$ for each group-time cell.

**Clustering:** Force level (43 clusters). Wild cluster bootstrap for robustness given moderate cluster count.

## Data Sources

1. **police.uk bulk archives** — Monthly street-level crime data by force area (2017–2020). Variables: crime type (includes "Possession of weapons", "Violence and sexual offences"), location (LSOA), month.
2. **police.uk stop-and-search data** — Monthly stop-and-search records with legislation used (S1 PACE vs S60 CJPO), object of search, outcome, self-defined ethnicity.
3. **ONS mid-year population estimates** — Force-area population denominators for rate construction.
4. **Force contiguity matrix** — Constructed from geographic boundaries for spatial displacement test.

## Fetch Strategy

1. Download police.uk bulk archive ZIP files for Jan 2017 – Feb 2020 (38 months)
2. Parse CSV files, aggregate to force-month level
3. Filter crime types: "Possession of weapons" (primary), "Violence and sexual offences" (secondary)
4. Download stop-and-search data to verify first stage (S60 stops increase post-relaxation)
5. Merge with ONS population estimates for rate construction

## Robustness Checks

1. Event study plots (leads/lags) for parallel trends validation
2. Wild cluster bootstrap p-values
3. Placebo outcomes: bicycle theft, shoplifting (should not respond to S60 relaxation)
4. Leave-one-out: drop each Cohort 1 force in turn
5. COVID sensitivity: vary post-period endpoint (Dec 2019, Jan 2020, Feb 2020)
