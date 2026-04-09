# Research Plan: The Formula Floor — Indonesia's PP78/2015 Wage Reform and Formal Employment

## Research Question

Did Indonesia's 2015 formula-based minimum wage reform (PP78/2015) — which replaced discretionary district-level wage negotiations with a binding national formula — increase or decrease formal employment in provinces where the formula imposed a larger upward wage shock?

## Policy Background

Government Regulation No. 78/2015, effective January 2016, replaced annual wage council negotiations with a mechanical formula: new minimum wage = prior minimum wage × (1 + national CPI inflation + national GDP growth). This removed local discretion. Provinces where the formula wage exceeded the prior negotiated minimum experienced a binding upward shock; provinces where the local negotiated wage already exceeded or matched the formula were effectively unaffected.

## Identification Strategy

**Design:** Continuous difference-in-differences using province-level variation in the "Kaitz ratio" — the gap between the PP78 formula wage and the pre-reform negotiated minimum wage, normalized by the prior wage. Provinces with higher Kaitz ratios experienced larger binding shocks.

**Treatment intensity:** Kaitz_p = (FormulaWage2016_p - NegotiatedWage2015_p) / NegotiatedWage2015_p

**Key assumption:** Parallel trends in employment outcomes across high-Kaitz and low-Kaitz provinces, conditional on province and year fixed effects. Plausible because the formula used *national* CPI and GDP — the only source of cross-province variation is the pre-reform negotiated wage level, which was set before PP78 was announced.

**Pre-treatment:** 2011-2015 (5 years). **Post-treatment:** 2016-2019 (before PP36/2021 superseded PP78).

**Unit of analysis:** 34 provinces × 9 years = 306 province-year observations.

## Expected Effects and Mechanisms

- **Formal employment:** Ambiguous. Standard competitive model predicts decline; monopsony/efficiency wage models predict potential increase. Indonesia's ~50% informal sector creates a margin for informalization.
- **Wage compression:** Formula should compress cross-province wage distribution.
- **Informal sector:** High-Kaitz provinces may see shifts from formal to informal employment.
- **Gender:** Women and young workers disproportionately affected (existing literature).

## Primary Specification

Y_{pt} = α + β(Kaitz_p × Post_t) + γ_p + δ_t + X_{pt}'θ + ε_{pt}

Where:
- Y_{pt}: formal employment rate, unemployment rate, labor force participation, average wage
- Kaitz_p: pre-reform wage gap intensity (time-invariant)
- Post_t: indicator for 2016-2019
- γ_p, δ_t: province and year fixed effects
- X_{pt}: time-varying controls (GDP per capita, population)
- Clustering at province level (34 clusters — will use wild cluster bootstrap)

Event study: Y_{pt} = α + Σ_k β_k(Kaitz_p × 1{t=k}) + γ_p + δ_t + ε_{pt}

## Data Sources

1. **Minimum wages by province:** BPS published tables + World Bank DAPOER. Annual district/province minimum wages available 2011-2019.
2. **Employment outcomes:** World Bank Development Indicators (national) + ILO STAT (province-level where available) + BPS statistical yearbook aggregates.
3. **Province-level controls:** World Bank subnational indicators, BPS GDP by province.

## Data Fetch Strategy

1. World Bank API for Indonesia employment indicators (national + subnational where available)
2. Construct province-level Kaitz indices from published BPS minimum wage data
3. ILO STAT API for Indonesia labor market data
4. BPS open data portal for province-level employment and GDP

## Robustness

- Binary treatment (above/below median Kaitz) instead of continuous
- Event study for parallel pre-trends
- Wild cluster bootstrap for inference with 34 clusters
- Excluding Java/Bali (most urbanized) to test rural sensitivity
- Triple-difference: manufacturing vs. services sectors (manufacturing more exposed to minimum wage binding)
