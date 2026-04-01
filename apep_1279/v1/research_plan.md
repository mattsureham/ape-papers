# Research Plan: The Inertia Break — WWI Military Service and the Acceleration of American Structural Transformation

## Research Question
Did compulsory military service during World War I accelerate the farm-to-manufacturing transition by breaking agricultural attachment inertia? We use the WWI draft-eligibility age cutoff as a sharp discontinuity to estimate the causal effect of military service exposure on farm exit, occupational upgrading, and geographic mobility.

## Why It Matters
The farm-to-manufacturing transition is the defining economic transformation of early 20th-century America. Yet the mechanisms that broke individual-level agricultural attachment — keeping millions on subsistence farms despite higher urban wages — remain poorly understood. We provide the first causal evidence that forced occupational disruption (military service) permanently altered labor allocation, suggesting that inertia and attachment costs are first-order barriers to structural transformation.

## Identification Strategy

### Primary: Regression Discontinuity at Draft-Eligibility Age Cutoff
- **Running variable:** Age in 1910 (equivalently, birth year)
- **Cutoff:** Age 14 in 1910 (turning 21 by June 1917 = first-draft eligible)
- **Treatment:** Men aged 14+ in 1910 faced draft registration and potential induction
- **Control:** Men aged 13 in 1910 (turning 20 in 1917 = NOT eligible until third registration in September 1918, when war was nearly over)
- **Bandwidth:** Ages 10-17 in 1910 (births 1893-1900), with standard optimal bandwidth selection

### Supporting: Nativity-Based Difference-in-Differences
- Within draft-eligible ages, native-born citizens faced the draft while foreign-born non-citizens were EXEMPT
- DiD: (draft-eligible vs not) × (native-born vs foreign-born)
- Addresses concerns about age-specific secular trends

### Heterogeneity: County Agricultural Dependence
- Counties with higher 1910 agricultural employment share should show larger effects
- DDD: (draft-eligible vs not) × (high-ag vs low-ag counties) × (1910 vs 1920)

## Data
- **Source:** IPUMS MLP Linked Panel, 1910-1920 (`az://derived/mlp_panel/linked_1910_1920.parquet`)
- **Size:** 43.9 million linked individuals
- **Key variables:** age (1910), occupation (occ1950), occupational income score (occscore), farm residence (farm), county (countyicp), nativity (nativity/bpl), race, marital status, literacy, homeownership
- **Treatment sample:** ~10.7 million draft-eligible men (ages 14-23 in 1910)
- **Control sample:** ~3 million too-old men; ~5 million too-young men

## Primary Outcomes
1. **Farm exit rate:** P(farm=1 in 1910, farm=0 in 1920)
2. **Occupational income score change:** Δoccscore (1920 - 1910)
3. **Geographic mobility:** P(different county in 1920 vs 1910)
4. **Manufacturing entry:** P(manufacturing occupation in 1920 | farm in 1910)

## Expected Effects
- Draft-eligible men should show HIGHER farm exit rates (disruption breaks inertia)
- Occupational income scores should INCREASE (manufacturing pays more than farming)
- Geographic mobility should INCREASE (military service breaks local ties)
- Effects should be LARGER in high-agricultural-dependence counties

## Specification
```
Y_i = α + β₁·DraftEligible_i + f(age_i) + X_i'γ + ε_i
```
Where f(age) is a polynomial in the running variable (age in 1910), and X includes race, nativity, marital status, and literacy controls. Standard errors clustered at county level.

## Robustness
1. Varying RD polynomial order and bandwidth
2. Nativity-based DiD as alternative identification
3. Placebo cutoffs at non-draft ages
4. Subsample by race (Black vs White — differential draft experiences)
5. McCrary density test at cutoff
6. Donut-hole RD excluding ages immediately at cutoff
