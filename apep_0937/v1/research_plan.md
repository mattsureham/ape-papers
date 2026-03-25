# Research Plan: Building an Industry from Ashes

## Research Question
Did the 2017 Grenfell Tower fire and subsequent regulatory cascade (Hackitt Review 2017, EWS1 2019, Fire Safety Act 2021, Building Safety Act 2022) create a new fire safety industry, and did this industry form faster in local authorities with greater exposure to the cladding crisis (measured by pre-Grenfell high-rise flat density)?

## Identification Strategy
**Continuous-treatment DiD** at the local authority level.

- **Treatment intensity:** Pre-Grenfell (2016) share of dwellings that are flats, from VOA Council Tax dwelling stock data. LAs with more flats (especially in high-rise buildings) faced greater demand for fire safety assessment, cladding remediation, and building inspection services.
- **Treatment timing:** June 14, 2017 (Grenfell fire), with staggered regulatory intensification:
  - June 2017: Grenfell fire (immediate shock)
  - December 2017: Hackitt Review interim report
  - December 2019: EWS1 form requirement (RICS)
  - October 2021: Fire Safety Act
  - April 2022: Building Safety Act
- **Unit of observation:** Local authority × month (326 English LAs × ~180 months, 2010–2024)

**Specification:**
```
Y_lt = α_l + γ_t + β(FlatShare_l × Post_t) + X_lt'δ + ε_lt
```
where Y_lt is monthly fire safety firm incorporations in LA l at month t.

**Placebos:**
1. Non-fire construction SICs (electrical installation 43210, plumbing 43220) — should not respond to Grenfell
2. Scotland as geographic control — different building regulations, devolved housing policy
3. Pre-Grenfell placebo dates (2013, 2015) — should yield null

## Expected Effects and Mechanisms
- **Primary:** LAs with higher flat shares should see disproportionately more fire safety firm incorporations post-Grenfell
- **Mechanism 1 (Regulatory demand):** Each regulatory milestone creates new compliance requirements, generating demand for specialist firms
- **Mechanism 2 (Market creation):** EWS1 forms made ~1M apartments unmortgageable until certified — creating urgent demand for assessors
- **Mechanism 3 (Speed of formation):** If industry forms slowly in high-demand areas, the regulatory response prolonged the housing market freeze

## Primary Specification
Callaway-Sant'Anna not needed (single treatment date, continuous intensity). OLS with LA and month FE, clustering SE at LA level. Event study specification with FlatShare × YearMonth dummies for dynamic treatment effects.

## Data Sources and Fetch Strategy

### 1. Companies House Free Company Data Product
- **URL:** Bulk CSV download from Companies House
- **Content:** All active/dissolved UK companies with SIC codes, incorporation date, registered office postcode
- **Fire safety SIC codes:** 84250 (Fire service activities), 71200 (Technical testing and analysis), 80200 (Security systems service activities), 71121/71129 (Engineering activities), 43999 (Other specialised construction)
- **Control SIC codes:** 43210 (Electrical installation), 43220 (Plumbing), 43290 (Other construction installation)

### 2. VOA Council Tax Dwelling Stock
- **URL:** data.gov.uk or VOA direct — annual LA-level dwelling counts by property type (flat, terraced, semi, detached)
- **Purpose:** Construct pre-Grenfell (2016) flat share as treatment intensity

### 3. NSPL (National Statistics Postcode Lookup)
- **URL:** ONS Geography or postcodes.io API
- **Purpose:** Map Companies House postcodes to local authorities

### 4. Building Safety Remediation Data (supplementary)
- **URL:** GOV.UK building safety programme statistics
- **Purpose:** Validate treatment intensity — LAs with more remediation activity should show stronger effects
