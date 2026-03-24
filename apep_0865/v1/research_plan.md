# Research Plan: Last Call for Competition

## Research Question
Does marginal alcohol outlet entry — identified through Florida's quota liquor license lottery and statutory population thresholds — affect drinking-place employment, DUI arrests, and alcohol-related health outcomes?

## Identification Strategy
Two complementary designs:

### Design A: Population-Threshold RDD
Florida Statute 561.20 caps quota liquor licenses at 1 per 7,500 residents (benchmarked to 1999 population). When a county's cumulative population growth crosses a 7,500-resident increment, it becomes eligible for additional licenses. The running variable is distance to the next 7,500-increment boundary. Sharp cutoff: counties just crossing get new licenses; counties just below do not.

### Design B: License-Shock Event Study
County-year panel exploiting variation in the *number* of new quota licenses awarded. Some counties receive 0 new licenses in a given year; others receive 1-10+. Event study around years when counties receive their first new license in a spell.

### Key Identification Assumptions
- Counties cannot precisely manipulate population growth around the 7,500 threshold
- New license allocation is mechanical (formula-based) + lottery (random among applicants)
- No confounding county-level shocks coincide with threshold crossings

## Expected Effects and Mechanisms
- **Employment (NAICS 7224):** Positive — new licenses enable new drinking establishments
- **DUI arrests:** Ambiguous — more bars could increase or redistribute drinking
- **Health:** Ambiguous — density could increase alcohol consumption or shift from off-premise to on-premise

## Primary Specification
```
Y_{ct} = α + β · NewLicenses_{ct} + γ · X_{ct} + δ_c + θ_t + ε_{ct}
```
Where Y is county-quarter outcome, NewLicenses is the count of newly awarded quota licenses, δ_c are county FEs, θ_t are quarter FEs. Instrument: threshold-crossing indicator (RDD first stage).

## Data Sources
1. **BLS QCEW API**: County-level quarterly employment in NAICS 7224 (Drinking Places) and 7225 (Restaurants) for Florida, 2010-2024
2. **Census Population API**: Annual county population estimates for Florida, 2000-2024
3. **Florida DBPR**: Quota license data (new licenses by county-year, from public records)
4. **FDLE UCR**: DUI arrest counts by county (if API accessible)
5. **FL CHARTS**: Alcohol-related ED visits by county (if API accessible)

## Fetch Strategy
1. BLS QCEW via API (confirmed, have key)
2. Census population via API (confirmed, have key)
3. Construct treatment variable from population thresholds (no external data needed — we compute it from population increments)
4. Attempt FDLE/FL CHARTS for secondary outcomes; proceed with QCEW employment as primary if secondary sources unavailable
