# Research Plan: apep_0653

## Research Question

Did state data breach notification laws (BNLs) deter new business formation by imposing fixed-cost compliance burdens on startups, and did this compliance tax fall disproportionately on data-intensive industries?

## The Compliance Tax Hypothesis

Between 2003 and 2018, all 50 US states adopted data breach notification laws requiring organizations to notify consumers when personal data is compromised. These laws create fixed compliance costs — incident response plans, cybersecurity audits, notification infrastructure, legal liability — that large incumbents absorb easily but that represent a meaningful barrier for new entrants. If BNLs function as a hidden entry tax, we should observe reduced establishment entry rates after adoption, concentrated in data-intensive industries (Information, Finance) relative to data-light industries (Construction, Agriculture).

## Identification Strategy

**Method:** Callaway and Sant'Anna (2021) staggered difference-in-differences.

**Treatment:** State adoption of first data breach notification law, staggered across 50 states + DC (2003–2018).

**Control:** Not-yet-treated states serve as controls (all states eventually adopted).

**Treatment cohorts:**
- 2003: CA (first mover)
- 2005: Mega-cohort (~23 states including NY, TX, IL, FL)
- 2006–2010: Gradual adopters
- 2011–2018: Late adopters (AL, SD last in 2018)

**Core mechanism test — industry decomposition:**
1. NAICS 51 (Information) — HIGH data exposure → should show LARGE entry reduction
2. NAICS 52 (Finance/Insurance) — HIGH data exposure → should show entry reduction
3. NAICS 54 (Professional/Scientific/Technical) — MODERATE data exposure
4. NAICS 23 (Construction) — LOW data exposure → PLACEBO
5. NAICS 11 (Agriculture) — LOW data exposure → PLACEBO

## Exposure Alignment

**Who is actually affected by treatment?** BNLs apply to any organization that collects personal information. The directly burdened population is firms handling consumer data — particularly those in data-intensive sectors like technology, finance, healthcare, and e-commerce.

**Population at risk of deterrence:** Potential entrepreneurs evaluating entry into data-handling sectors. BNLs raise the fixed cost of entry through compliance requirements, making the expected profit calculation less favorable for startups with limited resources.

**Unit of observation vs. unit of treatment:** Our unit of observation is the state-year (or state-year-industry). Treatment is binary: whether a state has an active BNL. The outcomes (establishment entry rate, establishment exit rate, employment dynamics) are measured from Census BDS at the state level.

**Timing alignment:** Treatment is coded at the state-year level using the effective date of each state's BNL. For mid-year adoptions, the first full calendar year post-adoption is coded as treated.

**Dose-response variation:** States vary in BNL stringency (private right of action, AG enforcement, encryption safe harbor, notification timeline). More stringent laws create higher compliance costs and should produce stronger entry deterrence.

## Expected Effects and Mechanisms

| Outcome | Expected Sign | Mechanism |
|---------|---------------|-----------|
| Establishment entry rate (all) | Negative | Fixed-cost compliance barrier |
| Entry rate — Information (NAICS 51) | Large negative | High data exposure |
| Entry rate — Finance (NAICS 52) | Negative | High data exposure |
| Entry rate — Construction (NAICS 23) | Null | No data exposure (placebo) |
| Establishment exit rate | Ambiguous | Compliance costs may push small firms out |
| Net job creation | Negative | Reduced entry → fewer new jobs |

## Primary Specification

```
Y_{s,t} = α + ATT(g,t) + ε_{s,t}
```

Where Y is establishment entry rate (or related firm dynamics measure), estimated using Callaway-Sant'Anna with:
- Group = year of BNL adoption
- Time = year
- Clustering: state level
- Industry-specific analyses run separately for mechanism tests

## Robustness

1. Sun and Abraham (2021) interaction-weighted estimator
2. Bacon decomposition to verify clean comparisons
3. Event study with 5+ pre-treatment periods
4. Exclude California (first mover, tech hub confound)
5. Leave-one-out cohort analysis (especially excluding 2005 mega-cohort)
6. TWFE comparison
7. Business Formation Statistics (BFS) weekly applications as alternative outcome

## Data Source and Fetch Strategy

**Primary:** Census Bureau Business Dynamics Statistics (BDS) via Census API
- Endpoint: `api.census.gov/data/timeseries/bds`
- State × year × NAICS sector
- Variables: ESTABS_ENTRY, ESTABS_ENTRY_RATE, ESTABS_EXIT, ESTABS_EXIT_RATE, FIRM, EMP, JOB_CREATION, JOB_DESTRUCTION
- Coverage: 1978–2023

**Treatment coding:** Hand-coded from NCSL Security Breach Notification Laws tracker
- State, effective date, key provisions (private right of action, notification timeline)

**Population denominators:** Not needed (BDS provides rates directly)

**Secondary:** Census Business Formation Statistics (BFS) for robustness
- Weekly business applications by state, 2006–present
