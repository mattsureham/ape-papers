# Research Plan: Do Women Mayors Spend Differently?

## Research Question

Does electing a female mayor causally change the composition of municipal spending in Mexico? Specifically, do female mayors allocate more toward social transfers (ayudas sociales), public works (obra publica), and security (seguridad publica) relative to administrative overhead (servicios personales)?

## Why It Matters

Mexico's 2014 constitutional reform mandating gender parity in candidate lists tripled female mayors from ~5% to ~29%. Whether these women govern differently is first-order for evaluating parity mandates. Ferreira & Gyourko (2014, ReStud) found null gender effects for US mayors, but Mexico's context differs: higher gender inequality, stronger earmarked federal transfers (FAIS/FORTAMUN), and weaker institutional constraints on spending discretion.

## Identification Strategy

**Close-election RDD.** Running variable: vote margin between the female and male candidate in mixed-gender races. At the zero threshold, the identity of the winner switches from male to female. In close races, which candidate wins is as-if randomly determined.

**Key design choices:**
- Restrict to mixed-gender competitive races (female vs male candidate, margin < 10%)
- CCT optimal bandwidth as primary; robustness to half/double bandwidth and donut RDD
- Triangular kernel (default rdrobust)
- Fiscal outcomes averaged over the mayor's 3-year term
- Local linear specification (Gelman & Imbens 2019: avoid high-order polynomials)

## Validity Checks

1. **McCrary density test** — no bunching at margin = 0 (rddensity)
2. **Covariate balance** — pre-election fiscal variables smooth through cutoff (total revenue, population proxy, lagged spending shares)
3. **Placebo cutoffs** — no effect at margin = ±5%, ±10%
4. **Bandwidth sensitivity** — results hold across [h/2, h, 2h]
5. **Donut RDD** — exclude |margin| < 0.5% to check for precise manipulation

## Expected Effects and Mechanisms

**Theory is ambiguous:**
- *Preference channel:* If women have different policy preferences (more pro-social, less patronage), we'd see reallocation toward social transfers and away from administrative payroll
- *Competence channel:* If women must be higher-quality to win, spending could be more efficient overall
- *Institutional constraint channel:* If earmarking rigidities bind, gender may not matter (Ferreira & Gyourko mechanism)

**Possible findings:** Null effects would be consistent with institutional constraints dominating leader preferences. Positive effects on social spending would suggest gender parity mandates have policy consequences beyond representation.

## Primary Specification

Y_{m,t} = alpha + tau * D(Female_m) + f(margin_m) + epsilon_{m,t}

where:
- Y_{m,t} = fiscal outcome (spending share) averaged over mayor's term
- D(Female_m) = 1 if female candidate won
- f(margin_m) = local linear function of vote margin
- Estimated via rdrobust with CCT bandwidth

**Outcomes (spending shares of total expenditure):**
1. Social transfers (ayudas sociales / total expenditure)
2. Public works (obra publica / total expenditure)
3. Security (seguridad publica / total expenditure)
4. Administrative payroll (servicios personales / total expenditure)
5. Public investment (inversion publica / total expenditure)

## Data Sources

1. **Election data:** emagar/elecRetrns `aymu1989-on.incumbents.csv` (24,465 elections, 1954-2025)
   - Variables: dmujer (gender), mg (margin), inegi (municipal code), yr (year)
   - URL: https://raw.githubusercontent.com/emagar/elecRetrns/master/data/aymu1989-on.incumbents.csv

2. **Fiscal data:** INEGI EFIPEM municipal finances (1989-2023)
   - ~2,386 municipalities per year, annual CSV
   - URL: https://www.inegi.org.mx/contenidos/programas/finanzas/datosabiertos/efipem_municipal_csv.zip
   - Variables: total expenditure, servicios personales, inversion publica, ayudas sociales, obra publica, seguridad publica

## Analysis Plan

1. **00_packages.R** — Load rdrobust, rddensity, tidyverse, fixest, modelsummary
2. **01_fetch_data.R** — Download election CSV and EFIPEM zip; validate
3. **02_clean_data.R** — Construct RDD sample: identify mixed-gender races, compute margins, merge with fiscal data, average outcomes over mayoral term
4. **03_main_analysis.R** — RDD estimates for 5 spending outcomes + density test + balance tests
5. **04_robustness.R** — Bandwidth sensitivity, placebo cutoffs, donut RDD, pre-election outcomes
6. **05_tables.R** — Generate all LaTeX tables including SDE appendix
