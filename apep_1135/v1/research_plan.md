# Research Plan: The Waste Wall — National Sword and US Waste Management Labor Markets

## Research Question

What are the labor market effects of China's 2018 National Sword policy on US waste management workers? Specifically, did the near-total collapse of Chinese recyclable waste imports (99.998% reduction in plastic waste) cause employment losses, wage changes, and firm restructuring in US waste management and scrap wholesaling sectors?

## Identification Strategy

**Design:** Continuous treatment DiD exploiting county-level variation in pre-shock waste industry exposure. Counties with higher pre-period waste management employment shares experienced larger effective treatment from the National Sword shock.

**Treatment:** County-level "waste exposure" = pre-period (2015-2017) waste management (NAICS 562) employment share of total county employment, interacted with the national-level shock. China's enforcement began January 2018, with announcement in July 2017.

**Estimator:** Callaway-Sant'Anna (2021) with treatment defined as above-median waste exposure counties. Event study with quarterly leads and lags around 2018Q1. Triple-difference using NAICS 562 (waste management) vs NAICS 541 (professional services, unaffected) within the same counties.

**Key advantages:**
- The shock is exogenous to US county-level conditions (Chinese regulatory decision)
- QWI provides county × 3-digit NAICS × quarter granularity
- The collapse is massive and sharp (99.998%), minimizing measurement error
- Built-in placebo: non-waste sectors in the same counties

## Expected Effects and Mechanisms

**Primary hypothesis:** High waste-exposure counties experience employment declines in NAICS 562 (waste management) and NAICS 423 (merchant wholesalers/scrap) after 2018Q1. The shock reduced demand for waste processing labor as recycling became unprofitable without Chinese buyers.

**Mechanism:** "The Waste Wall" — when China stopped buying the world's recyclables, US municipal recycling programs shifted from revenue-generating to cost-bearing. Recycling facilities closed or cut staff, waste management firms restructured toward landfill operations.

**Expected magnitude:** Moderate negative effects on waste sector employment (5-15% reduction in high-exposure counties). Smaller effects on wages (downward rigidity). Potential reallocation to landfill operations.

## Primary Specification

```
Y_{c,s,t} = β₁ Post_t × HighExposure_c + α_c + δ_t + γ_{s,t} + ε_{c,s,t}

Where:
- Y = log employment, earnings per worker, hires, separations
- c = county, s = state, t = quarter
- Post_t = 1(t ≥ 2018Q1)
- HighExposure_c = above-median pre-period NAICS 562 share
- α_c = county FE
- δ_t = quarter FE
- γ_{s,t} = state × quarter FE (absorbs state-level trends)

Triple-diff: Add industry dimension (NAICS 562 vs 541)
```

## Data Sources

1. **QWI (Azure):** `az://derived/qwi/rh/n3/*.parquet` — 460M rows, county × 3-digit NAICS × race × quarter. Employment, earnings, hires, separations.

2. **Comtrade API:** US-China waste trade flows (HS 3915 plastic waste, HS 4707 waste paper, HS 7204 ferrous scrap) for motivation and aggregate shock magnitude.

3. **Census County Business Patterns:** Annual county-level establishment counts by NAICS for robustness.

## Robustness Checks

1. Placebo sectors (NAICS 541 professional services, NAICS 722 food services)
2. Event study — parallel pre-trends in waste employment across high/low exposure counties
3. Continuous treatment intensity (waste employment share) instead of binary
4. Donut hole excluding 2017Q3-Q4 (announcement period)
5. Race decomposition: differential effects by race (waste management disproportionately employs minority workers)
6. Alternative exposure measures (establishment counts instead of employment)
