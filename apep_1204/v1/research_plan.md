# Research Plan: Stretched Thin — Concurrent Disaster Load and the Quality of FEMA Household Assistance

## Research Question

Does FEMA bureaucratic capacity degradation — caused by concurrent disaster declarations stretching a fixed workforce — causally reduce the speed, generosity, and equity of federal household disaster assistance?

## Policy Context

FEMA's Individual and Household Program (IHP) and Public Assistance (PA) program are the primary federal disaster response channels. Following presidential Major Disaster Declarations, FEMA deploys caseworkers and inspectors from a fixed workforce (~2,585 Individual Assistance cadre workers). GAO (2025) documented that on November 1, 2024, only 0.3% of IA workers (9 of 2,585) were available, with the rest deployed across 80+ simultaneous declarations. Climate change is increasing disaster frequency, making this capacity constraint increasingly binding.

## Identification Strategy

**Instrumental Variables (2SLS):**

- **Endogenous variable:** FEMA resources per disaster (proxied by obligation speed, approval rates)
- **Instrument:** Number of concurrently active Major Disaster declarations at the time disaster *i* occurs
- **First stage:** More concurrent disasters → fewer resources per disaster (zero-sum workforce constraint)
- **Second stage:** Reduced resources → slower obligation, lower approval rates, smaller per-household assistance

**Exclusion restriction:** Conditional on own-disaster severity (type, magnitude, affected population), the number of concurrent disasters in OTHER states affects local assistance quality only through FEMA's resource allocation. We control for disaster type, state, and seasonal fixed effects.

**Threats to identification:**
1. Seasonal clustering (hurricanes concentrate in Aug-Oct) → control for month-of-year FE
2. Disaster severity correlation (large disasters may coincide with capacity) → control for disaster type, state damage indicators
3. Political factors (presidential attention) → control for election year, state partisanship

## Expected Effects and Mechanisms

- **Speed:** Higher concurrent load → longer obligation lags (days from declaration to first dollar)
- **Generosity:** Higher concurrent load → lower IHP approval rates, smaller average grants
- **Equity:** Higher concurrent load → larger disparities across county income levels within a disaster

Mechanism: fixed FEMA workforce (zero-sum deployment) → diluted caseworker-to-disaster ratio → slower inspections, less thorough assessments

## Primary Specification

```
Y_id = α + β(ConcurrentLoad_d) + X_d'γ + State_FE + Year_FE + DisasterType_FE + ε_id

IV: ConcurrentLoad_d = f(overlap of incident periods across all active declarations)
```

Where:
- Y_id = outcome for project/registration i in disaster d (obligation lag, approval, grant amount)
- ConcurrentLoad_d = count of other active Major Disaster declarations at time of declaration d
- X_d = disaster-level controls (type, affected population, damage estimates)

## Data Sources

1. **OpenFEMA Disaster Declarations Summary** (46K rows) — declaration dates, incident periods, disaster types, states
2. **OpenFEMA PA Funded Projects** (811K records) — project-level obligations with dates, amounts, categories
3. **OpenFEMA IHP Registrations** (222K county-disaster records) — approval rates, average grant amounts
4. **OpenFEMA Mission Assignments** (41K records) — agency deployment data

All via REST API, no authentication required.

## Robustness

1. Leave-one-out IV (exclude disasters in same FEMA region)
2. Placebo: concurrent Minor Disaster declarations (no FEMA deployment)
3. Pre-determined disaster characteristics as outcomes (falsification)
4. Donut-hole: exclude declared disasters within 30 days of instrument computation
5. Nonlinear specification (bins of concurrent load)
