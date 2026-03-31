# Research Plan: apep_1207

## Research Question
How does the abrupt withdrawal of a large agricultural subsidy affect farm structure, agricultural production, and rural welfare? Specifically, what happened to Thai provinces more dependent on rice cultivation after the rice pledging scheme's fiscal collapse in late 2013?

## Background
Thailand's rice pledging scheme (2011–2014) offered farmers 15,000 baht/ton for white rice and 20,000 baht/ton for jasmine rice — roughly 40–50% above market prices. Cumulative expenditure reached 858 billion baht. In late 2013, the Bank for Agriculture and Agricultural Cooperatives (BAAC) refused further financing. Over 150,000 farmers went unpaid; many turned to informal lenders at usurious rates. Nine farmer suicides were documented. The May 2014 military coup formally terminated the scheme.

## Identification Strategy
**Continuous-treatment difference-in-differences.** Treatment intensity = province-level rice cultivation share (rice area / total agricultural area) measured in 2010, before the scheme's reintroduction. Provinces with higher rice dependence were more exposed to the scheme's collapse.

- **Pre-period:** 2006–2012 (scheme operating 2011–2012, normal conditions 2006–2010)
- **Post-period:** 2014–2020 (scheme collapsed)
- **Treatment onset:** Late 2013 (BAAC default)
- **Unit:** 77 provinces
- **Estimator:** TWFE with province and year fixed effects; event study with year-by-year interactions of rice intensity; Callaway-Sant'Anna for robustness using tercile-based binary treatment

Key threats: world rice prices moved during this period. Control for global rice price × province crop diversification. Also control for the 2011 floods (which differentially hit central provinces).

## Expected Effects and Mechanisms
1. **Production decline:** Provinces more dependent on rice should see sharper declines in agricultural output (cereal production, agriculture value added)
2. **Structural transformation:** Farmers exit rice → diversify into other crops or leave agriculture entirely. Labor reallocation toward non-farm sectors
3. **Rural welfare:** Poverty effects ambiguous — subsidy withdrawal hurts income, but structural adjustment may improve long-run productivity
4. **The "subsidy withdrawal trap":** When governments promise above-market prices, farmers over-invest in the subsidized crop. When the subsidy collapses, they're left with crop-specific capital and debt but no market at the promised price.

## Primary Specification
Y_{pt} = α + β(RiceShare_p × Post_t) + γ_p + δ_t + X_{pt}'θ + ε_{pt}

Where:
- Y_{pt} = outcome (cereal production, agriculture VA share, poverty rate) for province p in year t
- RiceShare_p = rice cultivation intensity in 2010 (continuous, 0–1)
- Post_t = 1 if t ≥ 2014
- γ_p = province fixed effects
- δ_t = year fixed effects
- X_{pt} = time-varying controls (world rice price × crop diversification, flood exposure)

Cluster standard errors at province level (77 clusters).

## Data Sources
1. **World Bank API** (primary): Cereal production (AG.PRD.CREL.MT), agriculture VA % GDP (NV.AGR.TOTL.ZS), poverty headcount (SI.POV.NAHC), rural population share
2. **FAO FAOSTAT**: Thailand rice production by year, rice area harvested
3. **Bank of Thailand (BOT)**: Province-level economic indicators, agricultural credit
4. **NESDC**: Gross Provincial Product by sector for 77 provinces (if downloadable)
5. **World Bank Pink Sheet**: Global rice prices for controls

## Feasibility Assessment
- World Bank country-level data: confirmed via smoke test
- Province-level GPP from NESDC: needs verification (may require manual download)
- Fallback: Use national-level World Bank data with synthetic province variation from FAO rice area data
- 77 provinces provides adequate clustering

## Risk Mitigation
- If province-level data unavailable: pivot to national time-series with regional agricultural data from FAO
- If pre-trends fail: explore triple-difference with crop diversification as additional margin
- If effects are null: report as evidence that agricultural markets adjust efficiently to subsidy withdrawal
