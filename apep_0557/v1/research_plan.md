# Research Plan (Revised)

## Research Question

Does foreign aid buffer the destabilizing effects of oil revenue shocks in Nigeria? When oil prices crash and government revenue collapses, do states with more geocoded foreign aid projects experience smaller increases in conflict?

## Motivation

Nigeria derives approximately 75% of government revenue from oil exports. Oil price shocks therefore transmit directly into government capacity — reducing spending on security, public services, and infrastructure. The 2008-09 global financial crisis caused Brent crude to fall from $145/barrel (July 2008) to $40/barrel (January 2009), wiping out roughly half of Nigeria's federal revenue within months. This paper tests whether pre-existing foreign aid projects provided a fiscal buffer, cushioning the shock's impact on local conflict.

## Identification Strategy

**Continuous DiD** exploiting the interaction between:

1. **Cross-sectional variation in aid exposure**: States differ in their pre-shock stock of geocoded foreign aid projects (AidData AIMS v1.3.2). This variation is predetermined — projects were approved years before the oil crash for reasons (disease burden, poverty, institutional ties) plausibly orthogonal to the timing of the oil shock.

2. **Time variation from the oil price shock**: The 2008-09 crash is driven by global demand collapse and financial contagion — fully exogenous to Nigerian local conditions.

**Estimating equation:**

Conflict_{s,t} = alpha_s + gamma_t + beta * (AidExposure_s * PostShock_t) + X'_{s,t} delta + epsilon_{s,t}

where s indexes states, t indexes months, alpha_s are state fixed effects, gamma_t are year-month fixed effects.

**Key identifying assumption:** Conditional on state and time fixed effects, the timing-adjusted aid exposure does not predict differential pre-trends in conflict.

## Data Sources

| Source | Variables | Coverage |
|--------|-----------|----------|
| AidData AIMS v1.3.2 | Geocoded aid projects, commitments, sectors, donors | 1988-2014, 595 projects, 1,409 locations |
| ACLED | Conflict events, fatalities, event types | 1997-present, 40,000+ Nigeria events |
| FRED | Brent crude oil prices | 2000-present, daily |

## Primary Specification

**Unit of analysis:** State x month (~37 states x 216 months [1997-2014] = ~7,992 observations)

**Outcome variables:**
- Count of ACLED conflict events (log(events+1))
- Count of battle events specifically
- Total fatalities (log(fatalities+1))

**Treatment (continuous):**
- AidExposure_s = cumulative geocoded aid projects in state s as of December 2007 (pre-shock)
- Alternative: log(total commitments + 1) as of December 2007

**Shock timing:** PostShock = 1 for months >= September 2008 (when oil prices began steep decline)

**Fixed effects:** State FE + year-month FE

**Standard errors:** Clustered at state level (37 clusters — will supplement with wild cluster bootstrap)

## Secondary Specifications

1. **Event study:** Monthly leads/lags around September 2008, testing parallel pre-trends
2. **Binary treatment:** Above/below median aid exposure
3. **Sector heterogeneity:** Health aid vs infrastructure aid vs governance aid
4. **Donor heterogeneity:** World Bank vs bilateral vs multilateral
5. **Oil-producing states:** Triple interaction (aid x shock x oil-producing)

## Robustness Checks

1. Pre-trend test: F-test for joint significance of pre-treatment event-study coefficients
2. Wild cluster bootstrap (Cameron, Gelbach, Miller) for inference with 37 clusters
3. Randomization inference: Permute aid exposure across states (1,000 draws)
4. Alternative shock windows: October 2008, January 2009
5. Poisson pseudo-maximum likelihood for count outcomes
6. Leave-one-out: Drop each state to check outlier dependence
7. Placebo shock: Test 2005 or 2011 (non-shock years) for false positives
8. Exclude FCT (Abuja) which is unlike other states
9. Control for state population and urbanization

## Exposure Alignment (DiD)

- **Who is actually treated?** Nigerian states with active foreign aid projects during the 2008-09 oil crisis
- **Primary estimand population:** All 36 states + FCT = 37 units
- **Treatment variable:** Continuous (cumulative aid projects) — predetermined as of Dec 2007
- **Design:** Continuous DiD with interaction (AidExposure x PostShock)

## Power Assessment

- 37 clusters (states), ~18 years monthly = ~7,992 state-months
- Pre-shock: 1997-2008 (132 months); Post-shock: 2009-2014 (72 months)
- Continuous treatment with substantial cross-state variation
- With ~8,000 observations and 37 clusters, MDE approximately 10-15% of SD in log conflict
