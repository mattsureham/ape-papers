# Research Plan: When the Mine Money Stops

## Research Question

Does the abrupt elimination of Mexico's Fondo Minero in November 2020 — which stripped ~277 mining municipalities of billions of pesos in earmarked resource revenue — increase crime and degrade local public goods provision?

## Identification Strategy

**Standard two-group difference-in-differences.**

- **Treatment group:** ~277 municipalities that received Fondo Minero allocations (2014–2019)
- **Control group:** ~2,200 non-mining municipalities that never received fund allocations
- **Treatment timing:** November 6, 2020 (decree extinguishing 108 public trusts)
- **Pre-period:** 2015–2019 (5 years)
- **Post-period:** 2021–2025 (5 years)

The fund's elimination was driven by AMLO's ideological opposition to autonomous trusts ("corruption black holes") and desire to centralize federal spending. It was not triggered by trends in mining municipal outcomes — a textbook exogenous fiscal shock.

## Expected Effects and Mechanisms

**Primary hypothesis:** Mining municipalities experience increased crime after losing dedicated fiscal transfers.

**Mechanism:** The Fondo Minero funded local infrastructure, social programs, and public safety in mining communities. Losing this revenue reduces local public goods provision, increasing the opportunity cost of legitimate activity and reducing deterrence capacity.

**Expected direction:** Positive effect on crime (more crime post-elimination in mining municipalities). Effect should be larger for:
- Municipalities that received larger per-capita allocations (dose-response)
- Property crimes and extortion (economic channels) vs. domestic violence (less fiscal)

**Null result interpretation:** If null, this suggests either (a) fund resources were captured by elites rather than providing public goods, or (b) state/federal transfers substituted for the lost revenue.

## Primary Specification

$$Y_{mt} = \alpha + \beta \cdot \text{Mining}_m \times \text{Post}_t + \gamma_m + \delta_t + \epsilon_{mt}$$

Where:
- $Y_{mt}$: crime rate per 100,000 in municipality $m$, year $t$
- $\text{Mining}_m$: indicator for Fondo Minero recipient municipality
- $\text{Post}_t$: indicator for years ≥ 2021
- $\gamma_m$: municipality fixed effects
- $\delta_t$: year fixed effects
- Clustering: state level (~32 clusters)

**Event study:** Estimate year-by-year treatment effects relative to 2019 (last full pre-treatment year).

## Data Sources

1. **SESNSP Municipal Crime Data** (primary outcome)
   - Source: GitHub mirror (`lapanquecita/incidencia-delictiva`)
   - Coverage: 2,489 municipalities, 2015–2026, 519,649 rows
   - Variables: municipality code, year, crime type, count
   - Crime types: Homicidio doloso, Extorsión, Robo (various), Violencia familiar

2. **Fondo Minero Municipality List** (treatment assignment)
   - Source: SEDATU distribution reports on gob.mx
   - Coverage: 277 municipalities across 27 states, with allocation amounts (2014–2019)
   - Alternative: Mining municipalities identified via INEGI mining production data or Servicio Geológico Mexicano

3. **Population Data** (for rates)
   - Source: CONAPO population projections or INEGI Census 2020 intercensal
   - Coverage: All municipalities, annual estimates

## Exposure Alignment

Treatment is defined at the municipality level, matching the level at which the Fondo Minero allocated resources and the level at which SESNSP reports crime. Mining municipalities (those receiving Fondo Minero allocations) are directly exposed to the fiscal shock: they lose dedicated infrastructure and social spending revenue. Non-mining municipalities serve as controls because they never received Fondo Minero allocations and thus experience no direct fiscal change from its elimination. The treatment and outcome units are aligned — both are municipalities — avoiding the mismatch problems that arise when treatment varies at a coarser level than the outcome.

## Robustness Checks

1. **Event study for pre-trends** — Year-by-year coefficients should be zero pre-2020
2. **Dose-response** — Interact treatment with pre-period allocation amounts
3. **Crime-type heterogeneity** — Property crimes vs. violent crimes vs. domestic violence
4. **COVID control** — Include COVID mortality/case rates as controls
5. **Placebo: domestic violence** — Should be less responsive to fiscal channels
6. **State-year fixed effects** — Absorb state-level COVID policies and other shocks
7. **Wild cluster bootstrap** — For inference with 32 state clusters
