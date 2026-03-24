# Research Plan: The Conscription Complement — Civilian Service Expansion and Healthcare Employment in Switzerland

## Research Question

When Switzerland abolished its conscience test for civilian service in April 2009 — quadrupling the number of conscripts deployed to health and social care — did these near-free workers crowd out paid employment or complement it? This question has first-order welfare implications: if mandated quasi-free labor displaces market employment, national service programs may undermine the very sectors they aim to support.

## Policy Background

Swiss male citizens face mandatory military service. Since 1996, conscientious objectors could substitute civilian service (Zivildienst), but admission required passing a conscience examination (Gewissensprüfung/Tatbeweis). The April 1, 2009 reform abolished this test: anyone willing to serve 1.5× the military duration could enter civilian service. Result: admissions jumped from 1,632 (2008) to 6,720 (2009) — a 312% increase. By 2024, 1.9 million service days per year, with 51.6% in social services and 14.8% in healthcare (66.4% combined in treatment sectors).

## Identification Strategy

**Sector-level Difference-in-Differences**

- **Treatment sectors:** NOGA 86 (health), 87 (residential care), 88 (social work) — receiving ~66% of all civilian service days
- **Control sectors:** Comparable service sectors NOT receiving civilian servants: education (NOGA 85), hospitality (NOGA 55-56), professional/scientific services (NOGA 69-75), administrative services (NOGA 77-82)
- **Treatment timing:** April 1, 2009 (precise, overnight)
- **Pre-period:** 2005–2008 (quarterly: 16 pre-periods)
- **Post-period:** 2009–2015 (quarterly: 28 post-periods)
- **Unit of observation:** Canton × sector × quarter

**Built-in dose-response test:** The 2011 partial reversal tightened admission procedures, reducing new admissions by ~30%. If the 2009 shock affected employment, the 2011 tightening should partially reverse it.

**Triple-difference opportunity:** Canton-level variation in deployment intensity (French vs. German cantons, urban vs. rural) provides within-treatment heterogeneity.

## Expected Effects and Mechanisms

1. **Crowding-out hypothesis:** Near-free civilian servants substitute for paid workers → paid employment in health/social sectors declines relative to controls. Mechanism: employers replace positions with cost-free labor.

2. **Complementarity hypothesis:** Civilian servants fill unfilled vacancies and perform tasks that expand capacity → paid employment unchanged or increases. Mechanism: care facilities expand services using both civilian servants and paid workers.

3. **Null hypothesis:** The volume of civilian service days (~500K-900K/year) is too small relative to total sectoral employment (~500K FTE in NOGA 86-88) to move aggregate employment. The 1-2% labor supply shock may be undetectable.

## Primary Specification

Y_{cst} = α + β(Treated_s × Post_t) + γ_cs + δ_t + ε_{cst}

Where:
- Y = log employment (FTE or headcount) in canton c, sector s, quarter t
- Treated_s = 1 if NOGA 86, 87, or 88
- Post_t = 1 if t ≥ 2009Q2
- γ_cs = canton × sector fixed effects
- δ_t = quarter fixed effects
- Clustering: canton level (26 clusters) → wild cluster bootstrap for inference

## Data Sources

1. **BFS BESTA (Beschäftigungsstatistik):** Quarterly employment by canton × NOGA 2-digit sector. Goes back to early 2000s. Primary outcome variable.

2. **BFS STATENT (Statistik der Unternehmensstruktur):** Annual establishment-level data by canton × NOGA from 2011. Supplementary: FTE vs headcount decomposition.

3. **ZIVI administrative statistics:** Annual admissions, service days by sector. Available 1996-2024. Treatment intensity measure.

4. **BFS PXWeb wage data:** Median wages by sector — mechanism test for wage effects.

## Robustness

1. Event-study specification with leads and lags (pre-trend test)
2. Leave-one-canton-out (sensitivity to individual cantons)
3. Permutation inference: randomly assign treatment to control sectors
4. Alternative control groups: manufacturing vs. services
5. 2011 partial reversal as dose-response validation
6. HonestDiD sensitivity analysis for parallel trends violation
