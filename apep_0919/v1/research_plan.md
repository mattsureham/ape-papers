# Research Plan: Innovation Networks and Local Job Creation

## Research Question
Do innovation shocks in socially-connected counties transmit to local employment growth? Specifically, does a county experiencing exogenous increases in patent grants — caused by quasi-random examiner leniency in its social-network neighbors — see higher employment in innovation-intensive sectors?

## Identification Strategy
**Shift-share IV (Bartik) with network-weighted shares:**

- **Endogenous variable (X):** PatentShock_c = Σ_d(SCI_{cd} × GrantRate_d) — SCI-weighted patent grant rate in connected counties
- **Instrument (Z):** Z_c = Σ_d(SCI_{cd} × ExaminerLeniency_d) — SCI-weighted leave-one-out examiner grant propensity
- **Outcome (Y):** County-quarter employment from QWI (total, by NAICS sector)

**Why this works:**
1. Examiner assignment within art units is quasi-random (Righi & Simcoe 2019; Sampat & Williams 2019 AER)
2. SCI weights are predetermined (Facebook friendships, fixed cross-section)
3. Satisfies Borusyak, Hull, Jaravel (2022) random-shocks condition

## Expected Effects and Mechanisms
- **Primary:** Positive effect on total employment — knowledge spillovers through social ties enable commercialization, hiring, and technology adoption
- **Mechanism test:** Stronger effects in high-tech/professional sectors (NAICS 54, 51) than in non-innovative sectors (retail 44-45, food service 72)
- **Placebo:** No effect of SCI-weighted examiner leniency on employment in non-patent-intensive counties or non-innovative industries

## Primary Specification
Second-stage: Y_{ct} = β × PatentShock_{ct} + X_{ct}'γ + α_c + δ_t + ε_{ct}
First-stage: PatentShock_{ct} = π × Z_{ct} + X_{ct}'γ + α_c + δ_t + ν_{ct}

- Unit: county (c) × quarter (t)
- Period: 2005Q1–2012Q4 (32 quarters)
- FE: county + quarter
- Clustering: state level (~50 clusters)
- Controls: geographic-distance-weighted employment, commuting zone FE, trade exposure

## Data Sources and Fetch Strategy

### 1. Patent Examiner Data (BigQuery)
- `patents-public-data.uspto_oce_pair.application_data`: 9.8M applications with examiner_id
- `patents-public-data.patentsview.location_201908`: County FIPS for inventor locations
- Construct: leave-one-out examiner grant propensity by art-unit-year
- Aggregate to county-year level

### 2. Social Connectedness Index (Azure Blob)
- `raw/sci/v2026/us_counties.zip`: County × county SCI pairs
- Predetermined friendship weights (Facebook)
- Use raw SCI values, normalize by focal county's total connections

### 3. Employment Data (Azure QWI / Census QWI API)
- Azure: `derived/qwi/sa/ns/*.parquet` — county × quarter × NAICS employment
- Fallback: Census QWI API (state-level downloads by county)
- Outcomes: total employment, beginning-of-quarter emp, new hires, earnings

### 4. Controls
- Geographic distance between county pairs (from centroids)
- Commuting zone assignments
- Industry employment shares (for Bartik-style controls)

## Key Risks
1. **SCI endogeneity:** Friendships reflect past economic ties → control for distance, trade, commuting
2. **SUTVA:** Random leniency shocks may cancel across network → focus on asymmetric exposure
3. **Weak instrument in non-patent counties:** Restrict to counties with >10 patent apps/year
4. **Temporal aggregation:** Patents are slow to commercialize → test lags of 1-4 quarters
