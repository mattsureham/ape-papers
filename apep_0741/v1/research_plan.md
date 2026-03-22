# Research Plan: apep_0741

## Research Question

Do handheld cellphone bans reduce fatal traffic crashes? This paper exploits the spatial discontinuity at state borders where one side bans handheld phone use while the other does not, using geocoded crash-level data from NHTSA's Fatality Analysis Reporting System (FARS).

## The Puzzle

Distracted driving kills approximately 3,500 Americans annually — yet evidence on whether hands-free laws actually reduce fatalities is surprisingly thin. Existing studies rely on temporal before-after comparisons within treated states, confounding the law's effect with concurrent safety trends, enforcement changes, and smartphone technology evolution. The spatial dimension — what happens at the precise border where a law's jurisdiction ends — has never been exploited.

## Identification Strategy

**Spatial RDD at state borders** combined with staggered adoption timing.

The running variable is geographic distance to the nearest treated state border. Crashes on the treated side (handheld ban) are compared to crashes on the untreated side, within narrow distance bandwidths (10km, 20km, 30km, 50km).

**Treatment states and timing:**
- Oregon (Oct 2017), Georgia (Jul 2018), Tennessee (Jul 2019), Minnesota (Aug 2019), Indiana (Jul 2020), Massachusetts (Feb 2020), Virginia (Jan 2021)
- This creates ~10 border pairs where one side adopts while the neighbor does not

**Key identification assumption:** Fatal crash risk varies smoothly across state borders in the absence of differential cellphone policies. Validated by:
1. Pre-treatment balance: crash rates, demographics, road characteristics should be smooth at borders before treatment
2. Placebo borders: no discontinuity at borders where neither or both states have bans
3. Placebo outcomes: non-phone distractions (eating, grooming, radio) should show no border effect
4. Donut tests: excluding observations very close to the border

## Expected Effects and Mechanisms

**Primary hypothesis:** Fatal crashes decline discontinuously on the treated side of the border after the ban takes effect.

**Mechanism:** FARS distraction codes allow decomposition into phone-involved vs. non-phone-involved crashes. If the law works through reducing phone use while driving, only phone-coded crashes should show a border discontinuity.

**Magnitude expectation:** Small to moderate effect. Prior temporal studies find 3-8% reductions in fatal crashes. Given imperfect enforcement and compliance, the border effect may be smaller.

## Primary Specification

For crash i at distance d from border b in year-month t:

Y_ibt = α + τ · Treated_i + f(d_i) + γ_b + δ_t + ε_ibt

Where:
- Y is a fatal crash indicator (or crash count at the grid-cell level)
- Treated_i = 1 if crash occurred on the treated-state side after the ban
- f(d_i) is a local polynomial in distance to border (separate slopes each side)
- γ_b are border-pair fixed effects
- δ_t are year-month fixed effects

Bandwidth selection via Cattaneo-Idrobo-Titiunik (rdrobust). Inference clustered at county level (or border-pair level with wild bootstrap for few-cluster robustness).

## Data Source and Fetch Strategy

**NHTSA FARS (2015-2022):**
- Annual CSV files from NHTSA FTP/download site
- Person file + Accident file + Distract file
- Accident file contains latitude/longitude for geocoding
- Distract file links to crashes via ST_CASE with driver distraction codes
- ~39,000 fatal crashes per year nationally
- Phone distraction codes: 15 (cell phone), 16 (other electronic device)

**Geographic data:**
- State boundary shapefiles from US Census TIGER/Line
- Distance computation: Haversine from crash lat/lon to nearest border segment

**Sample construction:**
- Restrict to crashes within 50km of relevant state borders
- Years: 2015-2022 (3+ pre-treatment years for earliest adopters)
- Expected sample: ~10,000-15,000 fatal crashes in border zones

## Robustness Checks

1. Multiple bandwidths (10km, 20km, 30km, 50km)
2. Donut RDD (exclude crashes within 1km of border)
3. Placebo borders (where both/neither states have bans)
4. Placebo outcomes (non-phone distraction crashes)
5. Pre-treatment falsification (apply treatment date to pre-period)
6. Border-pair-level wild cluster bootstrap
7. Stacking across border pairs with pair-specific time trends
