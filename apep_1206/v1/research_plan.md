# Research Plan: Shell Games at the Municipal Border

## Research Question
Do Swiss municipal corporate tax cuts attract real economic activity (employment-rich establishments) or letterbox companies (employment-light entities)? The STATENT establishment-by-employment decomposition enables a direct test.

## Identification Strategy
Municipality-level panel DiD exploiting within-municipality Steuerfuss (corporate tax multiplier) changes. ~800+ municipalities change their rate at least once during the 2011-2023 STATENT panel. Treatment is a binary indicator for Steuerfuss decreases ≥5 percentage points. Event study around large cuts confirms parallel pre-trends.

**Primary outcome:** Employment-per-establishment ratio (total employment / number of establishments). If β < 0, tax cuts attract employment-light (letterbox) entities.

**Key tests:**
- Triple-difference: tertiary sector (services, holding companies) vs. secondary sector (manufacturing) — letterbox firms cluster in tertiary
- Placebo: natural-person Steuerfuss changes (should not affect corporate location decisions)
- Leave-one-out by canton (Zug sensitivity)

## Expected Effects and Mechanisms
If tax competition is partly zero-sum fiscal transfer, municipal tax cuts should disproportionately attract paper entities — holding companies, IP vehicles, management HQs with minimal local employment. The employment-per-establishment ratio should decline more in tertiary sectors where letterbox structures are feasible.

## Primary Specification
Y_{it} = β × TaxCut_{it} + α_i + γ_t + X_{it}δ + ε_{it}

Where i = municipality, t = year, Y = employment/establishments, TaxCut = indicator for Steuerfuss ≤ previous year minus 5pp. Municipality and year fixed effects. Clustered SEs at canton level (26 clusters).

For event study: leads and lags around the first large Steuerfuss cut per municipality.

## Data Sources
1. **BFS STATENT** (PXWeb API): Establishment counts and employment by municipality × sector × year, 2011-2023
2. **Municipal Steuerfuss data**: Corporate tax multipliers by municipality and year (BFS/cantonal tax offices)
3. **BFS municipal statistics**: Population, area, language region for controls

## Fetch Strategy
1. Query BFS PXWeb API for STATENT establishment and employment counts at municipality level
2. Download Steuerfuss data from ESTV/cantonal sources
3. Apply SMMT merger mapping for longitudinal consistency
4. Merge datasets on BFS Gemeindenummer × year
