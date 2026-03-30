# Research Plan: Contagious NIMBYism — Social Network Diffusion of Anti-Wind Ordinances

## Research Question
Do anti-wind energy ordinances spread through social networks rather than direct geographic proximity? Counties with no wind turbines of their own are adopting restrictive ordinances — suggesting the opposition diffuses through non-local channels. This paper tests whether socially connected counties (via Facebook SCI) that experience wind turbine installations transmit anti-wind sentiment to counties that have never hosted a turbine.

## Identification Strategy
**Shift-share (Bartik) design** with Callaway-Sant'Anna estimator.

**Exposure construction:** For each county c at time t:
```
Exposure_ct = Σ_j [SCI_cj / Σ_k SCI_ck] × ΔTurbines_jt
```
where SCI_cj is the pre-determined Facebook Social Connectedness Index between counties c and j, and ΔTurbines_jt is the change in turbine count in county j by year t.

**Key identification test:** SCI-weighted exposure predicts ordinance adoption *beyond* geographic distance. The horse race between social and spatial exposure is the paper's central empirical contribution.

**Parallel trends:** Event study around first SCI-weighted turbine exposure shock. Pre-trends should be flat for counties with high network exposure but zero local turbines.

**Inference:** AKM standard errors (Adão, Kolesár, Morales 2019) for shift-share designs; wild cluster bootstrap as robustness.

## Expected Effects and Mechanisms
- **Main hypothesis:** Higher SCI-weighted turbine exposure → higher probability of adopting anti-wind ordinances, even for counties with zero local turbines.
- **Mechanism:** Information/attitude diffusion through social networks — learning about noise, property value concerns, visual impacts from socially connected areas rather than direct experience.
- **Heterogeneity:** Effect should be strongest for (a) rural counties without prior industrial development experience, (b) politically conservative counties, (c) counties with higher social media penetration.

## Primary Specification
Binary outcome: county c adopts a restrictive wind ordinance by year t.
Linear probability model with county FE, year FE:
```
Ordinance_ct = β₁ × SCI_Exposure_ct + β₂ × Geo_Exposure_ct + X_ct'γ + α_c + δ_t + ε_ct
```
where Geo_Exposure = distance-weighted turbine exposure (control for spatial spillover).

## Data Sources
1. **USGS Wind Turbine Database v8.2** — 75,417 turbines, county-level, CSV (13.5 MB)
2. **NREL Wind Energy Ordinance Database** — 1,833 ordinances across 423 counties
3. **Columbia/Sabin Opposition Report** — 459 counties with severe restrictions (monthly updates)
4. **Facebook SCI** — County-county social connectedness pairs (Azure: `raw/sci/v2026/us_counties.zip`, 59 MB)
5. **ACS/Census** — County demographics for controls (population, income, political lean, rural/urban)

## Fetch Strategy
1. Download USGS turbine CSV from data.gov
2. Download/scrape NREL ordinance database
3. Download Columbia/Sabin opposition tracker
4. Load SCI from Azure blob storage
5. ACS county-level controls from Census API or tidycensus

## Key Risks
- Ordinance timing data may be imprecise (year only, not month)
- SCI data is a single cross-section (2020) — assume network structure is stable
- Need to handle counties that adopt ordinances before any turbine exposure (anticipatory adoption)
