# Research Plan: Italy's Universal Child Benefit Revolution

## Research Question

Does extending child benefits to previously excluded self-employed and unemployed families raise fertility? Italy's March 2022 Assegno Unico Universale (AUU) replaced eight fragmented transfers with one universal system, creating sharp treatment for ~4.6 million households that previously received zero family allowances.

## Identification Strategy

**Triple-difference (DDD):**
- **Dimension 1 (time):** Pre (2015–2021) vs post (2022–2023) AUU implementation
- **Dimension 2 (treatment intensity):** Cross-regional variation in self-employment share (16.5% in Friuli-Venezia Giulia to 27.3% in Molise) — higher share → more families gained NEW benefit access
- **Dimension 3 (country):** Italian NUTS3 provinces vs comparable EU NUTS3 regions (Spain, France, Germany, Portugal, Greece) as additional control group

**Key identifying assumption:** Absent AUU, Italian provinces with higher vs lower self-employment shares would have followed parallel birth rate trends. Testable with 7 pre-treatment years.

**Event study specification:**
$$Y_{r,t} = \sum_{k \neq -1} \beta_k \cdot \mathbf{1}(t = k) \cdot \text{SelfEmpShare}_r + \gamma_r + \delta_t + X_{r,t}'\theta + \varepsilon_{r,t}$$

where $Y_{r,t}$ is the crude birth rate (or first-birth rate) in NUTS3 region $r$ in year $t$, $\text{SelfEmpShare}_r$ is the pre-reform (2019) self-employment share at the NUTS2 level, and $\gamma_r, \delta_t$ are region and year fixed effects.

## Expected Effects and Mechanisms

**Primary hypothesis:** Regions with higher self-employment shares should see larger fertility increases post-AUU, especially for first births (extensive margin).

**Mechanism:** The AUU removed "structural exclusion" — self-employed families received EUR 0 in family allowances pre-reform, then EUR 50–175/month per child post-reform. This is a pure extensive-margin policy change (from nothing to something) for the treated group, not a marginal generosity increase.

**Expected magnitude:** Small but detectable. Literature suggests cash transfers increase fertility by 0.01–0.05 children per woman (Gonzalez 2013, Milligan 2005). The AUU transfer (~EUR 1,600/year per child) is modest.

**Heterogeneity:**
- First births vs higher-order births (extensive margin strongest for first)
- Mother's age (younger mothers more responsive)
- ISEE income quintiles (if available at regional level)

## Primary Specification

```
births_rate_r_t ~ post_2022 * self_emp_share_r + region_FE + year_FE + controls
```

**Controls:** Regional GDP per capita, unemployment rate, female labor force participation, net migration rate (all from Eurostat regional statistics).

## Data Sources

| Variable | Source | Eurostat Code | Coverage |
|----------|--------|---------------|----------|
| NUTS3 live births | Eurostat | demo_r_gind3 | 115 provinces, 2000–2023 |
| NUTS3 population | Eurostat | demo_r_pjangroup | 115 provinces, 2000–2023 |
| NUTS2 employment by status | Eurostat | lfst_r_lfe2estat | 21 regions, 1999–2024 |
| National births by order | Eurostat | demo_fordagec | 1960–2023 |
| EU NUTS3 births (controls) | Eurostat | demo_r_gind3 | ~1,400 NUTS3 regions |
| Regional GDP | Eurostat | nama_10r_2gdp | NUTS2/3, 2000–2023 |
| Regional unemployment | Eurostat | lfst_r_lfu3rt | NUTS2, 2000–2024 |

## Robustness

1. **Placebo test:** Run same specification with pre-reform "pseudo-treatment" dates (2018, 2019)
2. **Alternative treatment:** Use share of families below ISEE EUR 15K threshold (max benefit) instead of self-employment share
3. **EU comparators:** Spain, Portugal, Greece (similar fertility decline, no comparable reform in 2022) as control countries
4. **Dose-response:** Continuous treatment with self-employment share quartiles
5. **Birth order decomposition:** First births should respond more than higher-order births
6. **Leave-one-out:** Sequentially drop each NUTS2 region to check for outlier sensitivity
