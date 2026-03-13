# Research Plan: Dial Tone Roulette — The FCC Cellular Lottery and Local Economic Development

## Research Question

Did the staggered timing of FCC cellular license allocation via lottery (1984–1989) causally affect local economic development in U.S. counties? Specifically, did counties whose Cellular Market Areas (CMAs) received licenses earlier experience faster employment and establishment growth, and through which sectors did these effects propagate?

## Identification Strategy

**Staggered DiD exploiting lottery-induced timing variation.** The FCC allocated cellular licenses across 734 CMAs (306 MSAs + 428 RSAs) through a pure lottery system from 1984–1989. The processing order was determined by administrative round scheduling, not market characteristics. Treatment is defined as the year a CMA's first license was granted.

- **Estimator:** Callaway and Sant'Anna (2021) for heterogeneous treatment effects under staggered adoption
- **Unit of analysis:** County × year
- **Treatment:** Year CMA's first cellular license was granted (mapped to county via CMA-county crosswalk)
- **Control:** Not-yet-treated counties in later lottery rounds
- **Pre-trends:** 8+ years of CBP data (1975–1983) before earliest treatments

## Expected Effects and Mechanisms

**Primary hypothesis:** Earlier cellular access increases local employment and establishment counts, with effects concentrated in information-intensive sectors (services, FIRE, business services) rather than goods-producing sectors (manufacturing, mining).

**Mechanisms:**
1. **Communication cost reduction** → more efficient labor market matching → employment growth
2. **Business formation** → lower coordination costs → new establishments (especially services)
3. **Sectoral reallocation** → shift from goods to services, with information-intensive industries gaining disproportionately

**Placebo:** Manufacturing and mining sectors should show weaker effects (these sectors benefit less from mobile communication in this era).

## Primary Specification

Y_{ct} = α_c + γ_t + β × CellularAccess_{ct} + ε_{ct}

Where Y is log(employment) or log(establishments) at the county-year level, with county and year fixed effects. Callaway-Sant'Anna ATT(g,t) estimated separately by cohort g (year of first license grant).

## Data Sources

1. **FCC ULS** (l_cell.zip): License records for all 734 CMAs with grant dates, market IDs, A/B block identifiers. URL: https://data.fcc.gov/download/pub/uls/complete/l_cell.zip
2. **County Business Patterns** (CBP): Annual county-level employment, establishments, payroll from 1975–2000. Via Census Bureau API + Peckert harmonized panel (fpeckert.me/cbp).
3. **CMA-County crosswalk:** FCC MK.dat market records contain county FIPS mappings.

## Fetch Strategy

1. Download FCC ULS l_cell.zip → extract HD.dat (licenses) and MK.dat (markets)
2. Parse grant dates and CMA identifiers from HD.dat; parse CMA-county FIPS from MK.dat
3. Download Peckert harmonized CBP panel (1975–2000) for consistent NAICS employment/establishment data
4. Merge via county FIPS codes

## Key Risks

- **License grant ≠ service launch:** There may be a lag between FCC license grant and actual service activation. If lag is uniform, this is just a level shift; if correlated with CMA characteristics, it threatens identification. Mitigation: use grant date as ITT.
- **CMA-county mapping complexity:** Some CMAs span multiple counties. Will use population-weighted assignment.
- **Top-30 MSAs excluded:** These were awarded by hearing, not lottery. They serve as a natural boundary for the sample.
