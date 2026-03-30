# Research Plan: Does Universal Health Insurance Save Infants? Cause-Specific Neonatal Mortality and Mexico's Seguro Popular

## Research Question

Does universal public health insurance reduce infant mortality, and if so, through which medical channels? We exploit Mexico's staggered rollout of Seguro Popular (SP) across municipalities (2002–2005) to estimate its causal effect on cause-specific infant and neonatal mortality, separating amenable causes (treatable conditions like diarrheal disease, respiratory infections, perinatal complications) from non-amenable causes (congenital anomalies, external causes) that serve as a built-in placebo.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD** with municipality-level treatment cohorts:

- **Treatment:** Year a municipality first enrolled in Seguro Popular
- **Cohorts:** 2002 (342 municipalities), 2003 (524), 2004 (946), 2005 (~1,600)
- **Controls:** Not-yet-treated and never-treated municipalities
- **Pre-treatment:** 1998–2001 (4 years before earliest cohort)
- **Post-treatment:** Up to 2012 (before SP was restructured into INSABI)
- **Unit:** Municipality-year panel

**Key identifying assumption:** Conditional on baseline covariates (marginality index, indigenous population share, urbanization), municipalities enrolling in different years would have followed parallel infant mortality trends absent SP. The cause-specific decomposition provides internal validation: non-amenable mortality (congenital anomalies, accidents) should show no effect.

## Expected Effects and Mechanisms

- **Amenable-cause IMR:** Negative effect (reduction). SP should improve access to prenatal care, institutional deliveries, and treatment of diarrheal/respiratory disease.
- **Non-amenable-cause IMR:** Null (built-in placebo). Insurance cannot prevent congenital anomalies or accidents.
- **Heterogeneity:** Larger effects in high-marginality municipalities with worse baseline healthcare access.

## Primary Specification

```
ATT(g,t) estimated via Callaway-Sant'Anna (2021)
Y_{it} = infant mortality rate (deaths < 1 year per 1,000 live births) by cause group
g = year of first SP enrollment
Controls: doubly-robust (OR + IPW) conditioning on baseline poverty, indigenous share, urbanization
Clustering: state level (32 clusters)
```

## Data Sources

1. **INEGI death microdata** (1998–2012): Individual death records with municipality of residence, age at death, ICD-10 cause of death. ~500K records/year. Free CSV download from datos.gob.mx.

2. **CONAPO municipal population projections**: Live births by municipality-year for mortality rate denominators. Alternative: INEGI registered births (SINAC).

3. **Seguro Popular enrollment dates**: Municipality-level first enrollment year from published SP administrative records and Pfutze (2014) replication data.

4. **CONEVAL marginality index**: Municipal-level poverty/marginality for baseline covariates.

## Data Fetch Strategy

1. Download INEGI death CSVs for 1998–2012 (15 files, ~60-90MB each)
2. Extract infant deaths (age < 1 year) and neonatal deaths (age < 28 days) by municipality and ICD-10 cause
3. Classify causes as amenable vs non-amenable
4. Download CONAPO/SINAC birth denominators by municipality-year
5. Construct SP enrollment cohort variable from published rollout data
6. Merge all into municipality-year panel

## Exposure Alignment

Treatment is state-level SP enrollment. The directly affected population is uninsured women of childbearing age and their infants — roughly 50% of the population had no insurance before SP. The infant mortality outcome aligns with this exposure because all infant deaths are recorded regardless of insurance status, and SP's benefits package directly targets maternal and child health services. The treatment effect is diluted by the fact that some municipalities had lower uninsured rates (due to IMSS/ISSSTE coverage), but this conservative bias works against finding an effect.

## Key Risks

- **Selection into early enrollment:** Poorer municipalities enrolled first. Addressed via doubly-robust CS-DiD with baseline covariates.
- **Measurement:** Small municipalities may have noisy IMR. Address via population-weighted estimation and robustness to dropping small municipalities.
- **Confounders:** Oportunidades (CCT program) expanded simultaneously. Control for Oportunidades coverage if data available.
