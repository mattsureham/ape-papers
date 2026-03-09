# Research Plan: Losing Rural Tax Breaks and Voting for the Rassemblement National

## Research Question

Does the withdrawal of place-based tax incentives cause affected communities to shift toward far-right populist parties? We study the 2017 reclassification of France's Zones de Revitalisation Rurale (ZRR), which removed 3,063 communes from eligibility for corporate tax holidays and social contribution exemptions, while adding 3,657 new communes. We estimate the causal effect on Rassemblement National (RN) vote share using both regression discontinuity and difference-in-differences designs.

## Institutional Background

ZRR was established in 1995 (Loi d'orientation pour l'aménagement et le développement du territoire) to revitalize declining rural areas through tax incentives:
- 5-year corporate income tax exemption for new establishments
- Employer social contribution exemptions for hiring
- Enhanced property tax exemptions

The 2015 finance law (Loi n° 2015-1786, Article 1388 quinquies C) reformed eligibility criteria:
- **Old criteria:** Commune-level population density and decline
- **New criteria:** EPCI-level density ≤ 63 hab/km² AND median fiscal income ≤ EUR 19,111
- **Effective date:** July 1, 2017
- **Transition:** Existing beneficiaries kept benefits until June 30, 2020

This created three groups:
1. **Losers** (3,063 communes): Previously ZRR, lost eligibility
2. **Gainers** (3,657 communes): Newly classified as ZRR
3. **Stayers** (~11,000 communes): Remained ZRR throughout

## Identification Strategy

### Primary: Regression Discontinuity (RD)

The EPCI density threshold at 63 hab/km² creates a sharp discontinuity in ZRR eligibility. Communes in EPCIs just below vs. just above this threshold are comparable in observables but differ in ZRR status after July 2017.

- **Running variable:** EPCI population density (habitants/km²)
- **Cutoff:** 63 hab/km²
- **Outcome:** Commune-level RN first-round presidential vote share (2022)
- **Bandwidth:** Data-driven (Calonico-Cattaneo-Farrell optimal bandwidth)
- **Estimator:** Local linear regression with triangular kernel

**Second RD:** Income threshold at EUR 19,111 median fiscal income (secondary).

### Complementary: Difference-in-Differences (DiD)

Panel of ~14,000 communes across 5 presidential elections (2002, 2007, 2012, 2017, 2022).

- **Treatment:** Communes that lost ZRR status (3,063 losers)
- **Control:** Communes that retained ZRR status (~11,000 stayers)
- **Estimator:** Callaway-Sant'Anna (2021) with single treatment timing (July 2017)
- **Pre-treatment periods:** 2002, 2007, 2012, 2017 (4 periods)
- **Post-treatment period:** 2022 (clean post-transition)

### Symmetric Test (Built-in Placebo)

ZRR gainers (3,657 communes that entered the program) should show the OPPOSITE effect — if losing benefits causes far-right voting, gaining benefits should reduce it. This is a powerful built-in placebo following tournament lesson on mechanism placebos.

## Expected Effects and Mechanisms

### Main hypothesis
Communes losing ZRR status experience:
1. Reduced business formation (first stage)
2. Employment decline or stagnation
3. Perception of state abandonment ("la France oubliée")
4. Increased support for RN (protest voting / economic grievance)

### Expected magnitudes
- First stage: 5-10% reduction in new establishment creation (ZRR exemption is substantial: up to 100% CIT exemption for 5 years)
- Main effect: 2-5 percentage point increase in RN vote share (comparable to Fetzer 2019 finding of 3-5pp UKIP increase from austerity)
- Symmetric: 1-3pp decrease in RN share for gainers (likely attenuated — gaining benefits may be less salient than losing them)

## Primary Specification

### RD specification:
Y_c = α + τ·D(density_EPCI < 63) + f(density_EPCI - 63) + X_c'β + ε_c

Where:
- Y_c: RN first-round vote share in commune c (2022)
- D: indicator for EPCI density below 63 hab/km²
- f(): local polynomial in running variable
- X_c: commune covariates (population, age structure, education)

### DiD specification:
Y_ct = α_c + γ_t + δ·(Loser_c × Post_t) + ε_ct

Where:
- Y_ct: RN first-round vote share, commune c, election t
- α_c: commune fixed effects
- γ_t: election fixed effects
- Loser_c: commune lost ZRR status in 2017
- Post_t: election year ≥ 2022 (or ≥ 2019 for secondary)

## Planned Robustness Checks

1. **RD validity:** McCrary density test, covariate balance at cutoff, donut-hole RDD, alternative bandwidths, placebo cutoffs
2. **DiD validity:** Event study plot (parallel trends 2002-2017), leave-one-out (drop each department)
3. **Anticipation test:** Check for break in 2017 relative to 2012 trend
4. **Transition dose-response:** Compare 2019 (partial treatment) vs 2022 (full treatment) effects
5. **Symmetric test:** Gainers should show opposite effect
6. **Alternative outcomes:** Turnout, other party vote shares (LFI, LREM, LR), abstention
7. **Heterogeneity:** By commune rurality, prior RN support, economic dependence on ZRR firms
8. **Spatial:** Conley standard errors accounting for spatial correlation

## Exposure Alignment (DiD)

- **Who is treated?** Communes that lost ZRR eligibility in July 2017
- **Primary estimand population:** All registered voters in loser communes
- **Placebo/control population:** Registered voters in ZRR stayer communes
- **Design:** Standard 2x2 DiD (single treatment timing) + event study
- **Symmetric placebo:** ZRR gainers (opposite treatment)

## Power Assessment

- **Pre-treatment periods:** 4 (2002, 2007, 2012, 2017)
- **Treated clusters:** 3,063 communes (loser group) — well above 20 minimum
- **Post-treatment periods:** 1 clean (2022), 1 partial (2019)
- **Cluster-level variance:** RN vote share σ ≈ 10pp across communes
- **MDE at 80% power:** With 3,063 treated and 11,000 control communes, MDE ≈ 0.8pp — well-powered to detect effects of 2pp or larger

## Data Sources

1. **ZRR classification:** data.gouv.fr (commune-level ZRR status pre/post 2017)
2. **Elections:** data.gouv.fr (commune-level presidential results 2002-2022, European 2019)
3. **Establishments:** INSEE Sirene bulk (creation/cessation dates by commune)
4. **Employment:** FLORES/CLAP (commune-level employment by sector)
5. **Commune characteristics:** INSEE RP (population, age, education, income)
6. **EPCI density/income:** INSEE (for RD running variables)

## Literature Positioning

- **Fetzer (2019, AER):** UK austerity → UKIP voting. We test the parallel mechanism (withdrawal of place-based benefits → far-right voting) in France with sharper identification (RD + symmetric test).
- **Autor et al. (2020, AER):** Trade shocks → populism in US. We study fiscal withdrawal rather than trade exposure.
- **Dustmann et al. (2017):** Refugee allocation → AfD in Germany. Different shock type but same populist response channel.
- **Dippel et al. (2022):** Import competition → AfD. Economic grievance mechanism.
- **Guilluy (2014):** "La France périphérique" — our paper provides causal evidence for the narrative that state withdrawal from rural areas fuels populism.
