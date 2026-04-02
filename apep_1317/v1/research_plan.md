# Research Plan: Conscription Under Fire

## Research Question

Does wartime military conscription in Colombia causally affect long-run labor market outcomes? Specifically, does serving during the FARC/ELN conflict (pre-2016 peace deal) build human capital through formal-sector credentials (the *libreta militar*) or destroy it through violence exposure and foregone education?

## Identification Strategy

**Angrist (1990) framework adapted to Colombia.** Colombian law (Ley 48/1993, replaced by Ley 1861/2017) mandates that all males "define their military situation" at age 18. After screening, a public municipal lottery (*sorteo*) randomly selects who serves. This is codified as explicitly random (Art. 16: "los sorteos son publicos").

**Key variation:** Birth-cohort × time variation in military service exposure. Men born in years when conscription intensity was higher (larger draft cohorts, more active conflict) have higher service rates than comparable men born in adjacent years. The 2016 FARC peace deal provides a sharp structural break — post-2016 cohorts faced dramatically lower combat risk.

**Primary specification:** Reduced-form ITT comparing labor market outcomes of men in age cohorts with higher vs. lower military service exposure, using the GEIH repeated cross-sections. The key comparison is men aged 25-45 (who would have been eligible for conscription at 18) vs. women of the same age (who were never eligible), in a difference-in-differences framework:

Y_{imt} = alpha + beta * Male_i * HighExposureCohort_t + gamma * Male_i + delta * Cohort_t + X_{imt}' * theta + epsilon_{imt}

Where HighExposureCohort captures birth-year variation in military service intensity.

**Alternative specification:** Triple-difference exploiting the 2016 peace deal:
- Pre-2016 cohorts (served during conflict) vs. post-2016 cohorts (served during peace)
- Males vs. females
- Departments with higher vs. lower conflict intensity (using CERAC/UCDP conflict data)

## Expected Effects and Mechanisms

**Negative channel (human capital destruction):**
- Foregone education (12-24 months out of school/labor market)
- PTSD, injury, disability from combat exposure
- Disrupted social networks and career trajectories

**Positive channel (formal-sector credential):**
- *Libreta militar* is legally required for many formal-sector jobs, government positions, and some professional licenses
- Military service may provide skills training, discipline, networks
- For men from informal-sector backgrounds, service may be the only pathway to formal employment

**Net effect is genuinely ambiguous** — this is what makes the question interesting.

## Primary Specification

- **Unit of observation:** Individual male, aged 25-45, in DANE GEIH survey
- **Treatment:** Birth in a cohort with high military service intensity (pre-peace deal cohorts)
- **Outcomes:** Monthly earnings, formal employment (contributes to pension/health), hours worked, educational attainment, occupational skill level
- **Controls:** Age, department fixed effects, survey year fixed effects, education (for some specs)
- **Clustering:** Department level (32 departments)
- **Inference:** Wild cluster bootstrap given 32 clusters

## Data Source and Fetch Strategy

1. **DANE GEIH (Gran Encuesta Integrada de Hogares):** Colombia's main labor force survey. ~240,000 households/year. Available via ColOpenData R package on CRAN. Will fetch 2015-2023 microdata (pre and post peace deal). Variables: age, sex, department, education, earnings, formality, hours, occupation.

2. **Conflict intensity data:** UCDP Georeferenced Event Dataset (GED) for department-level conflict intensity by year. Available via UCDP API. This creates the dose variable for the DDD specification.

3. **Military service rates:** CNPV 2018 Census (48M people) has military service status. Can construct cohort × department service rates as a first-stage check.
