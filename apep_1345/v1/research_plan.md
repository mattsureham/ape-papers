# Research Plan: The Inspector Lottery

**Paper ID:** apep_1345
**Idea:** idea_2140
**Date:** 2026-04-03

## Research Question

Do Ofsted school inspection ratings causally affect local house prices? We exploit quasi-random variation in lead inspector identity — specifically, differences in grading leniency across inspectors — to isolate the causal label effect of inspection grades on residential property values near schools.

## Identification Strategy

**Method:** Examiner-leniency IV (Kling 2006 framework)

**Instrument:** Leave-one-out average rating of lead inspector j across all other schools inspected in the same region and year. More lenient inspectors (higher leave-out average = worse ratings, since 1=Outstanding, 4=Inadequate) systematically assign harsher ratings; more lenient inspectors assign better ratings.

**First stage:** Inspector j's leave-out leniency predicts the rating assigned to school i, conditional on school characteristics, region-by-year FE, and school type.

**Exclusion restriction:** Conditional on region-by-year FE and school observables, inspector identity affects house prices only through the assigned rating. Inspectors are assigned based on scheduling logistics (availability, geography, remit), not school characteristics.

**Estimand:** LATE — the causal effect of a one-grade improvement in Ofsted rating for schools whose rating is marginal to inspector leniency.

## Expected Effects and Mechanisms

- **House prices:** Positive effect of better ratings. Hussain (2023 JUE) estimates ~0.5% per grade using DiD. IV estimate may be larger (LATE on marginal schools) or smaller (if DiD captures correlated quality improvements).
- **Mechanism:** Information channel — Ofsted reports are public and widely consulted by parents choosing schools and homebuyers. The rating IS the signal; the IV isolates the label from the underlying quality.

## Primary Specification

Y_{it} = α + β * Rating_{it} + X_{it}γ + δ_{r,t} + ε_{it}

Instrumented: Rating_{it} = π * Leniency_{j(i),-i} + X_{it}λ + μ_{r,t} + ν_{it}

Where Leniency_{j(i),-i} is the leave-one-out mean rating of inspector j across all other inspections (excluding school i) in the same region and year.

Unit: school-inspection event. Outcome: log mean house price within school postcode district in the 12 months following inspection.

## Data Sources

1. **Ofsted Management Information** (GOV.UK) — inspection dates, ratings, school URN, postcode
2. **Ofsted Published Reports** (reports.ofsted.gov.uk) — lead inspector name/type per inspection
3. **HM Land Registry Price Paid Data** (GOV.UK) — postcode-level house prices
4. **postcodes.io** — postcode to geographic linkage

## Key Risk

Inspector identity linkage: The MI CSV may not contain inspector names. If scraping report metadata proves infeasible, fallback is to use HMI vs OI type as a coarser instrument, or pivot to a rating-change event study.

## Exposure Alignment

The treatment (Ofsted rating publication) directly affects information available to homebuyers and estate agents in the school's local area. The outcome (house prices) is measured at the postcode district level — the same geographic unit where the information shock occurs. Treated units are schools receiving negative ratings (3-4); control units are schools receiving positive ratings (1-2). The exposure is a discrete event (publication date) with a clear before/after boundary. Homebuyers in the school's postcode district are the affected population — they face the school quality signal when making purchasing decisions.

## Robustness & Placebos

1. Pre-inspection house prices (should be null — leniency shouldn't predict pre-trends)
2. House prices 5+ km from school (distance placebo)
3. Pre-determined school characteristics (balance test)
4. LIML/Fuller/UJIVE as alternative estimators
5. Varying the house price window (6mo, 12mo, 24mo post-inspection)
