# Research Plan: Rescue or Ruin? The EU Preventive Restructuring Directive and Business Failure

## Research Question
Does access to preventive restructuring frameworks reduce business failures? Directive 2019/1023 required all EU member states to create court-supervised, debtor-in-possession restructuring procedures — essentially transplanting US Chapter 11 principles into civil law systems. The staggered transposition across 26 countries (Dec 2020 to Jul 2023) provides a natural experiment.

## Policy Context
Directive 2019/1023 on preventive restructuring frameworks ("the Second Chance Directive"):
- **Adopted:** June 2019, transposition deadline July 2022
- **Key provisions:** Pre-insolvency restructuring, debtor-in-possession, stay of enforcement (up to 12 months), cross-class cram-down, protection of new financing
- **Staggered adoption:** Germany StaRUG (Dec 2020), Netherlands WHOA (Jan 2021), France (Oct 2021), Denmark/Estonia (Jun 2022), Italy/Ireland (Jul 2022), Spain (Sep 2022), Czechia/Belgium (2023)
- **Purpose:** Save viable firms, prevent unnecessary liquidation, preserve jobs

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD:**
- Treatment: date of national law entry-into-force (transposition)
- Treatment groups: 6+ cohorts defined by transposition quarter
- Never-treated: countries not yet transposed as of data end (if any)
- Unit: country × NACE sector × quarter
- Pre-periods: 2015Q1-treatment quarter (~20-28 quarters pre)
- Post-periods: up to 12 quarters post-treatment

**Identifying assumption:** Absent transposition, bankruptcy trends in early-transposing countries would have evolved like those in late/never-transposing countries, conditional on sector and time effects.

## Expected Effects and Mechanisms
Theory is genuinely ambiguous:
1. **Rescue effect (β < 0):** Preventive restructuring saves viable firms → fewer bankruptcies
2. **Reclassification effect (β ≈ 0):** Distressed firms file restructuring instead of bankruptcy → no change in total failures, just relabeling
3. **Stigma-reduction effect (β > 0):** Easier process increases filings from firms that would have informally wound down → more recorded proceedings

## Exposure Alignment
The treatment (transposition of the directive) directly affects all firms in a member state that face financial distress. The bankruptcy declarations index captures court-supervised insolvency proceedings filed by firms domiciled in the treating country. Exposure is at the country level: once a member state transposes, all distressed firms within its jurisdiction gain access to the new preventive restructuring procedure. The outcome (bankruptcy declarations) is measured at the same geographic unit (country) and temporal frequency (quarter) as the treatment, ensuring alignment between who is treated and what is measured.

## Primary Specification
- Outcome: log bankruptcy declarations index (sts_rb_q, base 2021=100)
- Treatment: first quarter after national transposition law enters into force
- FE: country × sector, sector × quarter
- Clustering: country level (robust to few-cluster: wild cluster bootstrap)
- Estimator: Callaway-Sant'Anna with not-yet-treated comparison group

## Robustness
1. Alternative treatment dates: notification date to Commission (vs. entry-into-force)
2. Aggregate country-level analysis (collapsing across sectors)
3. Individual NACE sectors separately (industry B-E, construction F, services G-N)
4. Placebo treatment dates (1 year before actual transposition)
5. Drop Germany (earliest adopter, COVID moratorium overlap)
6. Oxford Stringency Index as time-varying control
7. Event study with 8 pre-quarters and 12 post-quarters

## Data Sources
1. **Eurostat sts_rb_q:** Quarterly bankruptcy declarations by country and NACE sector
   - Access: `eurostat` R package, no API key needed
   - Coverage: 26 countries, 2015-2025, NACE sectors B-E, F, G-N
2. **EUR-Lex CELLAR SPARQL / eurlex R package:** Transposition dates for Directive 2019/1023
   - National implementation measures with notification dates
3. **Oxford COVID-19 Government Response Tracker:** Stringency index as control
4. **Eurostat bd_hgnace2_r3:** Business demography (births, deaths) — compositional check
