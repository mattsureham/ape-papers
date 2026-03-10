# Initial Research Plan: Frozen Out

## Research Question

Does energy import dependence on Russian gas translate into measurable excess winter mortality during the 2022-2023 European energy crisis? If so, energy diversification is not merely economic strategy but public health intervention.

## Identification Strategy

**Continuous-treatment DiD.** The 2022 Russian gas cutoff is a common shock that hit all European countries simultaneously, but with differential intensity determined by pre-war (2021) Russian gas dependence. Countries like Finland (75%), Germany (66%), and Italy (40%) faced binding constraints; Spain (9%) and Portugal (~5%) were effectively untreated.

**Main specification:**
```
Deaths_{c,w} = alpha_c + gamma_w + beta * GasDep_c * Post_w + X'_{c,w} delta + epsilon_{c,w}
```
Where:
- `Deaths_{c,w}` = weekly deaths per 100,000 in country c, week w
- `GasDep_c` = 2021 share of Russian gas in total gas supply (continuous 0-0.75)
- `Post_w` = indicator for heating seasons starting winter 2022/23
- `alpha_c` = country fixed effects
- `gamma_w` = week fixed effects (absorbs Europe-wide seasonal patterns)
- `X_{c,w}` = COVID deaths, temperature, GDP per capita

**Estimand:** The additional winter deaths per 100,000 attributable to a 10 percentage point increase in Russian gas dependence, during and after the 2022 price shock.

## Expected Effects and Mechanisms

**Primary channel:** Gas dependence → energy prices ↑ → heating costs ↑ → under-heating among elderly/low-income → excess winter mortality from cardiovascular and respiratory causes.

**Expected sign:** Positive (more gas-dependent → more excess winter deaths).

**Expected magnitude:** Small but detectable. UK "fuel poverty" literature estimates 1 excess winter death per 250-500 fuel-poor households. With heating costs doubling in high-dependence countries, even modest under-heating responses could generate 2-5 additional deaths per 100,000 elderly.

**Alternative channel:** Gas dependence → industrial contraction → unemployment/income loss → health deterioration (indirect, slower).

## Exposure Alignment

- **Who is actually treated?** All European households in gas-dependent countries, through higher retail energy prices. Treatment intensity is continuous (0-97% gas dependence).
- **Primary estimand population:** Entire population of 26 European countries, measured at the country-week level.
- **Placebo/control population:** Countries with zero or low Russian gas dependence (Denmark, Ireland, Norway, Sweden).
- **Design:** Continuous-treatment DiD (not binary; not staggered). Common treatment timing (Feb 2022 invasion) with heterogeneous intensity.

## Exposure Alignment

- **Who is actually treated?** All European households in gas-dependent countries, through higher retail energy prices. Treatment intensity is continuous (0-97% gas dependence).
- **Primary estimand population:** Entire population of 26 European countries, measured at the country-week level.
- **Placebo/control population:** Countries with zero or low Russian gas dependence (Denmark, Ireland, Norway, Sweden).
- **Design:** Continuous-treatment DiD (not binary; not staggered). Common treatment timing (Feb 2022 invasion) with heterogeneous intensity.

## Built-in Placebos (Critical for Identification)

1. **Summer placebo:** Effects should be zero in warm months (May-September). Heating costs are irrelevant in summer. If beta > 0 in summer, the specification is confounded.

2. **Age-gradient placebo:** Effects should concentrate in 75+ and vanish for working-age (25-64). Working-age adults rarely die from under-heating. If beta is similar across age groups, something other than heating is driving results.

3. **Pre-2022 winter placebo:** Running the same specification on winters 2019/20 and 2020/21 should show zero. Gas dependence should not predict mortality before the supply shock.

4. **Non-gas energy placebo:** Countries dependent on Russian oil (different product, less heating-relevant) should show weaker/no effects.

## Primary Specification Details

- **Unit of analysis:** Country × week (or country × age-group × week for age-gradient analysis)
- **Treatment timing:** "Post" begins at Week 40, 2022 (start of heating season 2022/23)
- **Treatment intensity:** 2021 Russian gas share (continuous)
- **Clusters:** Country level (conservative; 20 clusters)
- **Estimator:** OLS with two-way FE. Since treatment is continuous intensity with common timing, standard TWFE is appropriate (no staggered-adoption bias).

## Planned Robustness Checks

1. **Wild cluster bootstrap** (small-N correction for 20 country clusters)
2. **Leave-one-out:** Drop each high-dependence country (Germany, Italy, Finland) to check no single country drives results
3. **Alternative treatment measures:** IEA gas import data, Eurostat nrg_ti_gasm
4. **Alternative mortality measures:** Excess mortality above 2015-2019 baseline (EuroMOMO approach)
5. **Controlling for COVID:** Include weekly COVID deaths as covariate; exclude 2020/21 COVID waves
6. **Temperature controls:** Heating degree days (HDD) from Eurostat or ERA5
7. **Fiscal relief controls:** Countries with larger energy subsidies (price caps, lump-sum transfers) should show weaker effects — heterogeneity test
8. **Randomization inference:** Permute gas dependence across countries (20! permutations)
9. **Dose-response:** Binned gas dependence (quartiles) to check linearity

## Data Sources

| Dataset | Source | Observations | Role |
|---------|--------|-------------|------|
| demo_r_mwk_ts | Eurostat | ~5,220 | Weekly total deaths, 20 countries |
| demo_r_mwk_05 | Eurostat | ~12,528 | Weekly deaths by age, 8 countries |
| prc_hicp_midx (CP045) | Eurostat | ~600 | Monthly HICP energy prices |
| nrg_ti_gasm | Eurostat | ~513 | Monthly gas imports from Russia |
| Gas dependence shares | IEA/Eurostat/literature | ~25 | Cross-section treatment intensity |
| demo_r_mweek3 | Eurostat | TBD | Alternative weekly deaths by age |
| nrg_cb_gasm | Eurostat | TBD | Gas consumption by country |

## Power Assessment

- **Countries:** 20 (continuous treatment)
- **Pre-periods:** ~155 weeks (2019-W01 to 2022-W39)
- **Post-periods:** ~52 weeks (2022-W40 to 2023-W39) for first winter; ~104 for two winters
- **Total cells:** ~5,200 for main specification
- **Cluster count:** 20 countries (modest — will use wild cluster bootstrap)

## Timeline

1. Data fetch and cleaning (01-02)
2. Descriptive statistics and first-stage (gas dependence → energy prices)
3. Main mortality analysis (03)
4. Robustness battery (04)
5. Figures and tables (05-06)
6. Paper writing
7. Review and revision
