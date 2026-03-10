# Initial Research Plan: Walls Without Bricks

## Research Question
Do temporary Schengen border control reintroductions (since September 2015) reduce economic activity in affected border regions, and are the integration gains of Schengen reversible?

## Identification Strategy
**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021) heterogeneity-robust estimator.

**Treatment:** NUTS3 regions lying directly on a Schengen internal border segment where temporary border controls were reintroduced. Treatment is defined at the border-segment × cohort level.

**Treatment cohorts (6+):**
1. Germany-Austria border (Sep 13, 2015)
2. Austria-Hungary border (Sep 16, 2015)
3. Austria-Slovenia border (Sep 16, 2015)
4. France — all borders (Nov 13, 2015)
5. Sweden-Denmark / Øresund (Nov 12, 2015)
6. Denmark-Germany (Jan 4, 2016)
7. Norway-ferry routes (Nov 26, 2015)

**Control groups:**
- (a) NUTS3 border regions on unaffected Schengen internal borders (e.g., Germany-Netherlands, Germany-Belgium, Austria-Italy, Austria-Liechtenstein)
- (b) Interior NUTS3 regions in the same countries (more distant from any border)

**Key threat:** The refugee crisis of 2015 may independently affect border regions. We address this via:
- Placebo test on non-migration-route borders (e.g., Germany-Netherlands shares no major migration route but is geographically adjacent)
- Triple-difference exploiting migration-route intensity across border segments

## Exposure Alignment
- **Who is treated?** People and firms in NUTS3 regions adjacent to borders where controls were reimposed
- **Primary estimand:** ATT on GDP per capita and employment in treated border NUTS3 regions
- **Placebo population:** NUTS3 border regions on unaffected Schengen borders (same border-region characteristics, no control shock)
- **Design:** Staggered DiD with 6+ cohorts

## Expected Effects and Mechanisms
**Primary hypothesis:** Border controls increase transaction costs (waiting times, ID checks, unpredictability), reducing cross-border commuting, trade, and tourism → lower GDP and employment in border regions.

**Mechanisms to test:**
1. **Cross-border commuting channel:** If controls deter commuters, employment in border regions should fall, especially in sectors reliant on cross-border labor (manufacturing, healthcare)
2. **Trade friction channel:** Road freight volumes should decline at controlled borders
3. **Tourism channel:** Tourism overnight stays should fall in border-region tourism destinations

**Hysteresis hypothesis:** If Schengen integration created agglomeration economies (specialized border-region firms, cross-border supply chains), controls may have smaller effects than the original opening because the economic structure has adapted. Alternatively, if integration gains rest on low transaction costs, even temporary controls can cause persistent damage.

## Primary Specification
$$Y_{i,t} = \alpha_i + \delta_t + \beta \cdot \text{BorderControl}_{i,t} + \varepsilon_{i,t}$$

Using Callaway-Sant'Anna (2021):
- Group-time ATT: $ATT(g,t)$ for each cohort $g$ and time $t$
- Aggregation: simple average across groups and time
- Not-yet-treated as comparison group
- Outcome: log GDP per capita (NUTS3)

## Power Assessment
- **Pre-treatment periods:** 12 years (2003-2014)
- **Treated NUTS3 regions:** ~80-100 across 6 border segments
- **Post-treatment periods:** Up to 9 years (2015-2023, data permitting)
- **MDE:** Effects >1-2% of GDP should be detectable given the panel length and number of treated units. With ~80 treated units × 22 years and within-unit variation, statistical power should be adequate for moderate effects.

## Planned Robustness Checks
1. **Callaway-Sant'Anna event study** — dynamic effects and pre-trend visualization
2. **TWFE comparison** — standard two-way fixed effects (interpret cautiously given staggered treatment)
3. **Leave-one-segment-out** — exclude each border segment to test sensitivity
4. **Randomization inference** — permute treatment assignment across border segments
5. **Alternative control groups** — interior regions only, border regions only, matched border regions
6. **Placebo borders** — test for effects at unaffected Schengen internal borders
7. **Placebo timing** — test for effects using fake treatment dates (2010, 2012)
8. **Wild cluster bootstrap** — cluster at the border-segment level
9. **Rambachan-Roth (HonestDiD)** — sensitivity to violations of parallel trends
10. **COVID placebo** — truncate sample at 2019 to avoid confounding with COVID-era border closures

## Data Sources
- **NUTS3 GDP:** Eurostat `nama_10r_3gdp` (2003-2024)
- **NUTS3 GVA by sector:** Eurostat `nama_10r_3gva` (2003-2022)
- **NUTS3 employment:** Eurostat `nama_10r_3empers` (2003-2022)
- **Road freight:** Eurostat `road_go_na_rl3g`
- **Cross-border commuters:** Eurostat `lfst_r_lfe2ecomm`
- **Tourism nights:** Eurostat `tour_occ_nin2`
- **NUTS3 shapefiles:** Eurostat GISCO for border region identification

## Outcome Hierarchy
1. **Primary:** Log GDP per capita (NUTS3)
2. **Secondary:** Log employment (NUTS3)
3. **Mechanism:** GVA by sector (trade/transport/accommodation shares), road freight, commuter flows, tourism nights
