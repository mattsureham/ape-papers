# Research Plan: H-2A Guestworker Expansion and Domestic Farm Worker Displacement

## Research Question
Does the rapid expansion of H-2A temporary agricultural guestworker certifications (tripling from 85,000 to 372,000 positions, 2012–2022) displace Hispanic domestic workers in U.S. agriculture, or do guestworkers complement the existing domestic labor force?

## Identification Strategy
**Triple-difference (DDD):** county × quarter × ethnicity

- **Treatment:** ln(H-2A certified positions + 1) in county c, year y, from DOL Foreign Labor Certification disclosure files
- **First difference:** High vs. low H-2A-expansion counties (continuous dose)
- **Second difference:** Pre vs. post expansion periods (continuous ramp 2012–2022)
- **Third difference:** Hispanic vs. non-Hispanic domestic workers within county-quarter cells in NAICS 11 (agriculture)
- **Fixed effects:** county-ethnicity, quarter-ethnicity, state-quarter (absorbs state-level ag shocks)

**Key identifying assumption:** Hispanic/non-Hispanic employment ratios in agriculture would have evolved similarly across high- and low-H-2A counties absent the expansion. H-2A certifications are driven by employer crop-cycle demand, which affects all workers; ethnicity provides the within-county contrast.

**Bartik IV (robustness):** National H-2A growth rate × county's initial (2012) share of state H-2A positions — isolates demand-pull variation from local sorting.

## Expected Effects and Mechanisms
- **Substitution hypothesis:** H-2A expansion displaces Hispanic domestic farm workers → negative effect on Hispanic employment, increased separations, reduced hires
- **Complementarity hypothesis:** H-2A fills seasonal/peak labor gaps that domestic workers avoid → null or positive effects on domestic Hispanic employment
- **Wage effects:** If substitution, Hispanic earnings fall; if complementarity, stable or rising

**Mechanism tests:**
- Separations (Sep): displacement via job loss
- New hires (HirA): crowding out of new entrants
- Heterogeneity by crop intensity (USDA NASS acreage)

## Primary Specification
```
Y_{c,q,e} = β × ln(H2A_{c,y}) × Hispanic_e + γ × ln(H2A_{c,y}) + δ × Hispanic_e + FE + ε_{c,q,e}
```
Where Y is employment/earnings/separations/hires, c = county, q = quarter, e = ethnicity, y = year.
Cluster SEs at county level (treatment varies at county-year).

## Data Sources
1. **QWI race/ethnicity panel** (Azure: `az://apepdata/derived/qwi/rh/ns/*.parquet`) — county × quarter × ethnicity × industry employment flows. NAICS 11 for agriculture; NAICS 23 and 72 for placebos.
2. **DOL Foreign Labor Certification** H-2A disclosure files (foreignlaborcert.doleta.gov) — annual employer-level H-2A certified positions with county FIPS. Files available 2012–2023 as Excel/CSV.

## Fetch Strategy
1. Download DOL H-2A disclosure files for FY2012–FY2023 from DOL website
2. Parse employer county FIPS, aggregate to county-year H-2A certified positions
3. Load QWI parquet from Azure for NAICS 11, 23, 72 — ethnicity A1 (non-Hispanic) and A2 (Hispanic)
4. Merge on county FIPS × quarter, construct treatment intensity
