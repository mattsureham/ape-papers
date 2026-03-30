# Research Plan: Middlemen and the Opioid Flood

## Research Question

Did pharmaceutical distributor market concentration amplify county-level opioid pill supply during 2006–2012? The opioid economics literature (Alpert et al. 2022 QJE; Ruhm 2019; Evans et al. 2019) treats pill supply as a county-level aggregate. Nobody has opened the supply chain to examine whether distributor market structure mattered. This paper is the first to use transaction-level ARCOS data to measure distributor HHI at the county level and instrument for it using national merger waves.

## Mechanism: "The Middleman Premium"

When a few wholesalers dominate a county's supply chain, pharmacies face fewer options and weaker countervailing buyer power. Concentrated distributors may push higher volumes (revenue maximization) with less scrutiny (fewer compliance investments per dollar). National merger waves (McKesson-D&K 2006, Cardinal-Kinray 2010, AmerisourceBergen regional consolidation 2007-2011) reshuffled local market shares exogenously from county-level drug demand.

## Identification Strategy

**Shift-share / Bartik IV.**

- **Shares**: Pre-period (2006) county-level distributor market composition (share of pills from each distributor family)
- **Shifts**: National-level changes in distributor market shares driven by merger events
- **First stage**: Merger-predicted HHI change → Actual HHI change
- **Second stage**: Instrumented HHI → Pills per capita
- **Reduced form**: Merger-predicted HHI → Overdose deaths (if data permits)

**Exclusion story**: Pre-merger distributor territory allocation was driven by logistics networks, warehouse locations, and long-term contracts — not by county-level drug appetite. National merger decisions were corporate-level events responding to wholesale market competition, not to local opioid demand conditions.

**Key threats**: (1) Mergers correlated with pre-existing supply trends — addressed with pre-trend tests. (2) Shares correlated with county characteristics — addressed with balance tests and controls. (3) Concentrated markets differ in other ways — addressed with Rotemberg weight decomposition and shock-level balance.

## Expected Effects

- **First stage**: Higher merger-predicted HHI → higher actual HHI (positive, strong)
- **Second stage**: Higher HHI → more pills per capita (positive — the middleman premium)
- **Reduced form**: Higher predicted HHI → higher overdose mortality (positive but noisier)
- **Mechanism**: Volume channel (more pills shipped), not price channel

## Primary Specification

```
Pills_per_capita_{ct} = β × HHI_{ct} + X_{ct}γ + α_c + δ_t + ε_{ct}

First stage: HHI_{ct} = π × B_{ct} + X_{ct}φ + α_c + δ_t + u_{ct}

Where B_{ct} = Σ_d share_{d,c,2006} × ΔNationalShare_{d,t}
```

- County and year fixed effects
- Controls: population, median income, healthcare providers per capita
- Clustering at state level (shift-share inference: AKM-corrected SEs)

## Data Sources

1. **DEA ARCOS** (Azure: `raw/arcos/arcos_transactions.parquet`): 178M transactions, 2006-2012. Variables: Reporter_family (distributor), BUYER_STATE/BUYER_COUNTY, DOSAGE_UNIT, DRUG_NAME
2. **CDC WONDER**: County-level overdose death rates (age-adjusted)
3. **ACS / Census**: County population, demographics, income (controls)

## Analysis Pipeline

1. `01_fetch_data.R` — Load ARCOS from Azure via DuckDB, fetch CDC WONDER and ACS
2. `02_clean_data.R` — Construct county-year panel: HHI, pills per capita, distributor shares, merge outcomes
3. `03_main_analysis.R` — OLS, first stage, reduced form, 2SLS with shift-share IV
4. `04_robustness.R` — Rotemberg weights, AKM SEs, leave-one-out, placebo drugs, pre-trend balance
5. `05_tables.R` — All tables including SDE appendix

## Key Risks

- CDC WONDER suppresses cells with <10 deaths — may limit county-level mortality analysis
- ARCOS data ends 2012 — pre-fentanyl era only (can frame as feature: isolates prescription channel)
- Distributor mergers cluster in time — need sufficient pre/post variation
