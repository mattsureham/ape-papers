# Research Plan: Coming to the Nuisance

## Research Question

Do Right-to-Farm (RTF) law expansions that immunize Concentrated Animal Feeding Operations (CAFOs) from nuisance suits cause environmental justice sorting — specifically, do high-CAFO counties in treated states experience increases in low-income and minority population shares relative to similar counties in untreated states?

## Hypothesis

Banzhaf, Ma & Timmins (2019, JEP) theorize that removing legal recourse against polluters should reduce property values near pollution sources, attracting lower-income households through a Tiebout sorting mechanism. We test whether RTF shield-law expansions — which stripped residents' right to sue neighboring CAFOs — induced this "coming to the nuisance" pattern.

**Expected effects:**
- Property values decline in high-CAFO counties of treated states (FHFA HPI)
- Hispanic and low-income population shares increase (ACS demographics)
- Effects concentrated in high-CAFO-density counties; null in low-CAFO counties (placebo)

## Identification Strategy

**Triple-Difference (DDD):** State RTF amendment × County CAFO density × Post-treatment

- **State-level treatment:** 7 states passed major RTF expansions: ND (2012), MO (2014), IA (2017), NC (2017), NE (2019), WV (2019), FL (2021)
- **County-level intensity:** USDA NASS hog inventory quintiles (continuous treatment)
- **Time variation:** Staggered adoption 2012-2021

The triple-diff absorbs: state-level trends (high vs low CAFO counties within treated states), CAFO-level trends (high-CAFO counties across treated vs control states), and secular time trends.

**Estimator:** Callaway-Sant'Anna (2021) for staggered treatment timing, with county-level CAFO density as continuous moderator.

**Inference:** Wild cluster bootstrap at state level (7 treated + ~43 control = 50 clusters). Fisher randomization inference as robustness.

## Primary Specification

Y_{c,s,t} = α + β₁(RTF_s × Post_t × HighCAFO_c) + β₂(RTF_s × Post_t) + β₃(Post_t × HighCAFO_c) + γ_c + δ_t + ε_{c,s,t}

Where:
- Y = outcome (Hispanic share, poverty rate, median income, HPI)
- RTF_s = 1 if state passed RTF expansion by year t
- HighCAFO_c = county in top quintile of hog inventory
- γ_c = county FE, δ_t = year FE

## Data Sources

1. **Census ACS 5-year estimates (2009-2023):** County-level demographics
   - B02001 (race), B03003 (Hispanic origin), B19013 (median income), B17001 (poverty)
   - API: `api.census.gov/data/{year}/acs/acs5`

2. **USDA NASS QuickStats:** County-level hog inventory (2007, 2012, 2017, 2022 Census of Agriculture)
   - API: `quickstats.nass.usda.gov/api/api_GET`

3. **FHFA House Price Index:** State-level and MSA-level HPI
   - Download: `fhfa.gov/data`

## Outcome Variables

1. Hispanic population share (primary)
2. Poverty rate
3. Median household income
4. FHFA House Price Index (mechanism: property value channel)

## Robustness Checks

1. Low-CAFO county placebo (within treated states)
2. Pre-trend tests (event study)
3. Alternative CAFO density measures (cattle, poultry)
4. Wild cluster bootstrap p-values
5. Randomization inference (Fisher exact test)
6. Alternative bandwidth for CAFO intensity (terciles, quartiles)

## Method Notes

- ACS 5-year estimates pool data across years; I use the final year as the reference (e.g., 2018 ACS = "2014-2018" data, assigned to 2018)
- NASS Census of Agriculture is every 5 years; interpolate hog inventory between census years for annual panel
- Use pre-treatment (2007/2012) CAFO density to avoid endogeneity
