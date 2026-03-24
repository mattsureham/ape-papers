# Research Plan: Who Moves When Taxes Change?

## Research Question
Do high-income households migrate across state lines in response to state income tax changes, and if so, what is the full income-gradient of migration elasticities? This paper exploits (1) 37+ staggered state income tax rate changes and (2) the 2017 TCJA SALT deduction cap as a differential within-state shock to estimate income-bracket-specific migration responses from the universe of U.S. tax filers.

## Identification Strategy

### Strategy 1: Triple-Difference on State Tax Changes
- **First difference:** High-income filers (AGI $200K+) vs. middle-income ($50-75K) within the same state
- **Second difference:** States enacting top rate changes of ≥1pp vs. states with stable rates
- **Third difference:** Pre vs. post enactment
- Estimator: Callaway-Sant'Anna staggered DiD with never-treated states as controls

### Strategy 2: SALT Cap as Differential Shock (2018)
- The $10K SALT cap raised the effective tax burden disproportionately for high-income itemizers
- **Treatment intensity:** State-level average SALT deduction per itemizer (from 2017 SOI zip-code data)
- **Within-state variation:** Bracket 7 ($200K+) vs. Bracket 4 ($50-75K) — differential SALT exposure
- Pre-post 2018, within high-SALT states, compare migration change across brackets

### Strategy 3: Dose-Response
- Continuous treatment = state-level average SALT deduction per itemizer
- Interact with Post2018 × AGI bracket indicators
- Identifies heterogeneous treatment effects across the full income distribution

## Expected Effects and Mechanisms
- **Prior:** Young & Varner (2011, 2016) find near-zero millionaire elasticities; Kleven, Landais & Saez (2013) find ~1.0 for European superstars; Moretti & Wilson (2017) find significant inventor responses
- **Expected:** Positive income gradient — higher-income brackets more responsive, but smaller than Kleven estimates
- **Mechanisms:** (a) Outflow vs. inflow decomposition; (b) AGI-weighted vs. return-weighted (few rich movers carry large dollars); (c) State pairs with border proximity

## Primary Specification
```
Y_{s,t,b} = α + β(TaxChange_s × Post_t × HighIncome_b) + γ_{s,b} + δ_{t,b} + θ_{s,t} + ε_{s,t,b}
```
Where:
- Y = net migration rate (net returns / total returns) for state s, year t, AGI bracket b
- TaxChange_s = indicator for state enacting ≥1pp top rate change
- HighIncome_b = indicator for brackets 6-7 ($100K+)
- Fixed effects: state×bracket, year×bracket, state×year
- Clustering: state level (51 clusters)

## Data Sources
1. **IRS SOI State-to-State Migration Files** (2011-2022): `inmigall.csv` files from irs.gov/pub/irs-soi/. 51 jurisdictions × 7 AGI brackets × 12 years = 4,284 cells. Variables: total returns, outflow, inflow, outflow AGI, inflow AGI.
2. **State Tax Rate Changes:** Tax Foundation historical tables + NBER TAXSIM documentation. Manual coding of 37+ top-rate changes ≥1pp.
3. **SALT Exposure:** 2017 SOI zip-code data on average SALT deductions by state.
4. **Controls:** BLS LAUS state unemployment; BEA SAINC state personal income; Census population estimates.

## Fetch Strategy
- IRS SOI: Direct CSV download from irs.gov URLs (confirmed working in smoke test)
- Tax rates: Tax Foundation API or manual coding from published tables
- SALT exposure: 2017 SOI individual statistics by state
- Controls: FRED API (unemployment, income)
