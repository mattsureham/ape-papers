# Initial Research Plan: Technology Standards as Industrial Policy

## Research Question

Do technology-based environmental standards reduce industrial pollution? We evaluate the EU Industrial Emissions Directive's (IED) Best Available Techniques (BAT) conclusions — the largest technology-standard regulation in the world, governing 52,000 industrial installations — using the staggered adoption of sector-specific BAT conclusions between 2012 and 2019. We ask: (1) did BAT conclusions reduce facility-level pollutant releases? (2) at what cost to sector-level economic output? and (3) which mechanism dominates — technology adoption or production curtailment?

## Identification Strategy

### Treatment
BAT conclusions are adopted through the "Sevilla Process" — a technical review conducted by the European IPPC Bureau. Upon publication in the Official Journal, all IED-regulated facilities in that sector must comply within 4 years. Crucially, the staggering across sectors follows the inherited BREF (BAT Reference Document) review schedule, determined by the order of pre-IED technical review initiation in the 1990s-2000s — **not** by which sectors were most polluting or by political considerations.

### Sector Cohorts (14+ sectors, 2012-2019)
| Sector | BAT Adopted | Compliance Deadline |
|--------|-------------|---------------------|
| Iron and Steel | Mar 2012 | Mar 2016 |
| Glass Manufacturing | Mar 2012 | Mar 2016 |
| Cement, Lime, MgO | Apr 2013 | Apr 2017 |
| Chlor-Alkali | Dec 2013 | Dec 2017 |
| Tanning of Hides | Feb 2013 | Feb 2017 |
| Pulp and Paper | Sep 2014 | Sep 2018 |
| Refining | Oct 2014 | Oct 2018 |
| Common Waste Water/Gas | Jun 2016 | Jun 2020 |
| Non-Ferrous Metals | Jun 2016 | Jun 2020 |
| Large Combustion Plants | Aug 2017 | Aug 2021 |
| Waste Treatment | Aug 2018 | Aug 2022 |
| Food, Drink, Milk | Dec 2019 | Dec 2023 |
| Waste Incineration | Dec 2019 | Dec 2023 |
| Surface Treatment (Solvents) | Dec 2020 | Dec 2024 |

### Estimator
Staggered DiD with Sun and Abraham (2021) interaction-weighted estimator. Not-yet-treated sectors serve as the comparison group. Callaway and Sant'Anna (2021) as robustness.

### Identifying Assumption
Emission trends are parallel across sectors absent BAT conclusions. We test this with:
1. Pre-treatment event study showing flat pre-trends in the 3-5 years before BAT adoption
2. Randomization inference permuting treatment timing across sectors

## Expected Effects and Mechanisms

### Main Hypothesis
BAT conclusions reduce facility-level pollutant releases. Expected effect: 10-30% reduction in key pollutants (NOx, SOx, PM10) within 4 years of BAT adoption. Smaller or null for CO2 (covered by EU ETS).

### Mechanism Channel
**Technology adoption** (primary channel): BAT conclusions mandate specific technologies or emission limit values, forcing investment in cleaner processes.

**Testable prediction:** If technology adoption drives the effect, we should see:
- Emissions fall while output stays constant or rises (efficiency gain)
- Investment increases in treated sectors (capital expenditure on abatement)
- Effects concentrate in facilities furthest from BAT standards (most room for improvement)

**Alternative: Production curtailment** — if BAT conclusions simply shrink the sector:
- Emissions fall but so does output, employment, and investment
- Facility closures increase in treated sectors

### Built-in Placebo
Sub-IED-threshold facilities in the same sector are NOT subject to BAT conclusions. If our DiD is valid, these facilities should show no emission change at the BAT adoption date.

## Primary Specification

```
Y_{i,s,c,t} = β * Post_BAT_{s,t} + α_i + δ_{c,t} + ε_{i,s,c,t}
```

Where:
- Y = log(pollutant releases) for facility i in sector s, country c, year t
- Post_BAT = 1 after sector s's BAT conclusion compliance deadline
- α_i = facility fixed effects
- δ_{c,t} = country × year fixed effects (absorb macro shocks and national regulations)
- Clustered SEs at sector level (14 clusters → wild cluster bootstrap + RI)

## Exposure Alignment (DiD)

- **Who is treated:** IED-regulated facilities (above capacity thresholds) in sectors where BAT conclusions are adopted
- **Primary estimand:** ATT of BAT conclusion on facility-level pollutant releases
- **Placebo/control:** (1) Not-yet-treated sectors, (2) Sub-threshold facilities in same sector (triple-diff)
- **Design:** Staggered DiD with Sun-Abraham; DDD for sub-threshold placebo

## Power Assessment

- Pre-treatment periods: 5-10 years (E-PRTR data from 2007)
- Treated clusters: 14+ sector cohorts
- Post-treatment periods: 3-7 years per cohort
- N: ~34,000 facilities × 16 years ≈ 544,000 facility-years
- Cluster count concern: 14 sectors is borderline → use wild cluster bootstrap and RI
- MDE: With N > 500K and facility FEs, we should detect effects of ~5% or larger

## Planned Robustness Checks

1. **Pre-trends test:** Event study with leads up to -5 years
2. **Alternative estimators:** CS-DiD, Borusyak et al. (2024) imputation
3. **Leave-one-sector-out:** Verify no single sector drives results
4. **Triple-difference:** IED vs sub-threshold facilities
5. **Randomization inference:** Permute BAT adoption dates across sectors
6. **Alternative clustering:** Country × sector, wild cluster bootstrap
7. **Dose-response:** BAT stringency (tighter limits → larger reductions?)
8. **CO2 placebo:** CO2 covered by ETS, not primarily by IED BAT → should show smaller/null IED effect
9. **Pollution composition:** Effects on local pollutants (NOx, SOx, PM) vs global (CO2)

## Data Sources

1. **E-PRTR / EEA Industrial Reporting:** Facility-level pollutant releases (2007-2022), 854K+ observations
2. **Eurostat SBS (sbs_na_ind_r2):** Sector-level turnover, employment, value added, investment by NACE
3. **BAT conclusion dates:** Manually coded from Official Journal of the EU (Commission Implementing Decisions)

## Outcome Hierarchy

1. **Primary:** Log(facility NOx releases to air) — most common regulated pollutant
2. **Secondary:** Log(SOx), Log(PM10), Log(heavy metals aggregate)
3. **Placebo outcome:** Log(CO2) — should show smaller effect (ETS, not BAT, is main driver)
4. **Economic outcomes:** Sector-level turnover, employment, investment (Eurostat SBS)
