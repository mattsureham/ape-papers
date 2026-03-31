# Research Plan: The Extractability Trap — Anti-Corruption Enforcement and the Composition of Local Public Spending in China

## Research Question

Does anti-corruption enforcement shift local government spending away from extractable infrastructure toward harder-to-corrupt education and health expenditures? We test the Mauro (1998) hypothesis that corruption systematically distorts fiscal allocation using China's 2012 CCDI campaign as a natural experiment.

## Identification Strategy

**Staggered Difference-in-Differences** exploiting prefecture-level variation in the timing of the first CCDI investigation (2013–2017). Prefectures investigated in later rounds serve as not-yet-treated controls for those investigated earlier.

- **Estimator:** Callaway and Sant'Anna (2021) — handles heterogeneous treatment timing, avoids TWFE bias
- **Event study:** Dynamic treatment effects with 5 pre-treatment leads and available post-treatment lags
- **Clustering:** Prefecture level (the unit of treatment variation)
- **Pre-trends:** Test parallel trends in pre-period (2007–2012)

## Expected Effects and Mechanisms

**Primary hypothesis:** Anti-corruption enforcement increases the share of local spending on education and health relative to infrastructure/capital construction.

**Mechanism (the "extractability trap"):** Infrastructure spending offers higher rent-extraction opportunities through procurement kickbacks, land transactions, and construction contracts. Corrupt officials steer budgets toward extractable categories. Enforcement removes corrupt officials and deters extractive behavior, shifting spending toward education and health where rent extraction is harder.

**Expected direction:** Positive effect on education/health share, negative on infrastructure share. Effect may be larger in prefectures with more investigations (dose-response) and in prefectures with historically higher infrastructure shares.

## Primary Specification

Y_{it} = education_health_share of total fiscal expenditure for prefecture i in year t
Treatment: binary indicator for post-first-investigation, with staggered timing
Controls: prefecture FE, year FE (absorbed by CS estimator)
Sample: ~286 prefecture-level cities, 2007–2019

## Data Sources

1. **Treatment (anti-corruption investigations):** Wang (2020) China Corruption Investigations Dataset, Harvard Dataverse (doi:10.7910/DVN/9QZRAD). Records ~20,000 investigated officials with prefecture/county identifiers and year.

2. **Outcomes (fiscal spending composition):** China City Statistical Yearbook / Finance Statistics of Prefectures, via NBS or digitized datasets. Per-capita expenditures by function: education, health, infrastructure/capital construction. Backup: World Bank/CEIC prefecture-level fiscal data.

3. **Controls:** Prefecture GDP, population, urbanization rate from China Statistical Yearbook.

## Robustness

- Callaway-Sant'Anna with never-treated vs. not-yet-treated as control group
- Event study plots for pre-trends
- Bacon decomposition of TWFE for transparency
- Leave-one-province-out to check sensitivity
- Placebo outcomes: defense/public safety spending (should not shift)
- Dose-response: number of investigated officials per prefecture
