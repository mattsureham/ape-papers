# Research Ideas

## Idea 1: Does Eliminating the Housing Tax Capitalize into Property Prices? Evidence from France's Taxe d'Habitation Reform

**Policy:** France eliminated the taxe d'habitation (housing tax) for main residences in a phased reform (2018-2023). The tax raised ~€26 billion annually and varied enormously across communes (rates from <10% to >50% of the cadastral rental value). The reform was universal in timing but created cross-sectional variation in treatment intensity: communes with higher pre-reform rates experienced larger per-household tax savings.

**Outcome:** Property transaction prices from DVF (Demandes de Valeurs Foncières), covering all real estate sales in metropolitan France 2014-2025. ~24 million transactions with price, date, commune code, property type, and surface area.

**Identification:** Continuous-treatment DiD. Treatment intensity = pre-reform commune-level taxe d'habitation rate (from REI files). Specification: log(price/m²) = commune FE + year FE + β(pre_rate × Post2018) + controls. β measures differential price appreciation in high-rate vs low-rate communes after the reform. Pre-trends test: β should be zero for 2014-2017 (parallel trends across rate quartiles).

**Built-in placebos:** (1) Secondary residences kept the taxe d'habitation → communes with high secondary-residence shares should see attenuated effects; (2) Commercial/industrial properties unaffected → no differential price changes; (3) The two-wave phase-in (80% of households in 2018, remaining 20% in 2021) creates within-reform timing variation.

**Why it's novel:** Tax capitalization theory (Oates 1969, Brueckner 1982) predicts ΔP ≈ (1/r) × ΔTax. Despite the taxe d'habitation being the largest housing tax reform in modern French history, no micro-data evaluation using transaction-level DVF data exists. Existing French tax-capitalization studies (Charlot et al. 2015; Bono et al. 2021) examine different taxes or different time periods.

**Feasibility check:** DVF data confirmed available 2014-2025 (cadastre.data.gouv.fr + data.gouv.fr). REI commune tax rates available since 1982 (data.economie.gouv.fr). ~35,000 communes provide massive cross-sectional variation. Pre-period (2014-2017) gives 4 years for parallel trends testing. Post-period (2018-2025) gives 7 years of treatment.


## Idea 2: Does City-Center Revitalization Work? Causal Evidence from France's Action Coeur de Ville Program

**Policy:** In March 2018, France designated 222 medium-sized cities for the Action Coeur de Ville (ACV) program — a €5 billion place-based intervention combining infrastructure investment, housing renovation incentives, commercial revitalization, and heritage preservation. All 222 cities were selected simultaneously based on city-center decline indicators.

**Outcome:** Multi-outcome using DVF (property prices), Sirene (firm creation/destruction), and INSEE BDM (population, employment). Primary: property price per m² in city centers of treated vs control cities.

**Identification:** Two-period DiD with matching. Match the 222 ACV cities to similar non-selected cities using pre-treatment covariates (population, income, vacancy rates, property price levels) via CEM or propensity score. Compare property price trends in treated vs matched control cities, before (2014-2017) vs after (2018-2024) the program. Event-study specification with year-by-treatment interactions.

**Why it's novel:** The Cour des comptes explicitly stated that existing evaluations "do not allow distinguishing between the program's specific role and the effect of deeper societal trends." The ANCT barometer shows treated cities outperformed national trends (transactions declined only 1% vs 14% nationally), but this is not causal. No rigorous micro-data DiD evaluation exists.

**Feasibility check:** City list CSV available on data.gouv.fr (confirmed). DVF + Sirene data available. 222 treated cities well above 20-unit threshold. Selection concern addressable with matching + parallel trends. Risk: selection was non-random (cities chosen for decline), so pre-trends may not hold without careful matching.


## Idea 3: Place-Based Tax Incentives and Rural Firm Creation: Evidence from France's ZRR Reform

**Policy:** France's Zones de Revitalisation Rurale (ZRR) provide tax exemptions for firm creation in designated rural communes. The 2015 reform (effective July 2017) reclassified eligibility at the EPCI level using mechanical criteria: population density ≤ median and median income ≤ median. Hundreds of communes gained or lost ZRR status.

