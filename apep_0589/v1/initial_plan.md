# Initial Research Plan: ERDF Treatment Withdrawal and Regional Convergence

## Research Question

Do EU Structural Fund transfers create durable regional convergence, or do regions relapse when funding is withdrawn? We exploit the 2014 programming period transition, which abruptly reduced ERDF co-financing for regions that graduated above the 75% GDP/capita threshold.

## Identification Strategy

**Multi-period fuzzy RDD at the 75% threshold.**

- **Running variable:** 3-year average GDP per capita (PPS) as % of EU27 average, measured at the end of the 2007-2013 period
- **Treatment:** Crossing the 75% threshold → sharp drop in ERDF co-financing rate (from 85% to 50-60%) and reduced total allocations
- **Estimator:** Local polynomial RDD (rdrobust), with fuzzy specification using actual ERDF EUR per capita as endogenous variable
- **Bandwidth:** CCT optimal bandwidth selection + manual sensitivity (±5pp to ±20pp)

**Key threats and responses:**
1. *Mean reversion:* GDP growth may mechanically slow for regions crossing 75%. Response: pre-trend test, donut holes, reduced-form intent-to-treat
2. *Transition regions:* 75-90% category gets intermediate funding. Response: explicitly model the multi-tier structure
3. *Payment lags:* ERDF payments extend beyond programming period boundaries (N+2 rule). Response: use actual payment data, test with cumulative rolling windows
4. *Manipulation:* Regions could game GDP statistics near the threshold. Response: McCrary density test, heaping test at 75%

## Expected Effects and Mechanisms

**If transfers create durable convergence (human capital, infrastructure story):**
- Graduating regions maintain GDP growth trajectory after 2014
- Employment composition shifts toward higher-productivity sectors
- Null or small negative effect of funding withdrawal on GDP

**If transfers create subsidy dependence:**
- Graduating regions experience GDP growth slowdown post-2014
- Employment falls, especially in construction/public sector
- GVA composition reverts toward pre-treatment structure

## Primary Specification

Y_{r,t} = α + τ · 1[GDP_{r,2013} > 75%] + f(GDP_{r,2013} - 75%) + γ_t + X_{r} + ε_{r,t}

Where:
- Y_{r,t} = GDP per capita growth (2014-2020 vs 2007-2013)
- τ = effect of graduating above 75% threshold
- f(·) = local polynomial in running variable
- γ_t = year fixed effects
- X_{r} = pre-determined covariates (population, country FE)

**Fuzzy specification:** First stage replaces the sharp 75% indicator with actual change in ERDF EUR per capita.

## Planned Robustness Checks

1. **Bandwidth sensitivity:** ±5pp, ±10pp, ±15pp, ±20pp around 75%
2. **Polynomial order:** Linear, quadratic, cubic local polynomials
3. **Donut hole:** Exclude ±1pp, ±2pp, ±3pp around threshold
4. **McCrary density test:** Check for manipulation of running variable
5. **Placebo threshold:** Test at 60%, 70%, 80%, 90% (no policy change expected)
6. **Leave-one-country-out:** Sensitivity to excluding each country
7. **Pre-treatment balance:** Covariate smoothness at threshold
8. **Multi-cutoff replication:** Test at 90% threshold (transition→more developed)

## Outcome Hierarchy

1. **Primary:** GDP per capita (PPS), % of EU27 average
2. **Mechanism test:** Employment rate, GVA by sector (structural transformation)
3. **Appendix:** Compensation of employees, cross-border spillovers

## Data Sources

| Source | Variable | Level | Coverage |
|--------|----------|-------|----------|
| Eurostat tgs00006 | GDP per capita (PPS) % EU27 | NUTS2 | 2000-2024 |
| Eurostat nama_10r_2gdp | GDP (millions EUR) | NUTS2 | 2000-2024 |
| Eurostat lfst_r_lfe2emprtn | Employment rate | NUTS2 | 1999-2024 |
| Eurostat nama_10r_3gva | GVA by NACE sector | NUTS2/3 | 2000-2022 |
| cohesiondata.ec.europa.eu | ERDF payments | NUTS2 | 2007-2023 |

## Code Structure

- `00_packages.R` — Load libraries, set themes
- `01_fetch_data.R` — Fetch from Eurostat + cohesion data APIs
- `02_clean_data.R` — Construct running variable, treatment, outcomes
- `03_main_analysis.R` — RDD estimation (rdrobust)
- `04_robustness.R` — Bandwidth, donut, placebo, leave-one-out
- `05_figures.R` — All figures from saved CSVs
- `06_tables.R` — All tables from saved CSVs
