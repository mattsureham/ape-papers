# Research Plan: Riding the Rails of Liberalization

## Research Question

What is the causal effect of the EU's Fourth Railway Package — which forced open domestic rail passenger markets — on rail fares across European member states?

## Policy Background

Directive 2016/2370 of the Fourth Railway Package grants any EU-licensed railway undertaking the right to operate domestic passenger services in any member state. Regulation 2016/2338 mandates competitive tendering for Public Service Obligation (PSO) rail contracts from December 2023. Eight member states transposed early (by June 2019): Bulgaria, Finland, France, Greece, Italy, Netherlands, Romania, and Slovenia. The remaining ~17 transposed later (June–October 2020). Pre-existing market openness varied substantially: Sweden and Czechia had open access since the 2000s, while France, Spain, and Italy maintained near-monopoly structures.

## Identification Strategy

**Staggered difference-in-differences** exploiting the two-wave transposition timeline:
- **Early transposers** (8 countries, by June 2019): BG, FI, FR, EL, IT, NL, RO, SI
- **Late transposers** (~17 countries, 2020): remaining EU members

**Estimator:** Callaway & Sant'Anna (2021) with not-yet-treated as control group. This avoids the well-documented bias from two-way fixed effects in staggered settings.

**Built-in placebo sectors:** Air transport fares (HICP CP0733) and road transport fares (HICP CP0732) within the same countries should NOT be affected by rail-specific liberalization. Parallel effects in these sectors would suggest confounding from general transport price trends rather than the railway package.

**Treatment intensity:** Heterogeneity by pre-reform incumbent market share from RMMS data. Countries with near-monopoly incumbents (France, Spain) should see larger effects than countries with pre-existing competition (Sweden, Czechia).

**COVID challenge:** Late transposers (2020) overlap with COVID. Primary strategy: (1) triple-difference using rail vs. air/road within country-time to absorb COVID shocks common to all transport; (2) robustness using only early transposers (2019) with pre-COVID post-period; (3) event-study plots to visually assess whether effects emerge at transposition or at COVID onset.

## Expected Effects and Mechanisms

**Primary hypothesis:** Rail fare indices decline following liberalization, as market entry and competitive tendering pressure incumbents on price.

**Magnitude prior:** The EC's 2024 study found Italian HS fares fell 31% and Czech fares 44-46% on competitive routes. These are likely upper bounds (selected competitive routes). Country-average HICP effects should be smaller since many routes remain PSO-protected.

**Mechanism channels:**
1. Direct entry on high-traffic routes (open access)
2. Competitive tendering for PSO contracts (Regulation 2016/2338)
3. Incumbent strategic response (preemptive fare reductions)

**Null hypothesis:** If liberalization has no effect on average fares (e.g., entry limited to high-speed routes, PSO contracts unchanged), this is itself an important finding — suggesting that de jure market opening does not translate to de facto consumer price benefits.

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot D_{it} + X_{it}'\delta + \varepsilon_{it}$$

where $Y_{it}$ is the log HICP railway fare index for country $i$ in month $t$, $D_{it}$ is a post-transposition indicator, $\alpha_i$ and $\gamma_t$ are country and time fixed effects, and $X_{it}$ are time-varying controls (GDP per capita, oil prices). Standard errors clustered at the country level.

**Callaway-Sant'Anna:** Group-time ATTs estimated separately for each cohort (early 2019, late 2020), then aggregated.

## Data Sources and Fetch Strategy

| Variable | Dataset | Source | Frequency | Coverage |
|----------|---------|--------|-----------|----------|
| Rail fares | HICP CP0731 | Eurostat `prc_hicp_midx` | Monthly | 25 countries, 1996–2025 |
| Air fares (placebo) | HICP CP0733 | Eurostat `prc_hicp_midx` | Monthly | 25 countries, 1996–2025 |
| Road fares (placebo) | HICP CP0732 | Eurostat `prc_hicp_midx` | Monthly | 25 countries, 1996–2025 |
| Rail passengers | `rail_pa_quartal` | Eurostat | Quarterly | 25 countries, 2004–2025 |
| Transposition dates | CELLAR SPARQL | EUR-Lex | — | Directive 2016/2370 |
| GDP per capita | `nama_10_pc` | Eurostat | Annual | All EU |

**Fetch order:**
1. HICP monthly indices for CP0731, CP0732, CP0733 via `eurostat` R package
2. Quarterly rail passenger-km via `eurostat` R package
3. Transposition dates from CELLAR SPARQL / idea manifest (confirmed: 8 early, 17 late)
4. GDP per capita controls

## Robustness Checks

1. **Placebo sectors:** Air (CP0733) and road (CP0732) transport fares
2. **Pre-trend test:** Event-study coefficients for 24+ months pre-treatment
3. **COVID robustness:** Restrict to early transposers with pre-COVID post-period (Jul 2019–Feb 2020)
4. **Treatment intensity:** Interact with pre-reform incumbent market share
5. **Bacon decomposition:** Verify TWFE bias direction
6. **Alternative clustering:** Wild cluster bootstrap with 25 clusters
