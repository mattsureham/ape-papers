# Research Plan: Policy Leakage Across Borders — Canada's Cannabis Legalization and US Border County Drug Enforcement

## Research Question

Did Canada's nationwide cannabis legalization (October 17, 2018) generate measurable spillovers in US border county drug-market enforcement activity, and did the COVID-era border closure (March 2020–November 2021) attenuate those spillovers?

**Important scope clarification:** We measure spillovers in *recorded drug enforcement activity* (arrests), not in underlying crime rates. UCR arrest data captures enforcement encounters at the drug-market margin, not social harm.

## Conceptual Framework

### Theory and mechanism
Cross-border drug policy asymmetry creates arbitrage incentives. When cannabis becomes legal in Canada but remains federally illegal in the United States, three channels could increase drug enforcement activity in US border counties:

1. **Supply channel:** Cheaper, legal Canadian cannabis may be smuggled southward, increasing the stock of illicit cannabis in border areas and raising the frequency of law enforcement encounters.
2. **Demand channel:** US residents near the border may purchase cannabis in Canada and transport it back, increasing cross-border drug possession encounters.
3. **Enforcement channel:** Federal and state law enforcement may intensify border-area drug operations in response to the perceived threat of cross-border trafficking.

### Expected sign
**Positive.** Border counties should see increased drug-related arrests relative to interior counties after October 2018. CBP marijuana seizures at the northern border rose ~75% post-legalization (1,259 kg to 4,864 kg), suggesting a real supply-side response.

### Three-regime structure (the paper's key asset)
Rather than a simple pre/post design, we exploit three distinct border regimes:

| Regime | Period | Border Status | Prediction |
|--------|--------|---------------|------------|
| **Pre-legalization** | Jan 2014 – Sep 2018 | Open | Baseline |
| **Post-legalization, open border** | Oct 2018 – Feb 2020 | Open | Spillovers should appear |
| **COVID border closure** | Mar 2020 – Nov 2021 | Closed to non-essential travel | Spillovers should attenuate |
| **Post-reopening** | Dec 2021 – Dec 2023 | Open (phased) | Spillovers should return if mechanism is cross-border traffic |

If drug enforcement spillovers rise after legalization, weaken during border closure, and return upon reopening, the evidence for cross-border policy leakage is substantially stronger than a single-break DiD.

### Where effect should concentrate (heterogeneity predictions)
- **Land ports of entry:** Counties with major land border crossings (e.g., Blaine/Whatcom WA, Buffalo/Erie NY, Detroit/Wayne MI) should show larger effects than counties with minimal crossing infrastructure.
- **State retail access:** Border counties in states with operational retail cannabis (WA by Oct 2018) may show smaller effects since the legal differential is partially closed. Border counties in prohibition states (ID, MT, ND, MN, OH, PA) should show larger effects. This is secondary heterogeneity, not part of the main identification.

## Identification Strategy

### Method: Difference-in-Differences with three-regime interactions

**Primary design:** Compare drug arrest trends in high-crossing-exposure border counties versus all other counties in the same 12 border states, using continuous crossing exposure as the treatment measure, with separate post-period interactions for the open-border, closed-border, and reopened-border regimes.

**Treatment group:** US counties containing or adjacent to an active land/bridge/ferry port of entry on the Canadian border. Treatment intensity = continuous measure based on pre-2018 cross-border traffic volume at the nearest port of entry (from BTS Border Crossing data). Counties that are geographically adjacent to Canada but have no crossing infrastructure are not directly exposed to the cross-border access mechanism and serve as useful low-exposure comparisons.

**Control group:** All non-border counties within the same 12 border states (WA, ID, MT, ND, MN, MI, OH, PA, NY, VT, NH, ME). County FE + state-by-quarter FE absorbs state-level policy changes and enforcement trends. No matching in the main specification — matching is robustness only to avoid regression-to-the-mean attacks.

### Heterogeneity (secondary, not baseline)
US state retail cannabis access timing as heterogeneity dimension. Note: "legalization" dates do not capture the relevant market margin. WA had retail from July 2014. ME legalized 2016 but retail only October 2020. VT legalized possession July 2018 but retail October 2022. MI legalized November 2018 but retail December 2019. The relevant differential is retail access, not statutory legalization. We test whether border counties in states with retail access show smaller enforcement spillovers, but this is secondary heterogeneity, not the main identification.

### Model equation

**Primary specification:**

$$Y_{ct} = \alpha_c + \gamma_{st} + \beta_1 \cdot \text{Exposure}_c \times \text{PostLegal}_t + \beta_2 \cdot \text{Exposure}_c \times \text{CovidClosed}_t + \beta_3 \cdot \text{Exposure}_c \times \text{PostReopen}_t + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: drug arrests per reporting population (NOT total county population) in county $c$, quarter $t$
- $\alpha_c$: county fixed effects
- $\gamma_{st}$: state × year-quarter fixed effects (absorbs state-level policy changes and enforcement trends)
- $\text{Exposure}_c$: pre-2018 crossing exposure constructed from nearby ports of entry, with nearest-port traffic volume as the baseline implementation (log, standardized). Binary border indicator as robustness. Multiple-port aggregation explored if data suggest it.
- PostLegal: Oct 2018 – Feb 2020
- CovidClosed: Mar 2020 – Nov 2021
- PostReopen: Dec 2021 onward

