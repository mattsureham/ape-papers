# Research Plan: Paid Family Leave and the Racial Hiring Gap

## Research Question

Does state-level Paid Family Leave (PFL) reduce or widen the Black–white gap in new hiring rates? Two competing mechanisms generate opposite predictions: (1) statistical discrimination — employers expecting PFL-covered workers to take leave may disproportionately avoid hiring Black workers if they perceive differential leave-taking rates; (2) cost-spreading — PFL funded by employee payroll tax removes financial leave costs from individual hiring decisions, potentially reducing discrimination.

## Identification Strategy

**Callaway–Sant'Anna staggered DiD.** Eight US states adopted PFL between 2004 and 2022 (CA 2004, NJ 2009, WA 2012, RI 2014, NY 2018, DC 2020, MA 2021, CT 2022). Never-treated states serve as controls. The outcome is the Black/white ratio of new hires from non-employment (HirA) at the state × industry × quarter level. Pre-trends in this ratio must be flat for treated cohorts relative to never-treated states.

**Key advantage:** 8 treatment cohorts with staggered adoption across 2+ decades, avoiding problems with standard TWFE in heterogeneous-effects settings.

## Expected Effects and Mechanisms

- **If statistical discrimination dominates:** PFL widens the racial hiring gap (negative ATT on Black/white HirA ratio) as employers avoid workers they associate with higher leave-taking.
- **If cost-spreading dominates:** PFL narrows the gap (positive ATT) because the policy socializes leave costs, reducing the marginal cost of hiring any individual worker.
- **Heterogeneity predictions:** Effects should be stronger in industries with higher female share (healthcare) if mechanisms operate through gender-race interactions; effects may differ by benefit generosity and job protection provisions.

## Primary Specification

$$\text{ATT}(g,t) = E[Y_{it}(g) - Y_{it}(\infty) \mid G_i = g]$$

where $Y_{it}$ is the log Black/white HirA ratio, $G_i$ is the adoption cohort for state $i$, and $\infty$ denotes never-treated. Aggregated via CS estimator with not-yet-treated and never-treated as controls.

## Data Sources

1. **QWI Race Microdata:** `az://derived/qwi/rh/ns/*.parquet` — 160M+ cells. State × industry × race × quarter. Variables: HirA (new hires from non-employment), EarnS (earnings), Emp (employment). Race: A1 (white alone), A2 (Black/AA).
2. **PFL adoption dates:** NCSL legislative records, coded from Rossin-Slater et al. (2013) and Dahl et al. (2016).
3. **ACS (IPUMS):** State-level demographic controls (population, industry composition, female labor force share).

## Fetch Strategy

- QWI: DuckDB query against Azure parquet files. Aggregate to state × 2-digit NAICS × race × quarter.
- PFL dates: Hand-code from NCSL (8 states, well-documented).
- ACS: Census API or IPUMS extract for state-year controls.
