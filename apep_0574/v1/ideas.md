# Research Ideas

## Idea 1: Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock
**Policy:** Russia's February–September 2022 gas cutoff spiked TTF prices from 30 to 342 EUR/MWh, with differential pre-war dependence across EU countries (Finland 75%, Germany 66%, Italy 40%, France 24%, Spain 9%). Energy-intensive domestic production (chemicals, glass, metals) collapsed in gas-dependent countries while extra-EU imports of the same goods surged.
**Outcome:** Eurostat Comext DS-059331 monthly trade data: HS2 product-level imports by member state and partner, 2019–2024. Key HS codes: 28 (inorganic chemicals), 29 (organic chemicals), 31 (fertilizers), 39 (plastics), 69 (ceramics), 72 (iron/steel), 76 (aluminium). Supplemented by Eurostat STS_INPR_M monthly production indices to confirm the domestic production channel.
**Identification:** Triple-difference: country (pre-war Russian gas dependence, continuous 0–75%) × product (energy intensity of HS2 sector) × time (pre/post Feb 2022). Non-energy-intensive products (HS 84 machinery, 85 electrical, 62 apparel) serve as built-in placebos. Persistence test: did imports stay elevated after gas prices normalized in 2023–2024, indicating permanent comparative advantage loss? Placebo tests: pre-treatment trends, non-gas-dependent countries, non-energy-intensive products.
**Why it's novel:** Existing literature (Bachmann et al. 2022 Econometrica, VoxEU 2023) uses aggregate production indices and concludes "no broad deindustrialization." No paper examines the trade reallocation channel — whether gas-dependent countries substituted collapsed domestic production with extra-EU imports. This is reverse import substitution: an industrialized region becoming an importer due to a cost shock.
**Feasibility check:** Confirmed: Comext API returns monthly trade data with no authentication (2,304 rows for 8 countries × 2 HS codes × monthly 2019–2024). German ceramics (HS 69) extra-EU imports surged 21% between June 2021 and June 2022 while domestic chemical production fell 20% peak-to-trough. 22 countries × 7+ HS2 products × 72 months ≈ 11,000+ observations.

## Idea 2: Creative Destruction or Just Destruction? Enterprise Deaths and the Permanent Restructuring of European Manufacturing After the 2022 Gas Shock
**Policy:** Same Russian gas cutoff. Business demography data reveals whether firm exits (permanent, irreversible) increased in gas-dependent countries' energy-intensive sectors.
**Outcome:** Eurostat BD_SIZE (enterprise births/deaths/stock by NACE sector and country, 2010–2023). 2,187 rows confirmed. German chemicals births collapsed from 535 (2022) to 187 (2023).
**Identification:** Continuous DiD with double variation: country-level Russian gas share × sector-level gas intensity. 7 pre-treatment years.
**Why it's novel:** Existing literature uses production indices (flow). This uses firm stock (permanent change). Distinguishes "Europe had a bad year" vs "Europe lost its chemical industry."
**Feasibility check:** Confirmed: BD_SIZE API returns 2,187 rows, no authentication. 22 countries × 9 NACE sectors × 9 years.

## Idea 3: No Registration, No Market: The REACH 2018 Deadline and Chemical Industry Restructuring
**Policy:** REACH (EC 1907/2006) established three tonnage-phased deadlines: Nov 2010 (≥1,000t), May 2013 (≥100t), May 2018 (≥1t). The 2018 deadline disproportionately affected SMEs: 16% of registrants, costs 7× higher than predicted.
**Outcome:** Eurostat sbs_na_ind_r2 (enterprises, employment, turnover for NACE C20 chemicals and controls C22–C25). 18 countries, 2008–2020, 3,450 data points.
**Identification:** Triple-difference: time (pre/post May 2018) × sector (C20 chemicals vs C22–C25 controls) × country (pre-treatment micro-firm share, 40% Germany to 85% Czechia). 2013 deadline as built-in falsification test (targeted large firms).
**Why it's novel:** No quasi-experimental REACH study exists. The Commission's 2021 study relied on surveys only.
**Feasibility check:** Confirmed: Eurostat SBS 3,450 data points; business demography 4,592 data points.
