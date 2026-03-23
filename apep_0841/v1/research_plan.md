# Research Plan: Poland's 2019 Child Benefit Universalization and Female Labor Supply

## Research Question

Does universalizing a child benefit — removing the income test for first-child families — cause measurable maternal labor market exit? Poland's July 2019 extension of the "Family 500+" benefit to all first children created a sudden 500 PLN/month (~€120) windfall for ~1.4 million previously-excluded one-child families, providing a clean natural experiment.

## Identification Strategy

**Difference-in-Differences with continuous treatment intensity across NUTS2 regions.**

The 2019 universalization is a simultaneous nationwide shock. I exploit cross-regional variation in the share of families with exactly one child (proxied by the inverse of total fertility rate at NUTS2 level, measured in 2017–2018) as a continuous treatment intensity measure. Regions with more one-child families experienced a larger per-capita income shock.

**Panel construction:**
- Polish NUTS2 regions (16 regions, treated with varying intensity)
- CEE NUTS2 regions as controls: Czech Republic (~8), Slovakia (~4), Hungary (~8), Romania (~8), Bulgaria (~6) — similar economies without a comparable 2019 child benefit universalization
- Total: ~50 NUTS2 regions × 14 years (2010–2023) = ~700 region-year observations

**Specification:**
$$Y_{r,t} = \alpha_r + \gamma_t + \beta \cdot (Poland_r \times Post2019_t \times TI_r) + \delta \cdot (Poland_r \times Post2019_t) + X_{r,t}'\theta + \varepsilon_{r,t}$$

Where $TI_r$ is pre-determined treatment intensity (one-child family share proxy).

**Event study:** 9 pre-periods (2010–2018), treatment at 2019.

## Expected Effects

- **Primary:** Negative effect on female employment rate (ages 25–49) in high-intensity Polish regions post-2019
- **Magnitude:** Literature suggests income elasticity of female labor supply ~0.1–0.3 for cash transfers. With ~22% of median income, expect 2–5 pp reduction
- **Mechanism:** Substitution from formal employment to home production / childcare

## Data Sources

1. **Eurostat `lfst_r_lfe2emprt`** — Employment rates by sex, age (25–49), NUTS2 level, 2010–2023
2. **Eurostat `demo_r_frate2`** — Fertility rates by NUTS2 (for treatment intensity proxy)
3. **Eurostat `demo_r_pjangrp3`** — Population structure by NUTS2 (controls)
4. **Eurostat `nama_10r_2gdp`** — Regional GDP (controls)

## Exposure Alignment

The treatment directly affects mothers of first children (ages 0–17) who were previously excluded from the 500+ benefit due to the income test. The outcome (female employment rate, ages 25–64 at NUTS2 level) captures these mothers but also includes childless women and mothers of multiple children who were already eligible. This dilution attenuates the estimated effect: the regional-level estimate reflects the average across all women, not just the newly eligible. The treatment intensity measure (inverse TFR) proxies for the share of one-child families—the directly affected group—to partially address this dilution. Despite this limitation, the regional approach is necessary because individual-level EU-LFS microdata are not publicly available through the Eurostat API.

## Robustness

1. Placebo treatment years (2014, 2016, 2017)
2. Wild cluster bootstrap (16 Polish clusters)
3. Leave-one-region-out sensitivity
4. Male employment as placebo outcome
5. Alternative CEE control groups (drop Romania/Bulgaria)
6. Controlling for COVID-19 effects (2020–2021 interactions)

## Feasibility Assessment

- Data confirmed available via Eurostat API (manifest smoke test: 411,810 obs)
- 16 Polish NUTS2 regions with meaningful variation in TFR (1.1–1.7 range)
- 9 clean pre-periods for event study
- 500 PLN/month is a very large treatment (~22% of low-income regional wages)
