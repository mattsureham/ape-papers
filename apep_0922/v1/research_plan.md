# Research Plan: Dissolving the Monopoly? Alkaline Hydrolysis Legalization and Funeral Industry Competition

## Research Question
Does legalizing alkaline hydrolysis (water cremation) — a lower-cost alternative to traditional burial and cremation — affect funeral industry structure, employment, and wages? Or does the "grief premium" (supranormal markups sustained by information asymmetry and emotional vulnerability) persist despite legal market opening?

## Identification Strategy
**Staggered DiD (Callaway-Sant'Anna 2021).** 23 US states legalized alkaline hydrolysis between 2003 and 2023. 10 states adopted during the 2014-2023 data window (AL, CA, NV in 2017; NC, UT in 2018; WA in 2020; OK in 2021; AZ, HI in 2022; VA in 2023). 28 never-treated states + DC serve as controls. 13 states that adopted before 2014 are always-treated and excluded from CS-DiD estimation.

Treatment is at the state level. Outcome is at the county level (establishments) and state level (employment, wages). Standard errors clustered at the state level.

## Expected Effects and Mechanisms
- **If AH competition bites:** More establishments (new AH entrants), lower employment/wages per establishment (competitive pressure on incumbents), substitution from 812210 to 812220.
- **If the grief premium persists:** No detectable change in establishment counts, employment, or wages — legal barriers are not the binding constraint, behavioral barriers (grief, time pressure, social norms) dominate.
- **Price channel:** AH costs ~$2,500 vs cremation ~$6,280 vs burial ~$8,300. If consumers switch, incumbents face pressure.

## Primary Specification
$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot D_{ct} + \epsilon_{ct}$$
Using CS-DiD: ATT(g,t) for each treatment cohort g at time t, aggregated to overall ATT.
- County-level: $Y_{ct}$ = number of funeral home establishments in county $c$, year $t$
- State-level: $Y_{st}$ = ln(employment), ln(avg weekly wage) in state $s$, year $t$

## Data Source and Fetch Strategy
- **BLS QCEW API**: Annual data for NAICS 812210 (Funeral Homes) and 812220 (Cemeteries/Crematories), 2014-2023
- Endpoint: `https://data.bls.gov/cew/data/api/YEAR/a/industry/NAICS.csv`
- County-level (agglvl_code=78): establishment counts (~2,791 counties/year)
- State-level (agglvl_code=58): employment, wages (50 states, no suppression)
- Quarterly data available but annual preferred for stability

## Treatment Timing
| Year | States |
|------|--------|
| 2003 | MN |
| 2009 | ME, OR |
| 2010 | FL, KS |
| 2011 | MD, CO |
| 2012 | GA, IL |
| 2013 | TN |
| 2014 | ID, VT, WY |
| 2017 | AL, CA, NV |
| 2018 | NC, UT |
| 2020 | WA |
| 2021 | OK |
| 2022 | AZ, HI |
| 2023 | VA |
