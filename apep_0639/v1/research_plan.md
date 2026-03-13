# Research Plan: apep_0639

## Research Question

Did state opioid prescribing day-supply limits reduce prescription opioid deaths but inadvertently accelerate substitution to illicit opioids (heroin, fentanyl), producing a net increase in overdose mortality?

## The Substitution Trap Hypothesis

Between 2016 and 2019, 39 US states enacted laws limiting initial opioid prescriptions to 3–7 days. These "day-supply limits" were supply-side interventions designed to prevent opioid dependence by restricting the gateway — new prescriptions. The policy succeeded in reducing prescription volumes. But for patients already dependent, cutting the legal supply may have pushed them toward illicit markets — heroin and, increasingly, synthetic fentanyl — which carry dramatically higher overdose risk.

This paper tests whether the cure was worse than the disease.

## Identification Strategy

**Method:** Callaway and Sant'Anna (2021) staggered difference-in-differences.

**Treatment:** State adoption of day-supply limit laws, staggered across 39 states (2016–2019).

**Control:** ~11 never-treated states + not-yet-treated states (CS estimator uses both).

**Treatment cohorts:**
- 2016: MA, CT, NY (7-day)
- 2017: ME, NJ, OH, and others (5–7 day)
- 2018: FL, TN, AZ, and others (3–5 day)
- 2019: remaining states

**Core test — drug-type decomposition:**
1. Natural/semi-synthetic opioid deaths (T40.2) — prescription opioids → should DECREASE
2. Heroin deaths (T40.1) → substitution test
3. Synthetic opioid deaths excl. methadone (T40.4, captures fentanyl) → substitution test
4. Cocaine deaths (T40.5) → PLACEBO (no substitution channel)
5. Psychostimulant deaths (T43.6) → PLACEBO

**Why cocaine/psychostimulants are good placebos:** These are drug users affected by the same socioeconomic forces, but cocaine and methamphetamine are not substitutes for prescription opioids. If day-supply limits cause substitution specifically to opioid alternatives, cocaine/psychostimulant deaths should show no effect.

## Expected Effects and Mechanisms

| Outcome | Expected Sign | Mechanism |
|---------|---------------|-----------|
| Rx opioid deaths | Negative | Supply reduction works |
| Heroin deaths | Positive or null | Substitution from Rx to heroin |
| Synthetic/fentanyl deaths | Positive | Substitution to fentanyl (deadlier) |
| Cocaine deaths | Null | No substitution channel (placebo) |
| Psychostimulant deaths | Null | No substitution channel (placebo) |
| Total overdose deaths | Ambiguous | Net of reduction + substitution |

**Net welfare calculation:** Lives saved from Rx opioid reduction minus lives lost to illicit substitution.

## Primary Specification

```
Y_{s,t} = α + ATT(g,t) + ε_{s,t}
```

Where Y is deaths per 100,000 population (drug-type specific), estimated separately for each drug category using Callaway-Sant'Anna with:
- Group = year of law adoption
- Time = year (or quarter if data resolution allows)
- Covariates: state-level baseline characteristics (pre-treatment overdose rates, demographics)
- Clustering: state level
- Inference: wild cluster bootstrap + randomization inference

## Robustness

1. Sun and Abraham (2021) interaction-weighted estimator
2. De Chaisemartin and D'Haultfoeuille (2020)
3. Dose-response: 3-day vs 5-day vs 7-day limits
4. Exclude earliest cohort (MA 2016, only 1 pre-period year)
5. Bacon decomposition to verify clean comparisons dominate
6. HonestDiD sensitivity analysis (Rambachan-Roth bounds)
7. Leave-one-out state analysis
8. Population-weighted vs unweighted

## Data Source and Fetch Strategy

**Primary:** CDC NCHS Drug Overdose Death Counts via data.cdc.gov Socrata API
- Resource: `xkb8-kh2a` (provisional counts)
- Also try CDC WONDER for longer historical series
- State × year × drug type
- ICD-10 codes: T40.1 (heroin), T40.2 (Rx opioid), T40.4 (synthetic), T40.5 (cocaine), T43.6 (psychostimulants)

**Treatment coding:** Hand-coded from PDAPS/NCSL state law databases
- Day-supply limit, effective date, and maximum days for each state

**Population denominators:** Census Bureau state population estimates (for per-capita rates)

**Secondary:** ARCOS (DEA Automation of Reports and Consolidated Orders System) for prescription volume validation (if accessible)
