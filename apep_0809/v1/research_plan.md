# Research Plan: Trading Non-Tradable Votes

## Research Question
Does increased posted worker competition from EU enlargement cause a rise in far-right (Front National / Rassemblement National) voting in French départements?

## Identification Strategy
**Bartik shift-share instrument.**
- **Temporal shocks:** EU enlargement dates — A8 accession (May 2004) and A2 accession (January 2007) massively expanded the pool of posted workers eligible to work in France.
- **Cross-sectional exposure:** Pre-enlargement (2000) département-level employment shares in construction, agriculture, and industry — the sectors that receive the vast majority of posted workers.
- **Instrument:** Predicted posted worker inflows = Σ_s (share_{d,s,2000} × ΔPostedWorkers_{national,s,t})
- **China shock control:** Include département-level exposure to Chinese import competition (Comtrade bilateral trade data) to separate the goods-trade channel from the services-trade channel.

## Expected Effects and Mechanisms
- **Primary:** Increased posted worker exposure → higher FN/RN vote share. The mechanism is labor market competition in non-tradable sectors (construction, agriculture) where native workers cannot relocate to avoid competition.
- **Magnitudes:** Munoz (2024 QJE) finds a 16% reduction in domestic employment from posted workers. If labor market anxiety maps to voting, we'd expect a positive, economically meaningful effect on far-right support.
- **Heterogeneity:** Stronger effects in départements with lower unionization, higher unemployment, and more construction dependence.

## Primary Specification
Y_{d,t} = α + β × PostedWorkerExposure_{d,t} + X'_{d,t}γ + δ_d + μ_t + ε_{d,t}

Where:
- Y = FN/RN vote share (%) in département d, election year t
- PostedWorkerExposure = instrumented posted worker inflows per worker
- X = controls (population, unemployment, GDP per capita, China import shock)
- δ_d = département fixed effects
- μ_t = election year fixed effects
- Clustering: département level

## Data Sources
1. **Posted workers:** DARES/DGT posted worker declarations by département-sector-year (XLSX from travail.gouv.fr)
2. **Elections:** Presidential and European election results at département level from data.gouv.fr
3. **Employment shares:** INSEE CLAP/FLORES (pre-enlargement sectoral employment by département)
4. **Controls:** INSEE BDM (unemployment, population, GDP); Comtrade (bilateral trade for China shock)

## Data Fetch Strategy
1. Download DARES posted worker XLSX (confirmed 107KB, 12 sheets)
2. Fetch election results from data.gouv.fr (Parquet format)
3. Fetch pre-enlargement sectoral employment from INSEE BDM/SDMX
4. Construct China import shock control from UN Comtrade API
5. Merge all at département-year level
