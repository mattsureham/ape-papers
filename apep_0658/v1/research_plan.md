# Research Plan: Taxing Landlord Wealth

## Research Question
Does taxing secondary dwelling (rental property) owners reduce housing supply? Norway's 2022 wealth tax reform raised assessed market values of secondary dwellings from 90% to 100% and added a top bracket of 1.1% for wealth above NOK 20M. We test whether municipalities with higher pre-reform secondary dwelling ownership shares experienced larger declines in building permits, enterprise formation, and emigration.

## Identification Strategy
Continuous-treatment DiD at the municipality × year level.

**Treatment intensity**: Pre-reform (2021) share of secondary dwelling owners in each municipality. The reform is national and uniform, but binds differentially across municipalities based on pre-existing ownership structure.

**Specification**:
Y_{m,t} = α_m + γ_t + β × (SecondaryShare_m × Post_t) + X'δ + ε_{m,t}

where SecondaryShare_m is the 2021 share of secondary dwelling owners (standardized), Post_t = 1{t ≥ 2022}, and X includes county × year fixed effects.

**Key assumption**: Conditional on municipality and year fixed effects, the pre-reform secondary dwelling ownership share is uncorrelated with differential trends in outcomes.

**Exposure alignment**: The treatment variable (2021 secondary dwelling share of assessed value) captures municipal-level exposure to the reform, which raised the assessment ratio for secondary dwellings from 90% to 100% of market value. The directly affected population is the ~500,000 Norwegian households owning secondary dwellings, whose wealth tax liability increased proportionally to the assessed value of their secondary properties. Municipalities with higher secondary dwelling shares had more of their local property stock subject to the increased assessment, meaning more local wealth was directly exposed to the tax increase. The outcomes (building permits, enterprise formation, migration) are municipal aggregates that capture the local general equilibrium response to this differential tax shock. Note: the treatment measures municipal exposure, not individual-level treatment; the estimates capture reduced-form ITT effects on the local economy.

## Expected Effects and Mechanisms
1. **Building permits** (supply channel): Higher-intensity municipalities should see reduced new construction as investment returns fall
2. **Enterprise formation**: Landlord disinvestment may reduce property-related enterprise activity
3. **Emigration** (capital flight channel): Wealthy property owners may emigrate to avoid the tax
4. **Secondary dwelling ownership**: Direct reduction in number of secondary dwellings owned

Theoretical ambiguity: if the tax is fully passed through to renters, supply may not change. If capitalized into property values, the tax falls on current owners.

## Primary Specification
- Event study: β_τ × (SecondaryShare_m × 1{t = τ}) for τ ∈ {2010, ..., 2024}
- Main DiD: single post indicator
- Robustness: alternative treatment (wealth >20M share), randomization inference, leave-one-out by county

## Data Sources and Fetch Strategy
All from SSB (Statistics Norway) free JSON API (https://data.ssb.no/api/v0/):

| Table | Content | Coverage |
|-------|---------|----------|
| 10333 | Wealth tax by municipality | 2001-2024 |
| 09838 | Secondary dwelling ownership | 2010-2024 |
| 05940 | Building permits | 2000-2025 |
| 14012 | New enterprises | 2002-2024 |
| 05426 | Emigration | 1999-2024 |

No authentication required. CC BY 4.0 license. All confirmed via smoke tests in idea manifest.

## Diagnostics Requirements
- n_treated: municipalities with above-median secondary dwelling share (~468)
- n_pre: 12 years (2010-2021)
- n_obs: ~936 municipalities × 15 years ≈ 14,040