**Outcome:** Firm creation rates from INSEE Sirene (establishment-level data with creation dates, commune codes, activity sectors). Secondary: employment from DADS/DSN aggregate data.

**Identification:** DiD comparing communes that gained ZRR status to those that lost it (or to always-ZRR/never-ZRR communes), before (2014-2016) vs after (2017-2024) the reform. The mechanical EPCI-level criteria provide clean variation: communes near the density/income thresholds experienced quasi-random reclassification.

**Why it's novel:** While place-based policies are well-studied (Busso, Gregory, Kline 2013 for US Empowerment Zones; Briant, Lafourcade, Schmutz 2015 for French ZFU), the 2015 ZRR reform has not been causally evaluated with firm-level micro-data. The EPCI-level reclassification provides cleaner variation than earlier reforms.

**Feasibility check:** ZRR commune list on data.gouv.fr (confirmed). Sirene data available via API (INSEE credentials confirmed). ~500+ communes changed status. Pre/post period well-defined. Risk: EPCI-level treatment means within-EPCI communes are all treated together, potentially reducing effective N.


## Idea 4: Do Renovation Tax Incentives Revitalize Declining Housing Markets? Evidence from the Dispositif Denormandie

**Policy:** Created in 2019, the Dispositif Denormandie provides income tax deductions (12-21% of renovation costs) for purchasing and renovating old housing in designated cities. Initially limited to 222 Action Coeur de Ville cities, eligibility was expanded to all communes with Opération de Revitalisation de Territoire (ORT) conventions. The incentive targets properties older than 15 years requiring renovation ≥25% of total cost.

**Outcome:** Property prices for old housing (pre-1970 construction) from DVF. Secondary: transaction volumes, price gap between old and new housing, and renovation-related firm creation from Sirene.

**Identification:** DiD comparing eligible communes (ACV + ORT) to non-eligible communes with similar characteristics, before (2014-2018) vs after (2019-2024) the Denormandie. Focus specifically on old housing transactions (the treated segment) using new housing as within-commune placebo.

**Why it's novel:** Renovation tax incentives are common globally but rarely evaluated with transaction-level data. The Denormandie is distinct from the well-studied Pinel (which targets new construction) and creates a clean within-commune comparison (old vs new housing). No causal evaluation exists.

**Feasibility check:** Eligible city list overlaps with ACV (222 cities, CSV on data.gouv.fr). ORT communes listed on ANCT. DVF data available. Risk: Denormandie overlaps temporally with ACV, making it hard to isolate the renovation incentive from the broader revitalization program. The within-property-type comparison (old vs new) helps address this.


## Idea 5: The Fiscal Displacement Effect: Do Communes Shift Tax Burden to Property Owners After Housing Tax Elimination?

**Policy:** When the taxe d'habitation was eliminated (2018-2023), communes lost a major revenue source. While the state provided compensation via a transfer of the département's share of taxe foncière, communes retained the ability to set their own taxe foncière rates. Many communes subsequently increased taxe foncière rates, creating a fiscal displacement from occupants to property owners.

**Outcome:** Commune-level taxe foncière rates from REI (2014-2024). Secondary: property prices from DVF (to test whether tax foncière increases offset the capitalization of TH elimination).

**Identification:** DiD exploiting variation in the "fiscal stress" of the reform across communes. Treatment intensity = pre-reform dependence on taxe d'habitation (TH share of total commune revenue). Communes more dependent on TH revenue should increase taxe foncière rates more aggressively post-reform. Specification: Δtaux_foncière = commune FE + year FE + β(TH_dependence × Post2018).

**Why it's novel:** This captures the supply-side fiscal response to the reform, complementing the demand-side capitalization story. Combines public finance theory (Tiebout, tax competition) with empirical evaluation. The question "who really bears the cost of eliminating a tenant tax?" has clear policy relevance for countries considering similar reforms.

**Feasibility check:** REI data available with historical rates. Commune revenue data from DGCL (collectivites-locales.gouv.fr). Risk: State compensation mechanisms may fully offset lost TH revenue, leaving no fiscal pressure for rate increases. Empirical question.
