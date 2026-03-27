# Research Plan: Banning the Straw — The Substitution Illusion in EU Single-Use Plastics Regulation

## Research Question

Does banning specific single-use plastic products under EU Directive 2019/904 reduce total plastic packaging waste, or does it merely shift waste composition toward paper/cardboard alternatives — a "substitution illusion"?

## Policy Background

The EU Single-Use Plastics (SUP) Directive (2019/904), adopted June 2019, bans specific items: cutlery, plates, straws, stirrers, and EPS food containers. Member states transposed the directive at different times:
- Slovakia: Dec 2019 (early mover)
- Germany: Nov 2020
- Multiple states: Jul 2021 (on-deadline)
- Spain: Apr 2022
- Poland: Apr 2023
- Belgium: Jun 2024 (latest)

This 4.5-year staggered transposition window across 22+ countries creates ideal conditions for a Callaway-Sant'Anna staggered DiD design.

## Identification Strategy

**Estimator:** Callaway-Sant'Anna (2021) staggered difference-in-differences with not-yet-treated and never-treated as comparison groups.

**Treatment:** National transposition date of Directive 2019/904, coded from CELLAR SPARQL entry-into-force dates.

**Outcomes:**
1. Primary: Plastic packaging waste generation (tonnes per capita), Eurostat env_waspac
2. Secondary: Paper/cardboard packaging waste (substitution channel)
3. Substitution ratio: Plastic share of total packaging waste
4. Trade: HS 3924 (plastic tableware) imports via Comtrade

**Built-in placebos:**
- Glass packaging waste (not targeted by SUP) — should show no effect
- Metal packaging waste (not targeted) — should show no effect
- These provide mechanism-matched placebos: same data source, same reporting methodology, same countries, but no treatment

**Pre-treatment periods:** 2006–2019 (13 years) for packaging waste data.

## Expected Effects and Mechanisms

- **If bans work as intended:** Plastic packaging waste falls, total packaging waste unchanged or falls
- **If substitution dominates:** Plastic falls but paper/cardboard rises by similar magnitude — total waste unchanged
- **If compliance is weak:** No detectable effect on any material

The key empirical test is the cross-material pattern: a ban that reduces plastic but increases paper by a comparable amount reveals the substitution illusion.

## Primary Specification

$$Y_{it} = \alpha_i + \lambda_t + \sum_g \beta_g \cdot \mathbb{1}[G_i = g, t \geq g] + X_{it}\gamma + \varepsilon_{it}$$

Where $Y_{it}$ is packaging waste (tonnes per capita) for country $i$ in year $t$, $G_i$ is the treatment cohort (transposition year), and $X_{it}$ includes GDP per capita and population as controls.

Callaway-Sant'Anna provides cohort-specific ATT(g,t) estimates and aggregated event-study plots.

## Data Source and Fetch Strategy

1. **Eurostat env_waspac:** Packaging waste by material (plastic, paper, glass, metal, wood), 27 countries, 2006–2023. Via `eurostat` R package.
2. **CELLAR SPARQL:** SUP Directive transposition dates from national implementation measures. Via `eurlex` R package.
3. **Eurostat controls:** GDP per capita (nama_10_gdp), population (demo_pjan).
4. **Comtrade (secondary):** HS 3924 (plastic tableware) and HS 4819 (paper containers) trade flows.

## Key Risks

1. **Annual data granularity:** env_waspac is annual — cannot identify within-year treatment timing precisely. Countries transposing mid-year will be coded to the following year.
2. **Reporting lags:** Some countries may report packaging waste with 1-2 year delays.
3. **COVID confound:** 2020-2021 saw unusual consumption patterns. The DiD design differences this out across countries, and the DDD with untreated materials provides additional protection.
4. **Small sample:** 27 countries × 18 years = 486 observations. Callaway-Sant'Anna with clustered SEs at the country level.
