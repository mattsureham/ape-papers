# Research Ideas

## Idea 1: Cap On, Cap Off: The Symmetric Credit Rationing Experiment from Kenya's Interest Rate Ceiling (2016-2019)
**Policy:** Kenya's Banking Amendment Act (September 14, 2016) imposed an interest rate cap at CBR+4% on all 42 licensed commercial banks; the Finance Act 2019 (November 7, 2019) repealed it, creating a 38-month symmetric on-off natural experiment in credit market regulation.
**Outcome:** Central Bank of Kenya (CBK) monthly supervisory data: private sector credit growth, lending rates, government securities holdings, and NPL ratios for all 42 banks by tier (Tier 1/2/3). World Bank WDI annual credit/GDP. FinAccess household microdata (2016, 2019) for digital credit substitution.
**Identification:** Bank-tier DiD exploiting differential exposure: Tier 3 small banks (~21, SME-focused) cannot easily shift portfolios to government securities like Tier 1 large banks (~6). The symmetric cap-on/cap-off design provides a built-in reversal test — if credit rationing reverses upon repeal, the effect is causal. COVID affects all tiers equally, differenced out. Mechanism: portfolio rebalancing from private credit to government securities. Substitution: borrowers shift to unregulated M-Pesa digital credit (7.5% per 30 days ≈ 90% APR).
**Why it's novel:** No published study exploits the symmetric cap/repeal design. IMF WP/19/119 and World Bank WPS8398 study only the cap introduction. Kenya is one of very few countries to both impose and repeal a rate cap. The M-Pesa substitution channel is unmeasured. Generalizable to 76+ countries with interest rate ceilings.
**Feasibility check:** Confirmed: CBK monthly CSVs downloadable (424 rows, 1991-2024); lending rate dropped from 17.66% to 13.86% immediately at cap; private credit growth fell from +25% to +2.4%; 42 banks × 120 months = 5,040 bank-month observations; NPL ratio spiked from 6.0% to 12.0% during cap; FinAccess 2016 microdata on Harvard Dataverse (19.8 MB).

## Idea 2: Constitutional Designation and Health Convergence: Kenya's Equalization Fund and the Marginalization Gap
**Policy:** Kenya's 2010 Constitution (Article 204) designated 14 of 47 counties as marginalized and mandated an equalization fund (0.5% of national revenue). Actual disbursement was KES 26.3B of 54B entitlement (48.7%).
**Outcome:** DHS Kenya 2014 and 2022: facility delivery, ANC visits, vaccination, stunting across 46 counties (1,334 API-confirmed records).
**Identification:** Two-period DiD: 14 marginalized vs 33 non-marginalized counties. Pre-trend test using DHS 2003/2008 at province level. Synthetic DiD, wild cluster bootstrap (47 clusters).
**Why it's novel:** No published DiD on the marginalization designation as treatment. Reveals heterogeneous convergence: access outcomes converge while preventive care does not.
**Feasibility check:** Confirmed: DHS API returns data for both waves; 47 counties × 2 waves = 94 observations (thin but supplemented by ~63,000 women in microdata).

## Idea 3: Does Health System Capacity Determine Who Benefits from Free Maternity? County-Level Evidence from Kenya's 2013 Devolution
**Policy:** Kenya's 2010 Constitution devolved health to 47 counties (effective March 2013). Simultaneously, President Kenyatta abolished delivery fees at all public facilities (June 2013). Counties varied enormously in pre-existing health infrastructure.
**Outcome:** DHS Kenya 2014 (N=31,079 women) and 2022 (N=32,156 women) with county-level representative data. Kenya Master Health Facility List (KMHFL) for baseline capacity.
**Identification:** Continuous-treatment DiD using pre-devolution county health infrastructure capacity (facilities per capita, health worker density) as treatment intensity. Individual birth-level microdata (~30,000 births per wave).
**Why it's novel:** First paper to use DHS 2022 for decade-long devolution evaluation. No published study examines infrastructure capacity as mediator of free maternity policy effectiveness.
**Feasibility check:** Confirmed: DHS API returns county-level indicators for 2014 and 2022; facility delivery ranges from 20% (Wajir) to 95% (Kiambu); KMHFL publicly accessible.
