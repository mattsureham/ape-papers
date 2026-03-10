<!-- pinned: idea_0338 -->
# Research Ideas

## Idea 1: Protecting Landscapes, Punishing Renters: The Unintended Rental Market Effects of Switzerland's Second Homes Ban
**Policy:** Switzerland's 2012 Second Homes Initiative (Lex Weber), approved by voters 50.6%-49.4% on March 11, 2012, amended the Constitution (Art. 75b) to cap second homes at 20% per municipality. Effective January 1, 2013 (emergency ordinance); January 1, 2016 (ZWG federal act). ~400 municipalities in Alpine tourism regions (Graubünden, Valais, Bern Oberland, Ticino) affected. Treatment is binary: municipalities above 20% second-home share are banned from issuing new vacation home permits.
**Outcome:** BFS Leerwohnungszählung (vacant dwellings by municipality, 1990-2023). BFS STATENT (employment by municipality and sector, 2011-2023). ARE Wohnungsinventar (second-home share by municipality via geo.admin.ch). BFS demographic balance via PxWeb (28 cantons, 1971-2024). Cantonal building permit data from opendata.swiss.
**Identification:** Sharp DiD: municipalities above 20% threshold (treated) vs. below (control), before/after 2013. The threshold was arbitrary (set by initiative sponsors, not market conditions). Surprise outcome (polls predicted defeat, 50.6% margin). Complementary RDD: just above vs. just below 20% for LATE. 20+ years of pre-data (1990-2012) for parallel trends. CS-DiD for heterogeneity across treatment intensity quintiles. Built-in placebo: non-tourism municipalities that happen to have high second-home shares vs. tourism municipalities below the cutoff.
**Why it's novel:** Hilber & Schöni (2020, J Urban Economics) study prices/unemployment. Deville (2022, Swiss J Econ Stat) studies construction permits. Nobody has studied RENTAL MARKET consequences — vacancy rates, rental scarcity, sorting, or population displacement. Deville documents ~40% fall in rental construction in treated municipalities but does not follow through to rental market outcomes.
**Feasibility check:** Variation confirmed (400 treated + 1,700 control municipalities; binary treatment Jan 2013). Data access confirmed (BFS vacancy via cantonal portals, ZH CSV 1990-2023; ARE via geo.admin.ch; BFS PxWeb). Novelty confirmed (no paper studies rental vacancy, rental prices, or sorting). Sample size: ~2,100 municipalities × 20+ years ≈ 42,000 observations.

## Idea 2: Cantonal Minimum Wages and Low-Wage Employment: Evidence from Switzerland's Staggered Adoption
**Policy:** Five Swiss cantons adopted cantonal minimum wages between 2017 and 2022 (Neuchâtel 2017, Jura 2018, Geneva 2020, Ticino 2021, Basel-Stadt 2022).
**Outcome:** BFS STATENT via PXWeb API: establishments and employees by year × canton × NOGA sector × gender/FTE (2011-2023).
**Identification:** Callaway & Sant'Anna staggered DiD with 5 treatment cohorts and 21 never-treated cantons. DDD: low-wage vs. high-wage sectors within treated vs. untreated cantons.

## Idea 3: Corporate Tax Competition After Harmonization: The Swiss TRAF Reform and Firm Dynamics
**Policy:** Switzerland's 2020 TRAF/STAF reform forced all 26 cantons to abolish special corporate tax regimes but allowed each canton to set its own replacement rate.
**Outcome:** BFS STATENT via PXWeb API: establishments and employees by year × canton × size class (2011-2023).
**Identification:** Continuous treatment intensity DiD: treatment = (pre-reform rate 2018) − (post-reform rate 2021). Federal mandate forcing reform addresses endogeneity.
