# Research Plan: Crowding Out the Smallest

## Research Question
Do SBA small business size standard increases — which expand the pool of firms eligible for federal set-aside contracts — geographically redistribute procurement dollars away from counties with genuinely small firms toward counties with larger firms that newly qualify?

## Identification Strategy
**Staggered DiD (Callaway-Sant'Anna 2021).** Treatment is defined at the NAICS code level: industry j receives a size standard increase at time t*_j. Treatment timing varies across 200+ NAICS codes between 2010 and 2023, driven by SBA's mandated sector-rotation review schedule (not responsive to local economic conditions).

**Unit of analysis:** County × NAICS code × fiscal year.

**Key identifying assumption:** Absent the size standard change, procurement in treated NAICS codes would have evolved in parallel with not-yet-treated NAICS codes in the same county.

**Threat to identification:** Simultaneous industry-specific demand shocks. Addressed by:
1. Event-study pre-trend tests
2. Never-treated NAICS codes as comparison group
3. County × year FE absorb local demand shocks
4. NAICS-sector × year FE absorb broad industry trends

## Expected Effects and Mechanisms
- **Primary:** Total set-aside procurement shifts toward counties with higher pre-treatment average firm size in the treated NAICS code
- **Mechanism (eligibility dilution):** Newly qualifying medium firms in suburban/metro counties outcompete genuinely small rural firms for the same set-aside contracts
- **Secondary:** Employment effects in treated NAICS codes (QCEW), distinguishing rural vs. urban counties

## Primary Specification
```
Y_{c,j,t} = α + β × Post_{j,t} + γ_c + δ_j + θ_t + ε_{c,j,t}
```
Where Y is log procurement dollars (or count of set-aside contracts), Post_{j,t} = 1 after NAICS j receives size standard increase, with county FE, NAICS FE, and year FE. Callaway-Sant'Anna group-time ATT accounts for staggered timing.

Heterogeneity by county pre-treatment firm size (small-firm-dominant vs. large-firm-dominant counties).

## Data Sources and Fetch Strategy

### 1. USAspending (Primary outcome)
- **Source:** USAspending.gov bulk download award files (contracts)
- **Variables:** Total obligated amount, NAICS code, place of performance (county FIPS), fiscal year, type of set-aside
- **Years:** FY2008–FY2024
- **Approach:** Use USAspending API for targeted NAICS × county queries

### 2. SBA Size Standard History (Treatment timing)
- **Source:** SBA.gov size standard tables + Federal Register documents
- **Variables:** NAICS code, size standard (employees or revenue), effective date of change
- **Approach:** Construct treatment panel from published SBA tables

### 3. QCEW (Mechanism/employment)
- **Source:** BLS Quarterly Census of Employment and Wages API
- **Variables:** County × NAICS employment and wages, quarterly
- **Years:** 2008–2024

### 4. County Business Patterns (Firm size distribution)
- **Source:** Census CBP
- **Variables:** Establishment counts by employee-size class, by county × NAICS
- **Years:** Pre-treatment cross-section for heterogeneity
