# Research Plan: Unblocking the River

## Research Question

Do dam removals improve downstream water quality? Specifically, does removing a dam reduce water temperature, increase dissolved oxygen, and alter turbidity at downstream monitoring stations?

## Policy Context

Dam removal is a growing policy tool in the United States, with over 100 dams removed annually and billions in federal infrastructure spending allocated to dam decommissioning. The policy rationale centers on ecological restoration — but existing economics research focuses exclusively on property value capitalization (Lewis et al. 2008; Walls & Lee 2022). No study has examined whether dam removal delivers on its core promise: measurably improved physical water quality. This gap matters because cost-benefit analyses of dam removal programs rely on assumed environmental benefits that have never been causally estimated at scale.

## Identification Strategy

**Staggered event study / difference-in-differences.** Each dam removal is a discrete, irreversible treatment event at a known location and date. We exploit the staggered timing of 1,100+ dam removals across the United States (2000–2018) using Callaway and Sant'Anna (2021) group-time ATT estimation.

- **Treatment:** Dam removal (binary, date of removal from American Rivers Database)
- **Treated units:** USGS stream gauges downstream of removed dams (within 17km)
- **Control units:** USGS stream gauges on rivers with no dam removals
- **Upstream placebo:** Gauges upstream of removed dams serve as within-event placebos

## Expected Effects and Mechanisms

1. **Water temperature:** Dams create warm-water reservoirs. Removal should *reduce* summer temperatures and increase winter temperatures (natural thermal regime restoration). Expected SDE: moderate negative for summer temperature.
2. **Dissolved oxygen:** Lower temperatures and restored flow increase DO capacity. Expected SDE: small to moderate positive.
3. **Turbidity:** Short-term spike during removal (sediment release), followed by return to baseline or reduction. Expected SDE: transient positive spike, then small negative.

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \sum_{e} \beta_e \cdot \mathbf{1}[t - G_i = e] + \varepsilon_{it}$$

where $Y_{it}$ is the water quality outcome at gauge $i$ in month $t$, $G_i$ is the removal date for the dam nearest gauge $i$, and $\alpha_i$, $\gamma_t$ are gauge and calendar-month fixed effects.

Callaway-Sant'Anna ATT aggregated across groups and event time. Clustering at the gauge level.

## Data Sources

1. **American Rivers Dam Removal Database** (Figshare): 1,590 removals since 1912; 1,103 during 2000–2018 with geocoded coordinates and dam height.
2. **USGS National Water Information System (NWIS)**: Continuous daily water quality data via `waterservices.usgs.gov` API.
   - Water temperature: parameter 00010
   - Dissolved oxygen: parameter 00300
   - Turbidity: parameter 63680
3. **National Inventory of Dams (NID)**: Dam characteristics (height, storage, purpose) for dose-response.

## Fetch Strategy

1. Download American Rivers CSV from Figshare
2. Query USGS NWIS API for daily values at all stream gauges in states with >30 dam removals (PA, CA, WI, MI, OR, OH, MA, MN)
3. Spatial match: assign each gauge to nearest dam removal within 17km downstream
4. Construct monthly panel of gauge-level water quality outcomes

## Key Risks

- **Gauge coverage:** Not all dams will have a nearby USGS gauge. Sample may be smaller than 1,100.
- **Seasonality:** Water quality is highly seasonal; must use calendar-month FE or within-month variation.
- **Sediment pulse:** Short-term turbidity spike during removal could complicate interpretation; handle with event-time decomposition.