**Prediction:** $\beta_1 > 0$ (spillovers), $\beta_2 < \beta_1$ (attenuated during closure), $\beta_3 > 0$ (returns on reopening).

**Critical measurement note:** Arrest rates must be normalized by *reporting population* (the population covered by agencies actually submitting data in that period), NOT total county population. This addresses the main measurement threat from UCR reporting inconsistencies and NIBRS transition.

**Event study:**

$$Y_{ct} = \alpha_c + \gamma_{st} + \sum_{k \neq -1} \delta_k \cdot \text{Exposure}_c \times \mathbb{1}[t = k] + \varepsilon_{ct}$$

With quarterly event-time indicators relative to 2018Q3 (last pre-treatment quarter). Presentation: plot $\delta_k$ for continuous exposure, and separately show event studies for exposure terciles/quartiles to make the dynamic pattern visually legible.

## Primary Specification

- **Outcome variable:** Drug/narcotic-related arrests per reporting population (UCR)
- **Sample:** All counties in 12 border states with consistent UCR reporting coverage (≥90% of quarters with positive reporting population). ~70 border + ~500+ interior counties.
- **Unit of observation:** County × quarter
- **Clustering:** State level (12 clusters — wild cluster bootstrap for conservative inference)
- **Population weights:** Reporting-population weighted
- **Constant-coverage robustness:** Restrict to agencies that report in every quarter of the sample period

## Data Sources

| Source | Table/File | Variables | Access |
|--------|-----------|-----------|--------|
| UCR Arrests | Kaplan Concatenated (ICPSR 102263) | Drug arrests by agency, county, month | ICPSR (free registration) |
| UCR Offenses Known | Kaplan Concatenated (ICPSR 100707) | Property crime, larceny, etc. by agency | ICPSR (free registration) |
| County population | Census intercensal estimates | Annual population for normalization | Census API |
| Border county IDs | Census TIGER/Line | County FIPS + border state identification | Census |
| Cannabis legalization | PDAPS/RAND | State-level legalization status + dates | Manual construction |
| Border crossing data | BTS Border Crossing/Entry | Monthly crossing volumes by port, vehicle/passenger type | BTS website (free) |
| Land ports of entry | CBP | Crossing locations | CBP website |

## Where Mechanism Should Operate

**Directly affected:** Counties adjacent to the Canadian border where cross-border traffic is the channel for cannabis flow. The effect should scale with:
- Proximity to land ports of entry
- Pre-existing cross-border traffic volume
- US state prohibition status (legal differential)

**Not directly affected:**
- Interior counties in the same 12 states — share state-level policies and enforcement trends but lack cross-border access channel
- Non-drug enforcement activity in border counties — placebo
- Border counties with no port of entry — share border geography but lack the cross-border access mechanism

## Planned Robustness Checks

1. **Alternative treatment specifications:** (a) binary border indicator instead of continuous exposure, (b) high-exposure (above-median crossing volume) indicator, (c) distance-to-border continuous measure
2. **Temporal aggregation:** monthly vs. quarterly (to address thin counts)
3. **Outcome variants:** (a) cannabis-specific arrests if identifiable, (b) total drug arrests, (c) drug arrest rate changes (logs and levels)
4. **Agency coverage correction:** restrict to agencies with consistent reporting coverage (>90% months reporting) to avoid NIBRS transition artifacts
5. **Weighted vs. unweighted:** population-weighted and unweighted specifications
6. **Permutation inference:** randomize border-county assignment across states

## Planned Validity Checks

1. **Parallel trends:** Event study with ≥16 pre-treatment quarters (2014Q1–2018Q3). Flat pre-trend coefficients required.
2. **Placebo outcomes:** (a) Fraud/embezzlement arrests — should not respond to cross-border cannabis, (b) Assault/violent crime — no expected mechanism, (c) DUI arrests — could go either way (substitution from alcohol)
3. **Fake-date placebos:** Re-estimate the main specification with placebo treatment dates (e.g., October 2015, October 2016) — should show no effect
4. **Low-traffic border county placebo:** Border counties with no port of entry — share border geography but lack the cross-border access mechanism
5. **UCR reporting consistency:** Document and control for agencies transitioning from SRS to NIBRS during sample period. Constant-coverage subsample.
6. **Border closure validation:** Verify that the March 2020 border closure actually reduced cross-border traffic (BTS Border Crossing data on passenger/vehicle volumes)

## Kill Conditions

- If pre-trends are not flat (significant divergence in drug arrests between border and interior counties pre-2018)
- If UCR reporting-population coverage is unstable or too thin in border counties to construct reliable rates
- If there is no discernible break at October 2018 in the event study (visually and economically, not just p-value gating)
- If the three-regime pattern does not hold (no attenuation during COVID closure) — note: this is supporting evidence, not a hard mechanical kill. Illicit flows may not track legal crossings one-for-one.

## Key References to Cite

- Dragone et al. (2019) — US internal cannabis border spillovers
- Hansen et al. (2020) — Cannabis and crime at US state borders
- Adda et al. (2014) — Cannabis decriminalization and crime in London
- Gavrilova et al. (2019) — Medical marijuana and crime
- Anderson et al. (2013) — Recreational marijuana and traffic fatalities
- Dills et al. (2021) — Cannabis legalization and crime overview
