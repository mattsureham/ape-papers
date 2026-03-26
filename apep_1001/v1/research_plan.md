# Research Plan: The Enforced Leisure Effect — Poland's Sunday Trading Ban and Road Traffic Accidents

## Research Question

Does Poland's phased Sunday trading ban (2018–2020) increase road traffic accidents by displacing commercial activity toward outdoor recreation and travel? When shops close, do people stay home — or get on the road?

## Policy Background

Poland's Act of 10 January 2018 phased in a Sunday trading ban:
- **Phase 1** (March 2018): ~24 trading Sundays/year permitted
- **Phase 2** (January 2019): ~12 trading Sundays/year
- **Phase 3** (January 2020): ~7 exempt Sundays only (primarily pre-Christmas, pre-Easter)

By 2020, the ban covers ~45 of 52 Sundays annually. Exempt ("trading") Sundays are legislatively designated, creating clean within-year variation.

## Identification Strategy

### Primary Design: Within-Year Sunday Comparison (DiD-like)

Compare road accident outcomes on **trading Sundays** (shops open) vs. **non-trading Sundays** (shops closed) within the same year and voivodeship. The unit of observation is voivodeship × date.

$$Y_{vd} = \alpha + \beta \cdot \text{NonTrading}_{d} + \gamma_v + \delta_m + X_{vd}'\theta + \varepsilon_{vd}$$

- $Y_{vd}$: accident count (or rate) in voivodeship $v$ on date $d$
- $\text{NonTrading}_{d}$: indicator for ban-affected Sunday
- $\gamma_v$: voivodeship FE
- $\delta_m$: month FE (absorbs seasonal confounds)
- $X_{vd}$: weather controls (temperature, precipitation)

$\beta$ captures the causal effect of the trading ban on accidents.

### Placebo: Saturday Comparison

Run the same specification comparing Saturdays before trading vs. non-trading Sundays. No treatment should exist for Saturdays.

### Triple-Difference: Hourly Displacement

Using individual SEWIK records with minute-level timestamps:

$$Y_{vdh} = \alpha + \beta_1 \cdot \text{NonTrading}_d + \beta_2 \cdot \text{ShopHours}_h + \beta_3 \cdot (\text{NonTrading}_d \times \text{ShopHours}_h) + \text{FEs} + \varepsilon_{vdh}$$

$\beta_3$ identifies within-day displacement: do accidents shift from evening hours (when shopping-trip returns would occur) to daytime hours (when people substitute outdoor activities)?

### Heterogeneity

1. **Accident type**: pedestrian vs. vehicle-vehicle (pedestrians more affected by retail activity)
2. **Intoxication**: alcohol-involved accidents may increase with leisure displacement
3. **Urban vs. rural voivodeships**: stronger effects where retail infrastructure is concentrated

## Expected Effects and Mechanisms

**Main prediction:** Non-trading Sundays have MORE total accidents than trading Sundays. When shops close, ~45 million Poles don't stay home — they drive for recreation, family visits, and outdoor activities.

**Mechanism — "enforced leisure displacement":** Shopping malls are enclosed, climate-controlled, pedestrian environments. When access is removed, substitute activities involve more road travel. The hourly pattern should show:
- Daytime (10–16h): accidents INCREASE on non-trading Sundays (more road activity)
- Evening (19–22h): accidents DECREASE on non-trading Sundays (no late shopping returns)

**Smoke test confirms:** Raw data shows trading Sundays: 43.1 accidents/day; non-trading: 46.4/day. Hourly ratios during 10–16h: 0.67–0.85; at 21h: 1.32.

## Data Sources

### Primary: SEWIK Police Records (Zenodo)
- 88,607 individual accident records, 2020–2023
- Fields: datetime (minute), voivodeship, incident type, severity, intoxication status
- Source: Zenodo dataset (confirmed accessible)

### Secondary: GUS BDL (Statistics Poland API)
- Quarterly road accidents by voivodeship, 2014–2024
- Used for pre-ban context and aggregate trends
- No authentication required

### Trading Sunday Calendar
- Legislatively fixed dates from the Act of 10 January 2018 and amendments
- Will construct indicator variable from official gazette

## Primary Specification

Poisson regression of daily voivodeship accident counts on non-trading indicator, with voivodeship and month FEs. Cluster standard errors at voivodeship level (16 clusters — will supplement with wild cluster bootstrap).

## Robustness

1. Saturday placebo (same dates, no treatment)
2. Wild cluster bootstrap (16 clusters is borderline)
3. Negative binomial as alternative to Poisson
4. Exclude holiday-adjacent Sundays (Christmas/Easter confounds)
5. Leave-one-voivodeship-out sensitivity
6. Weather controls from ERA5 or Polish meteorological service
