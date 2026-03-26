# Research Plan: Can Prosecutors Reach Across Borders? The European Investigation Order and Crime Deterrence

## Research Question

Does cross-border enforcement cooperation reduce crime? Specifically, did the European Investigation Order (Directive 2014/41/EU) — which replaced fragmented mutual legal assistance (10-18 month delays) with binding 90-day evidence requests — deter cross-border crime in EU member states?

## Identification Strategy

**Staggered Difference-in-Differences** exploiting the variation in transposition timing across EU member states.

- **Treatment:** National transposition of Directive 2014/41/EU (EIO)
- **Timing variation:** Deadline was May 22, 2017. Only 2 member states transposed on time; 13 faced infringement proceedings. Last transposition: September 2018. Denmark and Ireland opted out entirely (never-treated).
- **Estimator:** Callaway and Sant'Anna (2021) — modern staggered DiD to avoid TWFE bias
- **Unit of observation:** Country × year × crime category
- **Pre-treatment period:** 2012-2016 (5+ years)
- **Post-treatment period:** 2017-2022 (varies by cohort)

## Expected Effects and Mechanisms

**Theory (Becker 1968):** Criminals respond to expected punishment = probability of apprehension × probability of conviction × sentence severity. EIO operates through the *probability of conviction* channel by making cross-border evidence admissible and timely.

**Primary hypothesis:** Cross-border crimes (fraud, drug trafficking, theft) should decline after EIO transposition, because perpetrators exploiting jurisdictional gaps face higher conviction probability.

**Placebo hypothesis:** Domestic crimes (homicide, assault) — which rarely require cross-border evidence — should show no effect.

**Expected effect direction:** Negative (crime reduction) for cross-border crime categories, null for domestic crimes. Effect may be modest — EIO changes enforcement infrastructure, not penalties.

## Primary Specification

```
Y_{it} = α_i + γ_t + β × EIO_transposed_{it} + ε_{it}
```

Where:
- Y_{it}: Crime rate (offences per 100k population) in country i, year t
- α_i: Country fixed effects
- γ_t: Year fixed effects
- EIO_transposed_{it}: Binary indicator = 1 after country i transposes EIO
- Clustering: Country level (25 clusters)

Using Callaway-Sant'Anna with:
- Group variable: Year of transposition (cohorts: 2017, 2018)
- Never-treated group: Denmark and Ireland (opted out)
- Anticipation: 0 periods (transposition timing was uncertain)
- Outcome: Log(offences per 100k) for each crime category

## Triple-Difference Extension

Cross-border crime × post-transposition × treated country:
- Treatment crimes: Fraud (ICCS0701), drug offences (ICCS0601), theft (ICCS0502)
- Control crimes: Homicide (ICCS0101), serious assault (ICCS020111)

This isolates the EIO-specific deterrence from general crime trends or other EU criminal justice reforms.

## Data Sources

1. **Eurostat crim_off_cat** (2008-2022): Police-recorded offences by ICCS category, 25 EU countries. 92% coverage (1780/1925 cells). Primary outcome variable.

2. **Eurostat demo_pjan**: Population by country-year for rate calculation.

3. **EUR-Lex / CELLAR SPARQL**: Transposition dates for Directive 2014/41/EU via national implementation measures (notification dates).

4. **Eurostat crim_just_job** (optional): Criminal justice personnel — mechanism test (more prosecutors = more EIO usage).

## Robustness Checks

1. Wild cluster bootstrap (few clusters: 25 countries)
2. Randomization inference (permute treatment timing)
3. Event study with leads (pre-trend test)
4. Exclude 2020-2022 (COVID sensitivity)
5. Alternative crime categories as placebos
6. Continuous treatment intensity (EIO requests filed, if available from Eurojust)
7. Leave-one-out: drop each country to check influence

## Key Risks

1. **Few clusters:** 25 countries — will use wild cluster bootstrap and RI
2. **COVID confound:** 2020 lockdowns suppressed all crime — restrict sample to 2012-2019 as robustness
3. **Simultaneous reforms:** Other EU criminal justice reforms may coincide — document and address
4. **Crime reporting differences:** ICCS harmonization imperfect across countries — country FE absorb levels, but reporting changes could bias trends
5. **Anticipation:** If criminals don't know about EIO, there's no deterrence. Conversely, if governments announced early, there could be anticipation effects.
