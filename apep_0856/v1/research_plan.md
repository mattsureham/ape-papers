# Research Plan: The Stability Paradox — Tipped Minimum Wages and Racial Inequality in U.S. Restaurants

## Research Question
Do One Fair Wage (OFW) policies — which eliminate the tipped subminimum wage — reduce racial inequality in restaurants? Specifically, do they reduce both the Black-White *earnings* gap and the Black-White *employment stability* gap, or only one?

## The Paradox
Smoke test evidence reveals a paradox: OFW states eliminate the Black-White earnings gap in restaurants ($10 vs $115 gap in tip-credit states) but leave the employment stability gap untouched (10.1pp vs 9.8pp separation rate gap). This separation of mechanisms implies that tipping discrimination operates through wages, while employer-side discrimination in hiring/retention operates through a separate channel that wage policy cannot reach.

## Identification Strategy
1. **Cross-state comparison (motivating fact):** 7 OFW states (AK, CA, MN, MT, NV, OR, WA) vs 44 tip-credit states. TWFE with state and year FEs, continuous tipped MW treatment.
2. **Event studies (causal identification):** Large within-state tipped MW changes in NY ($2.50→$7.50, 2015-2020), IL ($4.95→$9.00, 2019-2022), AZ (Prop 206, 2017+). Pre-trend tests validate parallel trends.
3. **DDD:** (OFW × time × Black) vs (tip-credit × time × Black) with within-state, within-year, across-race variation.
4. **Placebo industry:** Finance/professional services (NAICS 52/54) — minimal tipping, should show no tipped MW effect.

## Expected Effects
- **Earnings:** OFW compresses Black-White gap (consistent with Neumark & Wohl 2024 NBER)
- **Stability:** OFW does NOT compress Black-White separation rate gap (the new finding)
- **Mechanism:** Tipping discrimination → wage channel; employer statistical discrimination → stability channel

## Primary Specification
```
Y_{c,s,r,t} = α + β₁(TippedMW_{s,t} × Black_r) + β₂(TippedMW_{s,t}) + β₃(Black_r) + γ_c + δ_t + ε_{c,s,r,t}
```
Where Y = EarnS or Sep/Emp, c=county, s=state, r=race (Black/White), t=quarter. SE clustered by state.

## Data Sources
1. **QWI Race×Ethnicity Panel:** `az://derived/qwi/rh/n3/**/*.parquet` — 143.9M rows, county × quarter × NAICS × race, 2000-2025. Filter: NAICS 722 (restaurants).
2. **State tipped minimum wage history:** DOL Wage & Hour Division data + Vaghul-Zipperer (2016 EPI, public).
3. **State regular minimum wage:** FRED API (confirmed).

## Data Fetch Strategy
1. Query Azure DuckDB for QWI NAICS 722, races A1 (White) and A2 (Black), years 2010-2023
2. Download state tipped MW panel from DOL/EPI
3. Merge by state × quarter
4. Construct: earnings gap, separation rate gap, tipped MW ratio

## Key Robustness
- Event study pre-trends for NY, IL, AZ phase-ins
- Wild cluster bootstrap (state-level clustering with ~50 clusters)
- HonestDiD/Rambachan-Roth sensitivity
- Placebo: NAICS 52/54 (finance/professional services)
- Leave-one-out: drop CA (largest OFW state)
