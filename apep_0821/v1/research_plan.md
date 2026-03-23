# Research Plan: The Bureaucrat's Bonus

## Research Question

What are the local economic spillover effects of India's 6th Central Pay Commission wage shock? The 6th CPC (implemented September 2008) delivered ~Rs 18,060 crore in arrears and a 20-40% permanent raise to ~4.7 million central government employees, with states adopting staggered implementations through 2013. This paper estimates village-level fiscal multipliers in a developing country by exploiting cross-village variation in pre-existing government employment intensity.

## Identification Strategy

**Dose-response Difference-in-Differences.** Treatment intensity = village-level government employment share from Economic Census 2005 (ec05_emp_gov / ec05_emp_all), measured before the 6th CPC was constituted (October 2006). Post-treatment: September 2008 onward.

**Key specification:**
```
log(nightlights_{v,t}) = β(GovEmpShare_v × Post_t) + α_v + δ_{s,t} + X_v × t + ε_{v,t}
```

Where:
- GovEmpShare_v = ec05_emp_gov / ec05_emp_all (continuous, village-level)
- Post_t = 1 for years ≥ 2008
- α_v = village fixed effects
- δ_{s,t} = state × year fixed effects (absorb state-level fiscal policy, including staggered state pay commission adoption)
- X_v × t = village-level pre-treatment controls interacted with linear trend

β estimates the differential nightlight growth in villages with higher pre-existing government employment intensity after the pay commission shock.

## Expected Effects and Mechanisms

1. **Direct income effect:** Government employees in high-treatment villages receive large income shocks → increased local consumption → higher nightlights
2. **Local multiplier:** Spending cascades to local retailers, service providers → firm entry (EC 2013 vs EC 2005)
3. **Credit channel:** Lump-sum arrears (40% in 2008, 60% in 2009) may relax liquidity constraints more than permanent raises
4. **Magnitude prior:** Nakamura & Steinsson (2014 AER) estimate US fiscal multipliers of 1.5-2.0. Developing-country multipliers may differ due to thinner markets and higher marginal propensities to consume.

## Primary Specification

Event-study version for pre-trend validation:
```
log(nightlights_{v,t}) = Σ_k β_k (GovEmpShare_v × 1{t=k}) + α_v + δ_{s,t} + ε_{v,t}
```
k ∈ {2004, ..., 2013}, base year = 2007.

## Robustness
1. **Placebo treatment:** Use private-sector employment share (ec05_emp_priv / ec05_emp_all) — should show no differential post-2008 growth
2. **Alternative outcomes:** EC 2013 vs EC 2005 changes in firm counts, private employment
3. **MGNREGA control:** Include MGNREGA phase rollout × year interactions
4. **Exclude urban:** Restrict to rural villages (nightlights more responsive)
5. **Top-code nightlights:** Address saturation at top (use asinh transformation)
6. **Conley standard errors:** Spatial correlation correction

## Data Sources
1. **SHRUG EC 2005** (`shrug_ec05.csv`): Village-level government employment (treatment)
2. **SHRUG DMSP nightlights** (`shrug_nl.csv`): Annual luminosity 2004-2013 (outcome)
3. **SHRUG PC11 TD** (`shrug_pc11_td.csv`): Geographic crosswalk (state/district IDs)
4. **SHRUG EC 2013** (`shrug_ec13.csv`): Firm counts post-treatment (secondary outcome)
5. **SHRUG PC11 PCA** (`shrug_pc11_pca.csv`): Population, literacy controls
6. **SHRUG PC01 PCA** (`shrug_pc01_pca.csv`): Pre-treatment Census controls

## Fetch Strategy
Download SHRUG CSV files from devdatalab.org download portal. All datasets are open-access. ~2-5 GB total.
