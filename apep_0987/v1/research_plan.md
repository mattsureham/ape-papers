# Research Plan: Three Compliance Waves — EPA MATS Staggered Deadlines and Local Health Outcomes Near Coal Plants

## Research Question

Did the staggered compliance waves of the 2012 EPA Mercury and Air Toxics Standards (MATS) reduce infant health harms in counties near coal-fired power plants? The three compliance waves (April 2015, April 2016, April 2017) create a natural experiment for estimating the causal health benefits of coal plant pollution reduction.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD.** Counties are assigned to treatment cohorts based on the compliance wave of their nearest coal plant(s):

- **Wave 1 (April 2015):** Counties near ~400 plants that complied on time
- **Wave 2 (April 2016):** Counties near ~200 plants receiving 1-year statutory extensions under CAA §112(i)(3)(B)
- **Wave 3 (April 2017):** Counties near ~5 plants receiving reliability-based Administrative Compliance Orders

Treatment assignment: A county is "treated" in wave *t* if the nearest coal plant within a 50-mile radius complied in wave *t*. Counties with no coal plant within 50 miles serve as never-treated controls.

**Key identifying assumption:** Assignment to compliance waves is uncorrelated with county-level health trends. Extensions were granted based on retrofit engineering timelines, not local health conditions. Wave 3 reliability orders were determined by NERC grid assessments.

**Built-in placebo:** Counties >50 miles from any coal plant should show no health improvement — a strong falsification test using distance-based exposure gradients.

## Expected Effects and Mechanisms

1. **Primary channel:** MATS-mandated pollution controls reduced mercury, acid gas (HCl, HF), and fine particulate precursors from coal plants. Mercury emissions fell 86% and acid gas HAPs 96% by 2017.
2. **Expected health effects:** Reductions in low birth weight, very low birth weight, and preterm birth in exposed counties, with effects appearing in the compliance year of the nearest plant.
3. **Magnitude prior:** Isen, Rossin-Slater & Walker (JPE 2017) found 1970 CAA reduced infant mortality 1-2% per 1-unit µg/m³ TSP reduction. We expect moderate effects (SDE 0.05–0.15) given the scale of emission reductions.
4. **Heterogeneity:** Stronger effects in counties with higher pre-MATS plant emissions, rural counties (less other pollution), and high-poverty counties (less access to protective behaviors).

## Primary Specification

```
Y_{ct} = α_c + γ_t + β × Post_{ct} + X'_{ct}δ + ε_{ct}
```

Where:
- Y_{ct}: birth outcome (low birth weight rate, preterm birth rate) in county c, year t
- α_c: county fixed effects
- γ_t: year fixed effects
- Post_{ct}: indicator = 1 after the compliance wave affecting county c
- X_{ct}: time-varying county controls (unemployment, median income)

Estimated via Callaway-Sant'Anna (2021) with never-treated counties as comparison group. Standard errors clustered at the county level.

## Data Sources and Fetch Strategy

1. **EIA Form 860 (plant-level):** Generator retirement/compliance dates, pollution control equipment installation dates, plant coordinates (lat/lon). Public download from eia.gov.

2. **CDC WONDER Natality (county-level, 2009–2020):** Low birth weight (<2500g), very low birth weight (<1500g), preterm birth (<37 weeks), birth count by county-year. Public API.

3. **Plant coordinates:** From EIA-860 for distance-based county-plant matching.

4. **County centroids:** From Census TIGER/Line for distance calculations.

5. **County controls:** BLS LAUS (unemployment), Census SAIPE (poverty/income).

## Robustness Checks

1. Event study plots (CS-DiD group-time ATTs)
2. Distance gradient: 25-mile, 50-mile, 75-mile exposure radii
3. Placebo: counties >100 miles from any coal plant
4. Pre-trend sensitivity: HonestDiD/Rambachan-Roth bounds
5. Alternative clustering: state-level
6. Bacon decomposition of TWFE
