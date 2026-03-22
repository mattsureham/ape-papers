# Research Plan: When the Grocery Store Leaves

## Research Question

Does supermarket exit from a census tract reduce mortgage originations and increase denial rates? Grocery stores signal neighborhood viability to lenders and appraisers. When a supermarket closes, the tract loses a foot-traffic anchor, property values may decline, and the neighborhood's creditworthiness signal weakens. This paper tests whether the capital market responds to food infrastructure loss.

## Identification Strategy

**Staggered DiD** at tract level. Treatment: tract experiences SNAP supermarket deauthorization. Control: tracts without supermarket exit. County × year FE absorb county-level economic trends. Tract FE absorb permanent tract characteristics.

**Key advantage:** Both SNAP and HMDA data are at census tract level — no aggregation penalty. This addresses reviewer concerns from apep_0753 about state-level coarseness.

## Expected Effects

1. Supermarket exit → fewer mortgage originations (fewer buyers willing to purchase in the tract)
2. Supermarket exit → higher denial rates (lenders perceive higher risk)
3. Supermarket exit → lower median loan amounts (reflecting declining property values)
4. Effects should be larger in tracts with fewer remaining food retailers (dose-response)

## Data Sources

1. **HMDA** (CFPB Data Browser, 2018–2023): Loan-level data with census_tract, action_taken (origination=1, denial=3), loan_amount, loan_type, loan_purpose. Aggregate to tract-year: n_originations, n_denials, denial_rate, median_loan_amount.

2. **SNAP Retailer Historical Database** (USDA FNS, 2005–2025): 703K retailers with tract-level geocoding, authorization/end dates.

## Specification

```
Y_{c,t} = α_c + γ_{county(c),t} + β · Post_{c,t} + ε_{c,t}
```

Where c = tract, t = year. County × year FE are aggressive — they absorb all county-level time-varying confounds.

## Robustness

1. Pre-trends (event-study)
2. Placebo: tracts that gain a convenience store but don't lose a supermarket
3. Dose-response: more supermarket exits → larger effect
4. Alternative outcomes: FHA share (government-backed loans = safety net for declining areas)
