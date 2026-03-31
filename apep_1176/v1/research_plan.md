# Research Plan: The Inspection Lottery

## Research Question
Does regulatory inspection stringency cause nursing homes to invest in real quality (staffing levels, quality outcomes), or does it primarily generate compliance paperwork? We exploit quasi-random variation in state survey agency stringency — the "inspection lottery" — to identify the causal effect of regulatory pressure on nursing home quality investment.

## Policy Context
CMS delegates nursing home certification surveys to state agencies under 42 CFR Part 488. Survey agencies assign scope/severity codes on a grid from A (isolated/no harm) to L (widespread/immediate jeopardy). GAO-08-517 documented massive cross-state variation: 70% of state surveys miss deficiencies found by federal follow-ups, and 15% miss serious ones. States like Alaska have 12.5 surveyors per 1,000 nursing home residents versus Alabama's 2.5. This creates a "regulatory lottery" — identical nursing home conditions receive different deficiency ratings depending on which state's agency conducts the survey.

## Identification Strategy
**Instrument:** Leave-one-out state mean deficiency severity within year. For each facility, the instrument is the average severity of deficiency citations issued by the same state agency to *other* facilities in the same year, excluding the focal facility.

**Multi-state chain design:** Large nursing home chains (Ensign: 14 states; Sabra: 43 states; Genesis: 25 states) set budgets and operational policies chain-wide. A Genesis facility in strict New Hampshire faces a different surveyor regime than a Genesis facility in lenient Louisiana, despite identical corporate governance. This separates management quality from regulatory stringency.

**First stage:** State survey agency stringency → facility deficiency severity
**Second stage:** Instrumented deficiency severity → quality investment (staffing HPRD, quality measures)

**Exclusion restriction:** State surveyor stringency affects a facility's quality investment only through the deficiency citations it generates. The identifying assumption is that conditional on chain fixed effects (or facility fixed effects in the full sample), state-level surveyor stringency does not directly affect staffing or quality outcomes through channels other than citations.

## Expected Effects and Mechanisms
- **Compliance channel:** Strict agencies → more/worse citations → facilities increase staffing to avoid penalties (real quality investment)
- **Paperwork channel:** Strict agencies → more citations → facilities hire compliance staff, not care staff (cosmetic response)
- **Deterrence channel:** Strict regulatory environment → facilities preemptively invest in quality to avoid citations

We expect a positive first-stage (strict states issue worse citations) and test whether the second stage shows real quality improvement (nurse staffing HPRD) or just paperwork compliance.

## Primary Specification
```
Y_it = α + β * Severity_hat_it + γ * X_it + δ_chain + θ_year + ε_it

Where:
  Severity_hat_it = instrumented deficiency severity for facility i in year t
  X_it = facility characteristics (beds, ownership type, urban/rural)
  δ_chain = chain fixed effects (for chain subsample)
  θ_year = year fixed effects
```

Instrument: Z_st = leave-one-out state mean severity (excluding facility i) in year t.

## Data Sources and Fetch Strategy

All data from CMS public APIs (no authentication required):

1. **Health Deficiencies** — `https://data.cms.gov/provider-data/api/1/datastore/query/r5ix-sfxw/0`
   - ~419K records: facility CCN, survey date, deficiency tag, scope/severity code, state

2. **Provider Information** — CMS Provider Info dataset
   - Facility characteristics: beds, ownership, chain affiliation, state, urban/rural

3. **Payroll-Based Journal (PBJ) Staffing** — CMS staffing dataset
   - Hours per resident day (HPRD) by staff type (RN, LPN, CNA, total)

4. **Quality Measures (MDS)** — CMS quality measures dataset
   - ~250K records: falls, pressure ulcers, UTIs, physical restraints, etc.

5. **Penalties** — CMS penalties dataset
   - ~17K records: CMPs, denial of payment, state monitoring

## Key Risks
1. **Weak instrument:** State stringency may not vary enough after controlling for state composition
2. **Exclusion restriction:** State regulatory culture may affect nursing homes through channels beyond citations (e.g., reimbursement rates, staffing requirements)
3. **Chain subsample selection:** Chains may systematically differ from independent facilities

## Robustness Checks
- OLS comparison (expected upward bias — worse facilities get more citations)
- Chain-only subsample with chain FE (strongest identification)
- Instrument diagnostics: F-statistic, Anderson-Rubin test, effective F
- Leave-one-state-out jackknife
- Placebo: instrument with lagged (t-2) stringency on current outcomes
- Heterogeneity: chain vs. independent, for-profit vs. non-profit
