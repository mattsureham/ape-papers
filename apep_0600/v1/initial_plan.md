# Initial Research Plan: apep_0600

## Research Question

Did the EU Mortgage Credit Directive (2014/17/EU) — which imposed mandatory creditworthiness assessments on mortgage lenders — tighten lending conditions and affect housing prices? We exploit the massively staggered transposition of the MCD across 24 EU member states (March 2015 to June 2019) as a natural experiment.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway & Sant'Anna (2021).

**Treatment:** Binary indicator for national MCD transposition, with timing from CELLAR SPARQL notification dates. 24 countries transposed between March 2015 and June 2019; only 8 met the March 2016 deadline.

**Unit of analysis:** Country × month (ECB MIR) or country × quarter (Eurostat HPI).

**Why staggered timing is plausibly exogenous:** Transposition delays were driven by legislative capacity, coalition politics, and legal complexity — not by mortgage market conditions. The Commission launched infringement proceedings against late transposers, confirming delays were not strategic.

## Expected Effects and Mechanisms

1. **Mortgage rates:** Ambiguous. Tighter creditworthiness standards may raise rates for marginal borrowers (risk-based pricing) or reduce rates by shifting composition toward safer borrowers (selection effect).
2. **Lending volumes:** Negative. Mandatory affordability assessments mechanically exclude some borrowers → lower origination volumes.
3. **House prices:** Negative or null. Credit tightening reduces demand → price moderation, but effect may be small relative to other housing market drivers.

**Primary mechanism:** The MCD's creditworthiness assessment requirement forces lenders to verify borrower income rather than relying on property values. This shifts lending from asset-based to income-based underwriting. Countries with previously lax standards should show larger effects.

## Primary Specification

For country *i* in month *t*, with treatment cohort *g* (month of transposition):

ATT(g,t) estimated via Callaway & Sant'Anna (2021), aggregated to event-time ATT and overall ATT.

**Outcomes:**
1. ECB MIR: Monthly mortgage lending rates (annualized agreed rate, new business, housing loans)
2. ECB MIR: Monthly mortgage lending volumes (new business)
3. Eurostat prc_hpi_q: Quarterly house price index (2015=100)

**Built-in placebo:** Consumer credit rates from ECB MIR (not covered by MCD) — same data source, same reporting framework, different product.

## Exposure Alignment (DiD)

- **Who is actually treated?** Mortgage lenders in each member state, required to conduct creditworthiness assessments per national transposition.
- **Primary estimand population:** All new mortgage borrowers in the country.
- **Placebo/control population:** Consumer credit borrowers (not covered by MCD); never-yet-treated countries serve as controls in CS-DiD.
- **Design:** Staggered DiD (not triple-diff), with consumer credit as a falsification test.

## Power Assessment

- **Pre-treatment periods:** 44 quarters (2005-2015) for HPI; ~36 months (Jan 2013 - Mar 2015) minimum for ECB MIR.
- **Treated clusters:** 24 countries across multiple cohorts.
- **Post-treatment periods per cohort:** Early transposers (2015) have 4+ years post; late transposers (2019) have ~1 year pre-COVID.
- **MDE given sample size:** With 21 euro-area countries and monthly data, standard errors clustered at country level. Wild cluster bootstrap for few-cluster robustness.

## Planned Robustness Checks

1. Bacon decomposition (share of clean vs. problematic comparisons)
2. Sun-Abraham IW estimator
3. Event-study pre-trend plots (12+ months pre)
4. Leave-one-out country exclusion
5. Randomization inference (permute treatment timing)
6. HonestDiD/Rambachan-Roth sensitivity to pre-trend violations
7. Consumer credit placebo (should show no effect)
8. Controlling for known national macro-prudential policy changes (LTV caps, stress tests)

## Heterogeneity (Theory-Driven)

1. **Pre-existing regulation stringency:** Countries with lax pre-MCD standards (e.g., no prior affordability checks) should show larger effects than countries that already had similar rules.
2. **Housing boom intensity:** Countries experiencing rapid price growth pre-MCD may show larger credit tightening effects.
3. **Euro vs. non-euro:** Euro area countries face uniform monetary policy; non-euro countries have additional policy instruments.
