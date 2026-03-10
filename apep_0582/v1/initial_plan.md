# Initial Research Plan: The Resilience Puzzle

## Research Question

How did European manufacturing survive the largest peacetime energy supply shock in history? When Russia cut pipeline gas deliveries from ~155 bcm (2021) to near zero (2023), CGE models predicted 0.2-3% GDP losses for Germany alone (Bachmann et al. 2022). The predicted industrial catastrophe largely failed to materialize. This paper asks: (1) How large was the differential production decline in gas-exposed country-sector pairs? (2) Through which channels did Europe's manufacturing sector adapt?

## Identification Strategy

**Design:** Continuous-treatment DiD exploiting the interaction of country-level Russian gas exposure (2021) and sector-level gas intensity.

**Estimating equation:**

Y_{c,s,t} = α_{cs} + γ_{ct} + δ_{st} + β × RussianGasShare_c × GasIntensity_s × Post_t + ε_{c,s,t}

- α_{cs}: country × sector FE (absorb time-invariant differences)
- γ_{ct}: country × month FE (absorb country-level macro shocks, sanctions, fiscal responses)
- δ_{st}: sector × month FE (absorb global sector trends, supply chain disruptions)
- Post_t: 1 if t ≥ March 2022

**Key identifying assumption:** Conditional on the triple FE, the interaction of pre-war Russian gas dependence and sector gas intensity is orthogonal to other determinants of production changes.

**Why credible:** (1) Pre-war gas dependence was determined by decades of infrastructure investment. (2) Nord Stream sabotage (Sep 26, 2022) was completely exogenous. (3) Sector gas intensity reflects technology, not firm choices. (4) Triple FE absorb country-level fiscal responses, global sector shocks, and time-invariant heterogeneity.

## Expected Effects and Mechanisms

**Main estimate:** Based on apep_0544's findings, expect a negative but statistically imprecise β. The point estimate suggests ~2-5% production decline per unit of gas exposure × intensity, but confidence intervals span from large negative to near zero.

**The resilience puzzle:** The core contribution is decomposing WHY the predicted catastrophe didn't materialize:

1. **Fiscal shield hypothesis:** €700bn+ in government energy subsidies (Germany: €200bn, France: €100bn, Italy: €90bn) attenuated energy cost pass-through. Test: interact main estimate with country-level subsidy spending per GDP. Predict: β is more negative in low-subsidy countries.

2. **LNG substitution hypothesis:** Countries that rapidly expanded LNG import capacity reduced effective Russian gas dependence. Test: compare production dynamics in countries with vs. without LNG terminals. Predict: countries with LNG infrastructure show faster recovery.

3. **Trade reallocation hypothesis:** If domestic production of gas-intensive goods declined, imports from less-exposed countries/non-EU sources increased. Test: estimate same DiD on import volumes by product category. Predict: import growth inversely correlated with domestic production decline.

4. **Energy demand destruction hypothesis:** Firms reduced energy intensity rather than output. Test: estimate DiD on gas consumption data by sector. Predict: gas consumption fell more than production in gas-intensive sectors.

**Placebo groups:**
- Electricity-intensive but gas-independent sectors (e.g., aluminum smelting powered by hydroelectricity)
- Non-EU gas-dependent countries (Turkey, Serbia) that didn't receive EU fiscal support
- Pre-invasion placebo periods (March 2019, March 2020)

## Primary Specification

- **Unit:** Country × NACE 2-digit sector × month
- **Sample:** ~25 EU countries, ~15-20 manufacturing sectors, Jan 2018 - Dec 2024
- **Treatment:** RussianGasShare_c × GasIntensity_s (continuous, pre-determined 2021 values)
- **Clustering:** Country level (23-25 clusters)
- **Inference:** Cluster-robust SE + wild cluster bootstrap + randomization inference (permuting gas shares across countries)

## Exposure Alignment

- **Who is treated?** Manufacturing firms in gas-intensive sectors located in countries with high pre-war Russian gas dependence
- **Primary estimand:** Differential production change in high-exposure vs. low-exposure country-sector pairs
- **Built-in placebo:** Non-gas-intensive sectors within the same countries; same sectors in gas-independent countries (Spain, Portugal, Norway)

## Power Assessment

- **Country clusters:** ~23-25
- **Sector variation:** ~15-20 NACE codes with distinct gas intensity values
- **Pre-treatment periods:** 48+ months (Jan 2018 - Feb 2022)
- **Post-treatment periods:** 33+ months (Mar 2022 - Dec 2024)
- **Known limitation:** 23-25 country clusters is modest → wild cluster bootstrap and RI essential
- **Mitigation from apep_0544:** The prior paper found t=-0.54 with production alone. This paper's value-add is mechanism decomposition, not statistical precision on the main estimate.

## Planned Robustness Checks

1. Leave-one-out (especially Hungary — known outlier)
2. Wild cluster bootstrap
3. Randomization inference (permuting gas shares)
4. Alternative post-treatment dates (Jun 2022, Sep 2022 for progressive escalation)
5. Pre-trend event study (monthly coefficients, 2018-2024)
6. Exclude COVID period (start sample Jan 2018, cut 2020 or include COVID × sector controls)
7. Alternative gas intensity measures (energy balance vs. EU ETS data)
8. Continuous treatment (gas share) vs. binary (above/below median)
