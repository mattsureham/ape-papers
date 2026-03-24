# Research Plan: School Autonomy and Pupil Sorting

## Research Question

Does conversion to academy status increase socioeconomic segregation within English schools? When schools gain admissions autonomy, do they cream-skim advantaged pupils at the expense of neighboring maintained schools?

## Identification Strategy

**Staggered DiD with Callaway-Sant'Anna (2021).** Treatment: year of academy conversion. Unit: school-year panel (~24,000 schools, 2010-2024). The staggered rollout (138 schools in 2010, peaking ~1,000/year) provides variation in treatment timing across 15 cohorts.

- **Primary estimator:** Callaway-Sant'Anna group-time ATT, aggregated to event-time
- **Fixed effects:** Local Authority × year (absorbs local trends in demographics)
- **Clustering:** Local Authority level (~150 LAs)
- **Control group:** Not-yet-treated schools (preferred) + never-treated
- **Heterogeneity:** Converter academies (voluntary, typically high-performing) vs sponsor-led (imposed on failing schools)

## Key Outcomes

1. **FSM share** (% pupils eligible for Free School Meals) — primary measure of socioeconomic composition
2. **SEN share** (% pupils with Special Educational Needs) — secondary inclusion measure
3. **EAL share** (% pupils with English as Additional Language) — additional composition measure

## Expected Effects and Mechanisms

If academy autonomy enables selective admissions:
- Converting schools should see **declining FSM/SEN shares** (cream-skimming)
- Neighboring maintained schools should see **rising FSM/SEN shares** (displacement)
- Effect should be stronger for converter academies (which have genuine choice) than sponsor-led (imposed conversions)

Null result is credible and publishable: would mean admissions autonomy doesn't translate to meaningful sorting.

## Data Sources

1. **GIAS (Get Information About Schools)** — bulk extract from DfE
   - URL: `https://get-information-schools.service.gov.uk/Downloads`
   - Contains: school URN, establishment type, open/close dates, LA, phase
   - Identifies all academies with exact conversion dates

2. **Schools, Pupils and their Characteristics** — annual DfE statistical release
   - URL: `https://explore-education-statistics.service.gov.uk/`
   - Contains: school-level FSM eligibility, SEN, EAL, ethnicity, headcount
   - Annual snapshots (January school census)

3. **KS4 Performance Tables** — optional for attainment robustness
   - URL: `https://www.find-school-performance-data.service.gov.uk/download-data`
   - Contains: institution-level attainment measures

## Primary Specification

```
Y_{it} = ATT(g,t) via Callaway-Sant'Anna
where g = year of academy conversion
      t = calendar year
      Y = FSM share at school i in year t
      Controls: school-level covariates (headcount, phase)
      Clustering: Local Authority
```

## Exposure Alignment

Treatment is academy conversion: the moment a maintained school officially becomes an academy (new URN created, predecessor school closed). The treated population is the set of pupils enrolled at the school at the time of conversion and subsequent cohorts. The control group (never-converted maintained schools) faces the counterfactual: what would FSM composition look like absent conversion? The identifying assumption is parallel trends in FSM shares between converting and never-converting schools, conditional on school and year fixed effects. Treatment is absorbing (schools do not revert from academy to maintained status).

## Robustness Checks

1. Sun-Abraham (2021) interaction-weighted estimator
2. Borusyak-Jaravel-Spiess (2024) imputation estimator
3. Converter vs sponsor-led subsample analysis
4. Spillover test on neighboring maintained schools (within same LA)
5. Leave-one-out by cohort (sensitivity to any single conversion wave)
6. Placebo: use pre-2010 years as fake treatment dates
