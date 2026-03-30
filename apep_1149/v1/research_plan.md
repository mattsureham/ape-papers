# Research Plan: The Waterbed Effect — DEA Distributor Enforcement and the Resilience of Opioid Supply Chains

## Research Question
Does DEA enforcement against a major pharmaceutical distributor reduce total county-level opioid pill supply, or does supply reroute through substitute distributors — a "waterbed effect"?

## Policy Context
In November-December 2007, DEA suspended Cardinal Health distribution center licenses in Lakeland FL, Auburn WA, and Swedesboro NJ for failing to report suspicious orders. Cardinal was the third-largest US opioid distributor (10.7 billion pills, 2006-2012). The suspension provides a quasi-experiment: counties heavily dependent on Cardinal experienced a sharp, exogenous supply disruption.

## Identification Strategy
**Event-study DiD with continuous treatment intensity.**

- **Treatment variable:** Pre-enforcement (2006-2007) Cardinal Health market share at the county level (pills from Cardinal / total pills).
- **Treatment timing:** November-December 2007 (Cardinal suspension).
- **Identifying assumption:** Conditional on county fixed effects and year fixed effects, counties with higher pre-enforcement Cardinal share experienced larger supply disruption — and any differential post-2007 outcome changes are attributable to the enforcement action.
- **Key test:** Decompose total county supply by distributor — track Cardinal, McKesson, AmerisourceBergen, Walgreens separately — to document the reallocation channel.

## Expected Effects and Mechanisms
1. **Direct effect:** Cardinal pills should decline sharply in high-Cardinal-share counties after late 2007.
2. **Waterbed hypothesis:** If the supply chain is resilient, competing distributors (McKesson, AmerisourceBergen) absorb displaced demand. Total pills per capita may not decline — or may even increase.
3. **Mechanism:** Pharmacies switch distributors; competing distributors expand territory into Cardinal's former markets.
4. **Downstream:** If total supply is unchanged, enforcement against distributors cannot reduce overdose deaths — policy implication for opioid strategy.

## Primary Specification
```
log(pills_pc)_ct = alpha_c + delta_t + beta * (CardinalShare_c,pre * Post_t) + X_ct'gamma + epsilon_ct
```
Where:
- `pills_pc_ct` = total opioid pills per capita in county c, year t
- `CardinalShare_c,pre` = Cardinal's share of county c's pills in 2006-2007
- `Post_t` = indicator for t >= 2008
- `alpha_c` = county FE, `delta_t` = year FE
- `X_ct` = state-year FE (optional)

Event-study variant: interact `CardinalShare_c,pre` with year indicators (omitting 2007).

## Data Sources
1. **DEA ARCOS transactions** (Azure: `raw/arcos/arcos_transactions.parquet`): 178.6M transaction-level pill shipments, 2006-2012. Distributor ID, buyer county, drug, dosage units.
2. **Census county population** (API): County-level population for per-capita normalization.
3. **CDC WONDER mortality** (if feasible): Overdose deaths by county-year for downstream analysis.

## Analysis Pipeline
1. `01_fetch_data.R` — Load ARCOS from Azure, fetch Census population
2. `02_clean_data.R` — Build county-year-distributor panel, compute Cardinal share, merge population
3. `03_main_analysis.R` — Event-study DiD, decomposition by distributor, total vs. Cardinal vs. substitute
4. `04_robustness.R` — Placebo (non-Cardinal distributors as treatment), state-year FE, donut-hole (drop NJ/FL/WA), alternative bandwidths
5. `05_tables.R` — All tables including SDE appendix
