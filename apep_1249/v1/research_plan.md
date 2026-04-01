# Research Plan: The Carbon Boomerang

## Research Question
Did Australia's two-year carbon pricing mechanism (July 2012–July 2014) reduce electricity-sector employment in high-carbon-intensity states, and did the repeal reverse these effects?

## Identification Strategy
**Continuous-treatment DiD** exploiting dramatic cross-state variation in coal's share of electricity generation as predetermined treatment intensity.

- **Treatment intensity:** Baseline (2010-11) coal share of electricity generation (ranges from ~2% in Tasmania to ~82% in NSW)
- **Time variation:** Three periods — pre (2008Q1-2012Q2), carbon tax (2012Q3-2014Q2), post-repeal (2014Q3-2017Q4)
- **Key identifying assumption:** Absent the carbon tax, employment trends in electricity-sector employment would have evolved similarly across states with different coal shares (conditional parallel trends in levels/growth)
- **Symmetric shock advantage:** The repeal provides a built-in falsification test. If the carbon tax caused employment declines, repeal should reverse them. If both introduction and repeal effects are identified, this dramatically strengthens causal inference.

## Expected Effects and Mechanisms
1. **Primary:** Carbon tax → higher electricity generation costs in coal-intensive states → reduced coal generation → reduced coal-related employment
2. **Reversal:** Tax repeal → cost advantage restored → employment recovery (degree of recovery indicates hysteresis vs. full reversibility)
3. **Composition:** Net employment near zero if renewables employment growth offsets coal losses
4. **Heterogeneity:** Brown coal (lignite) in Victoria more carbon-intensive than black coal in NSW → stronger bite per tonne

## Primary Specification
$$Y_{st} = \alpha_s + \gamma_t + \beta_1 \cdot \text{CoalShare}_s \times \text{TaxPeriod}_t + \beta_2 \cdot \text{CoalShare}_s \times \text{PostRepeal}_t + X_{st}'\delta + \varepsilon_{st}$$

Where:
- $Y_{st}$: log electricity-sector employment in state $s$, quarter $t$
- $\text{CoalShare}_s$: baseline coal share of electricity generation (2010-11)
- $\text{TaxPeriod}_t$: indicator for Q3 2012–Q2 2014
- $\text{PostRepeal}_t$: indicator for Q3 2014 onward
- $\alpha_s, \gamma_t$: state and quarter fixed effects
- SEs: wild cluster bootstrap (8 clusters)

$\beta_1 < 0$ (tax reduces employment), $\beta_2 \approx 0$ (full reversal) or $\beta_2 < 0$ (hysteresis).

## Event Study Specification
$$Y_{st} = \alpha_s + \gamma_t + \sum_{k \neq -1} \delta_k \cdot \text{CoalShare}_s \times \mathbb{1}[t = k] + \varepsilon_{st}$$

Event time centered on Q3 2012 (carbon tax effective). Pre-trend coefficients ($k < 0$) should be zero.

## Data Sources
1. **ABS Labour Force Survey** (Cat 6291.0.55.003): State × industry × quarter employment, public SDMX API
2. **AEMO generation data:** Electricity generation by fuel type and state, for constructing coal share
3. **ABS Energy Account** (Cat 4604.0): State-level generation mix for treatment intensity

## Robustness
1. Placebo outcomes: manufacturing, mining (non-electricity) employment
2. Placebo treatment: use states with intermediate coal exposure as controls
3. Wild cluster bootstrap p-values (Cameron, Gelbach, Miller 2008)
4. Randomization inference permuting treatment intensity across states
5. Alternative treatment windows (excluding transition quarters)
6. State-specific linear trends
