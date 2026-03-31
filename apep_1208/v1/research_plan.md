# Research Plan: The Sovereign Haircut and the Credit Desert

## Research Question
Does domestic sovereign debt restructuring cause a collapse in private sector credit? Specifically, did Ghana's December 2022 Domestic Debt Exchange Programme (DDEP) — which forced 22 universal banks to exchange GHS 137 billion in government bonds at a ~30% NPV haircut — cause the observed 29% decline in domestic credit to the private sector?

## Identification Strategy

### Primary: Synthetic Control Method (SCM)
- **Treated unit:** Ghana (country-level)
- **Donor pool:** 15 Sub-Saharan African comparators without concurrent sovereign restructuring
- **Outcome:** Domestic credit to private sector (% GDP), World Bank WDI indicator FD.AST.PRVT.GD.ZS
- **Pre-treatment period:** 2010–2022 (13 years)
- **Post-treatment:** 2023–2024
- **Matching predictors:** GDP growth, inflation, trade openness, government debt/GDP, banking sector depth, financial development indicators
- **Inference:** Placebo-in-space tests (iterative reassignment to each donor), RMSPE ratios, exact p-values

### Secondary: Cross-Country Difference-in-Differences
- **Treatment:** Ghana (binary)
- **Control group:** SSA countries without sovereign restructuring in 2022–2024
- **Specification:** Y_{ct} = α_c + δ_t + β(Ghana_c × Post2022_t) + X_{ct}γ + ε_{ct}
- **Clustering:** Country-level (wild cluster bootstrap for small N)

### Mechanism Tests
1. **NPL channel:** Did non-performing loans spike? (WDI indicator FB.AST.NPER.ZS)
2. **Bank profitability:** ROA/ROE collapse as mechanism (WDI banking indicators)
3. **Substitution test:** Did foreign-owned banks or non-bank financial institutions fill the gap?

## Expected Effects
- **Primary:** Large negative effect on private credit/GDP (SDE > 0.15 in magnitude)
- **NPLs:** Sharp increase in non-performing loan ratios
- **Bank profitability:** Collapse in return on assets
- The effect should be concentrated in 2023 (year of exchange) with possible persistence

## Primary Specification
Using Abadie, Diamond, and Hainmueller (2010, 2015) SCM:
- Minimize pre-treatment MSPE for credit/GDP
- Weight constraints: non-negative, sum to 1
- Report gaps (Ghana minus synthetic Ghana) and placebo distributions

## Data Sources
1. **World Bank WDI API** (primary): FD.AST.PRVT.GD.ZS (credit/GDP), FB.AST.NPER.ZS (NPLs), NY.GDP.MKTP.KD.ZG (GDP growth), FP.CPI.TOTL.ZG (inflation), NE.TRD.GNFS.ZS (trade), GC.DOD.TOTL.GD.ZS (govt debt)
2. **IMF IFS** (robustness): Claims on private sector
3. **Bank of Ghana Statistical Bulletin** (mechanism): Bank-level data if accessible

## Donor Pool (15 SSA countries)
Nigeria, Kenya, South Africa, Côte d'Ivoire, Senegal, Tanzania, Uganda, Rwanda, Botswana, Mauritius, Namibia, Cameroon, Ethiopia, Mozambique, Madagascar

Selection criteria: (1) No concurrent sovereign restructuring, (2) Functioning banking sector, (3) WDI data availability 2010–2024.

## Key Risks
- **Small N:** Country-level SCM is N=1 treated unit; inference relies on placebo tests
- **Concurrent shocks:** COVID recovery, global rate tightening may affect all SSA countries (but identification is relative)
- **Data recency:** 2024 WDI data may not yet be available (2023 should be)
