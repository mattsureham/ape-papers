# Research Ideas

## Idea 1: Bail-In Risk and Household Deposit Structure: How BRRD Transposition Reshuffled European Savings
**Policy:** Directive 2014/59/EU (BRRD) introduced bail-in risk for uninsured depositors (above EUR 100,000) with staggered transposition spanning Dec 2014 to Feb 2016. Upon bank failure, losses cascade through equity, subordinated debt, senior unsecured debt, and finally uninsured deposits. Transposition timing varied: Cyprus and Finland by end-2014; France, Italy, Romania, Sweden in late 2015; Luxembourg and Poland not until early 2016.
**Outcome:** ECB BSI dataset: monthly deposit composition by maturity type (L20 total, L21 overnight, L22 agreed maturity, L23 redeemable-at-notice) for household sector (2250). EBA DGS data: covered deposit ratio by country (2015-2024). Cross-border deposit flows via ECB BSI counterpart area decomposition.
**Identification:** Staggered DiD using Callaway-Sant'Anna. Treatment from IWH Banking Union Directives Database, cross-validated via CELLAR SPARQL (255 BRRD NIMs). 25 countries, 411 days of variation. Triple-difference using pre-BRRD uninsured deposit shares. Placebo on non-financial outcomes. Control for ECB QE timeline.
**Why it's novel:** Existing BRRD literature focuses on wholesale/capital markets (bail-in bond premia, CDS spreads). No paper studies the household deposit channel — whether bail-in risk caused systematic deposit restructuring across Europe.
**Feasibility check:** Confirmed: 25 countries, 411 days staggered transposition (IWH database downloadable), ECB BSI deposit data 60 monthly obs per country-type, EBA DGS Excel download, 255 BRRD NIMs from CELLAR SPARQL. ~5,040 country-month-type observations.

## Idea 2: Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock
**Policy:** The 2022 Russian gas shock caused a 10x spike in European gas prices. Countries with higher pre-war Russian gas dependence experienced larger domestic production collapses in energy-intensive sectors (chemicals, glass, metals, ceramics).
**Outcome:** Eurostat Comext monthly trade data (DS-059331) at HS2 product-level by member state, 2019-2024. Production indices from Eurostat. Triple-difference: country gas dependence × product energy intensity × time.
**Identification:** Triple-diff design with built-in placebo (non-energy-intensive products HS 84, 85, 62). Persistence test: did imports stay elevated after gas prices normalized in 2023-2024?
**Why it's novel:** No paper examines the trade reallocation channel of the gas shock — reverse import substitution where an industrialized region substitutes domestic production with imports due to cost shock.
**Feasibility check:** Confirmed: 8+ countries, 7+ HS2 products, monthly 2019-2024. Comext API returns data without authentication. ~4,032 country-product-month observations.

## Idea 3: Paying on Time Saves Firms: The EU Late Payment Directive and Small Firm Survival
**Policy:** Directive 2011/7/EU mandated max 30-day payment for public authorities with 8%+ interest on late payments. Transposition deadline March 2013 with Belgium delayed to November 2013.
**Outcome:** Eurostat bd_9bd_sz_cl_r2: firm birth rates, death rates, 3-year survival rates by size class (0, 1-4, 5-9, 10+), 35 countries, 2010-2020.
**Identification:** Triple-difference: pre/post March 2013 × countries with different payment cultures (25 days Scandinavia to 90+ Italy/Greece) × firm size classes (small 0-9 most exposed vs large 10+).
**Why it's novel:** Only one causal paper exists (Ferrando et al. 2021, JLE) using sector-level intensity. Our triple-diff uses firm size class as fundamentally different variation. No paper examines 3-year cohort survival rates.
**Feasibility check:** Confirmed: 28+ countries, 205,407 values, size classes 0/1-4/5-9/10+, 2010-2020.
