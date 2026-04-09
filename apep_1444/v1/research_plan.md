# Research Plan: Ecuador Non-Contributory Pension Age-65 RDD

## Research Question

Does receiving Ecuador's non-contributory elderly pension (Pensión Mis Mejores Años) at the age-65 eligibility threshold reduce labor force participation among poor elderly Ecuadorians? Secondary outcomes: health, household composition, food security.

## Identification Strategy

**Sharp RDD at age 65.** Ecuador's non-contributory pension is available only to individuals aged 65+ who lack contributory pension coverage and have a Registro Social poverty score below 34.67. The age-65 cutoff is administratively determined (from national ID/cédula), creating a clean discontinuity in pension receipt.

- **Running variable:** Age in years (centered at 65)
- **Treatment:** Pension receipt (binary: eligible at 65+)
- **Bandwidth:** Data-driven (Calonico-Cattaneo-Titiunik optimal), expected ±3-5 years
- **Kernel:** Triangular (baseline), uniform (robustness)
- **Polynomial:** Local linear (baseline), local quadratic (robustness)

### Validity Tests
1. McCrary density test at age 65
2. Covariate balance at cutoff (education, sex, urban/rural, household size)
3. Placebo cutoffs at ages 60 and 70
4. Donut-hole RDD excluding ages 64-65

## Expected Effects

- **Labor force participation:** Negative (income effect dominates for poor elderly). Prior estimates from Mexico, Bolivia, Chile suggest 3-8 pp reduction.
- **Health utilization:** Positive (income enables healthcare access).
- **Household composition:** Ambiguous (pension income may attract or release co-resident children).

## Primary Specification

Y_i = α + τ · 1(Age_i ≥ 65) + f(Age_i - 65) + X_i'β + ε_i

Using `rdrobust` in R with CCT bandwidth selection, clustered SEs at the age level.

## Data Source and Fetch Strategy

**ENEMDU (Encuesta Nacional de Empleo, Desempleo y Subempleo)** from INEC Ecuador.
- Source: ecuadorencifras.gob.ec or ILO microdata repository
- Years: 2018-2023 (post-MMA reform, quarterly)
- Target: individuals aged 55-75 in poverty (Registro Social eligible)
- Expected sample: ~100,000 person-quarter observations in ±10-year window around cutoff

### Fetch approach
1. Try INEC Ecuador open data portal API
2. Fallback: ILO ILOSTAT/SurveyLib microdata
3. Fallback: World Bank Microdata Library

## Key Risk

ENEMDU microdata may not be downloadable via API — may require manual portal navigation. If microdata is inaccessible, we can use INEC published tabulations by single-year age groups, though this limits the RDD to a coarser analysis.
