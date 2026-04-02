# Research Plan: When the Grocery Store Leaves

## Research Question
Do SNAP-authorized supermarket closures cause adverse birth outcomes? We estimate the causal effect of losing proximate access to affordable fresh produce on low birth weight, preterm birth, and gestational diabetes rates.

## Motivation
Hoynes, Schanzenbach, and Almond (ReStat 2011) showed that food stamp *introduction* improved birth outcomes. This paper runs the mirror experiment: food access *removal*. Allcott, Diamond, Dubé, Gentzkow, and Shapiro (QJE 2019) found that food desert closures don't change purchasing behavior — but purchasing ≠ health. The causal chain from maternal nutrition to birth outcomes operates through a tight 9-month biological window where nutritional deprivation has rapid consequences.

## Identification Strategy
**Primary: Event-study DiD.** Treatment = county-year loses one or more SNAP-authorized supermarkets (store_type = supermarket/large grocery). County + year FE. Event-study specification with leads/lags around closure events.

**IV: Corporate chain bankruptcy shocks.** National chain bankruptcy events provide plausibly exogenous variation in local supermarket closures:
- A&P / Pathmark (2015): ~300 stores across NE US
- Tops Markets (2018): 169 stores in upstate NY
- Southeastern Grocers / Winn-Dixie (2018): ~580 stores in SE US
- Lucky's Market (2020): 32 stores in multiple states
- Earth Fare (2020): 50 stores across eastern US

IV exclusion: corporate headquarters' financial distress is orthogonal to local health trends conditional on county and year FE. First stage: bankruptcy × pre-existing chain presence → store closures.

## Expected Effects and Mechanisms
- **Low birth weight:** Increase (nutritional deprivation channel)
- **Preterm birth:** Increase (stress + nutrition)
- **Gestational diabetes:** Ambiguous (reduced caloric intake could decrease, but shift to processed food could increase)
- **Mechanism test:** Effects should be larger for Medicaid-covered births (lower-income, fewer alternatives) than privately insured births

## Primary Specification
```
Y_{ct} = α + β × PostClosure_{ct} + γ_c + δ_t + X_{ct}' θ + ε_{ct}
```
Where:
- Y_{ct}: birth outcome in county c, year t
- PostClosure_{ct}: indicator for ≥1 supermarket closure in county c by year t
- γ_c, δ_t: county and year fixed effects
- X_{ct}: time-varying controls (unemployment rate, population)
- Cluster SEs at county level

IV first stage:
```
Closure_{ct} = π₀ + π₁ × (ChainPresence_c × PostBankruptcy_t) + γ_c + δ_t + v_{ct}
```

## Data Sources
1. **SNAP Retailer Database:** USDA FNS historical retailer data (2005-2025). ~703K retailers total, ~35K supermarket-class exits. Store type, authorization dates, county FIPS.
2. **CDC WONDER Natality:** County-year birth outcome data (2016-2024). Low birth weight, preterm, gestational diabetes, payment source. 609 counties with ≥100K population (79% of US births).
3. **BLS LAUS:** County-level unemployment rates for controls.

## Fetch Strategy
1. CDC WONDER: Query API for natality expanded data, county-level
2. SNAP retailers: Download from USDA FNS SNAP retailer locator/historical data
3. BLS LAUS: FRED API for county unemployment

## Key Risks
- CDC WONDER may suppress small-cell counts → focus on large counties (≥100K pop)
- SNAP retailer historical data may require scraping if bulk download unavailable
- Chain bankruptcy timing must be precisely identified
- Alternative food sources (dollar stores, convenience stores) may attenuate effects
