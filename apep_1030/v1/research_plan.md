# Research Plan: Can You Put a Deposit on Recycling?

## Research Question

Do deposit return schemes (DRS) causally increase material-specific packaging waste recycling rates in Europe? How large is the effect on targeted materials (plastic, metal) relative to non-targeted materials (glass, paper, wood), and how does it evolve over time?

## Policy Background

Deposit Return Schemes require consumers to pay a refundable deposit (EUR 0.10–0.25) on single-use beverage containers. Unlike Extended Producer Responsibility (EPR) fees paid by producers or Single-Use Plastics (SUP) bans, DRS creates a direct consumer price incentive: return the container, get your money back.

13 EU/EEA countries adopted DRS between 2003 and 2025:
- Germany (2003), Estonia (2005), Croatia (2006), Lithuania (2016), Netherlands (2021), Slovakia (2022), Latvia (2022), Malta (2022), Romania (2023), Hungary (2024), Ireland (2024), Austria (2025), Poland (2025)

14 EU member states remain without DRS as of 2023 (never-treated controls). The EU Packaging and Packaging Waste Regulation (PPWR) now mandates DRS adoption by 2029 for all remaining member states.

## Identification Strategy

### Primary: Callaway-Sant'Anna Staggered DiD
- **Treatment:** Binary indicator for DRS adoption in country c at time t
- **Treated units:** 13 countries with staggered adoption (2003–2025)
- **Control units:** 14 never-treated EU member states (as of 2023 data endpoint)
- **Estimator:** Callaway & Sant'Anna (2021) group-time ATT, aggregated by event time
- **Clustering:** Country level (27 clusters)
- **Pre-trends:** Formal pre-trend test via CS framework; visual event study

### Extension: Material-Level Triple-Difference (DDD)
- **Dimension 1:** Country (DRS adopter vs non-adopter)
- **Dimension 2:** Material (targeted: plastic, metal vs untreated: glass, paper, wood)
- **Dimension 3:** Time (pre vs post adoption)
- **Key advantage:** Country × year FE absorbs infrastructure trends; Material × year FE absorbs EU-wide mandates (SUP Directive, EPR reforms)
- **Built-in placebo:** Untargeted materials processed through the same municipal collection system should show no DRS effect

### Robustness
1. Dose-response by deposit amount (EUR 0.10 Germany vs 0.25 Finland)
2. Leave-one-out (drop Germany, the dominant early adopter)
3. Bacon decomposition to diagnose TWFE contamination
4. Permutation/randomization inference given 27 clusters

## Expected Effects and Mechanisms

**Primary hypothesis:** DRS increases recycling rates for targeted materials (plastic, metal cans) by 5–15 percentage points, driven by the consumer return incentive.

**Mechanism 1 — Price incentive:** Deposit creates a direct monetary incentive for consumers to return containers rather than discard them. Higher deposits → larger effects (testable via dose-response).

**Mechanism 2 — Infrastructure:** DRS requires dedicated collection infrastructure (reverse vending machines), which may crowd out or complement existing municipal collection for non-targeted materials.

**Mechanism 3 — Behavioral spillover:** DRS may raise recycling salience, generating positive spillovers to non-targeted materials — or zero/negative spillovers if effort substitutes away from municipal recycling.

## Primary Specification

$$Y_{c,m,t} = \alpha + \beta_1(DRS_{c,t} \times Targeted_m) + \gamma_{c,t} + \delta_{m,t} + \mu_{c,m} + \epsilon_{c,m,t}$$

Where:
- $Y_{c,m,t}$: Recycling rate for country c, material m, year t
- $DRS_{c,t}$: Binary indicator for DRS adoption
- $Targeted_m$: 1 for plastic/metal, 0 for glass/paper/wood
- $\gamma_{c,t}$: Country × year FE (absorbs infrastructure trends, GDP, other policies)
- $\delta_{m,t}$: Material × year FE (absorbs EU-wide mandates like SUP)
- $\mu_{c,m}$: Country × material FE (absorbs baseline recycling differences)
- Clustering at country level

## Data Sources

1. **Eurostat cei_wm020** — Recycling rate of packaging waste by type of packaging (plastic, glass, metal, paper/cardboard, wood, total). Annual, 27+ EU countries, 2005–2023. Via `eurostat` R package, no API key.

2. **Eurostat env_waspac** — Packaging waste generation and treatment by material type and waste operation. Annual, 27+ EU countries. Tonnes generated + recycled → can compute recycling rates as robustness.

3. **DRS adoption dates** — From TOMRA/Reloop databases, EU legislation trackers, and EUR-Lex national implementation measures. Hand-verified against manifest smoke test.

## Fetch Strategy

```r
library(eurostat)
# Primary outcome
cei_wm020 <- get_eurostat("cei_wm020")
# Secondary (tonnes)
env_waspac <- get_eurostat("env_waspac")
```

No API keys needed. Fallback: direct TSV download from Eurostat bulk server.
