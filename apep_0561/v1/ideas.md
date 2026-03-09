# Research Ideas

## Idea 1: Losing Rural Tax Breaks and Voting for the Rassemblement National: The ZRR Reclassification of 2017
**Policy:** ZRR (Zones de Revitalisation Rurale) grants 5-year corporate income tax holidays and employer social contribution exemptions. The 2015 finance law reformed criteria, effective July 1, 2017: shifted from commune-level to EPCI-level classification (density ≤ 63 hab/km² AND median income ≤ EUR 19,111). Created 3,063 losers and 3,657 gainers.
**Outcome:** RN vote share at commune level. Pre: 2002, 2007, 2012, 2017 presidential. Post: 2019 European, 2022 presidential. data.gouv.fr. Mechanism: business establishment counts (Sirene/Flores), employment, population.
**Identification:** DiD: ZRR losers (3,063) vs stayers (~11,000). RD: EPCI density at 63 hab/km² and income at EUR 19,111. Symmetric test: gainers (3,657) should show opposite effect. Timing: reclassification July 1, 2017, presidential election April 2017 = last pre-treatment. Transition period (benefits kept until June 2020) attenuates 2019 European but 2022 presidential is clean.
**Why it's novel:** No academic paper studies electoral consequences of ZRR reclassification. Closest analogue: Fetzer (2019 AER) on UK austerity → UKIP. This tests parallel mechanism in France with specific, dateable policy reclassification.
**Feasibility check:** Variation confirmed: 3,063 losers, 3,657 gainers, ~11,000 stayers. Data access confirmed: ZRR dataset on data.gouv.fr; election data confirmed. Sample size: ~14,000 communes × 7 elections.

## Idea 2: The Loi NOTRe and Municipal Mergers: Effects on Local Public Spending and Tax Competition
**Policy:** The Loi NOTRe (2015) forced ~800 intercommunalité mergers on January 1, 2017, halving the number of EPCIs from 2,062 to 1,259. This restructured fiscal governance for affected communes.
**Outcome:** Local public spending per capita, tax rates (taxe d'habitation, taxe foncière), public service provision quality.
**Identification:** DiD comparing communes in merged EPCIs vs communes in unaffected EPCIs across the 2017 boundary. Pre-periods: 2010-2016. Post: 2017-2023.
**Why it's novel:** Limited causal evidence on effects of French territorial consolidation on fiscal outcomes.
**Feasibility check:** Treatment variation across ~800 mergers. Fiscal data available from DGFIP open data.

## Idea 3: Maternity Ward Closures and Birth Outcomes in France
**Policy:** France closed 276 maternity wards from 2000 to 2024 across 79 departments. Closures followed minimum-volume thresholds (300 births/year) set by health planning agencies.
**Outcome:** Commune-level premature birth rates, low birth weight, perinatal mortality, travel time to nearest ward.
**Identification:** Staggered event-study DiD on commune-level proximity to closed wards, exploiting the timing variation across departments.
**Why it's novel:** Limited causal evidence on health consequences of maternity ward rationalization in a universal healthcare system.
**Feasibility check:** Data on ward locations and closure dates available from DREES/SAE. Birth outcome data from INSEE état civil.
