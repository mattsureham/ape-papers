# Research Plan: Training the Healers

## Research Question

Did the geographic intensity of the opioid prescription boom (2006-2012) drive subsequent growth in substance abuse counselor credential production at local higher education institutions? This paper links 178M DEA ARCOS pill-shipment transactions to IPEDS completion records to provide first evidence on crisis-induced workforce investment in the behavioral health pipeline.

## Identification Strategy

**Cross-sectional long differences with instrumental variable.**

Primary specification: county-level long difference (2018-2021 vs. 2006-2009) in IPEDS substance abuse counseling completions (CIP 51.15xx) regressed on ARCOS pills-per-capita during the prescription boom (2006-2012).

$$\Delta Y_c = \alpha + \beta \cdot \text{ARCOS\_pills\_pc}_c + X_c' \delta + \epsilon_c$$

where $\Delta Y_c$ is the change in substance abuse counseling completions in county $c$.

**Instrument:** Triplicate-prescription-state indicator (Alpert et al. 2022 QJE). States requiring triplicate prescriptions in the early 2000s (California, Idaho, Illinois, Indiana, New York, Texas) had systematically lower OxyContin penetration, providing plausibly exogenous variation in local opioid supply intensity.

## Expected Effects and Mechanisms

- **Demand channel:** Counties with higher opioid supply experienced more substance abuse crises, creating labor market demand for counselors.
- **Institutional response:** Local colleges and universities responded by creating or expanding substance abuse counseling programs.
- **Positive $\beta$:** More pills during the boom → more SA counselor credentials produced later (a "demand-induced credential pipeline").

## Data Sources

1. **ARCOS** (Azure: `az://raw/arcos/arcos_transactions.parquet`): 178.6M pill shipment records, aggregated to county-level pills per capita (2006-2012). 3,089 counties.

2. **IPEDS** (Azure: `az://raw/ipeds/ipeds.duckdb`): Institution-level completions by CIP code. Filter to CIP 51.15xx (Substance Abuse/Addiction Counseling). 842 institutions across 651 counties. Annual, 2000-2024.

3. **Controls:** County population (Census), median income, urban/rural (RUCC), baseline education levels, pre-existing healthcare employment (QWI), pre-trend SA completions (2000-2005).

## Placebo Outcomes

- Engineering completions (CIP 14.xxxx) — should not respond to opioid supply
- Business completions (CIP 52.xxxx) — should not respond
- Pre-2006 SA completion trends — no "anticipation"

## Robustness

- IV with triplicate-state instrument
- Donut specifications excluding 2012-2014 transition years
- State fixed effects to control for state-level policies
- Alternative ARCOS measures (pills per capita, morphine-milligram equivalents)
- Weighted and unweighted regressions
- Leave-one-state-out sensitivity
- Conley spatial HAC standard errors
