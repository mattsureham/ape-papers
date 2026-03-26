# Research Plan: One Fair Wage and the Racial Earnings Gap

## Research Question
Does eliminating the tipped subminimum wage reduce the Black-White earnings gap in food services? We name the mechanism the **tipping penalty** — the hypothesis that tip-credit regimes disproportionately suppress minority earnings because customer discrimination transmits directly into take-home pay when base wages are low.

## Policy Background
The FLSA permits employers to pay tipped workers as little as $2.13/hr (unchanged since 1991), crediting tips toward the regular minimum wage. Seven "One Fair Wage" (OFW) states never allowed a tip credit: AK, CA, MN, MT, NV, OR, WA. Key reforms: Arizona Proposition 206 (Jan 2017, raised tipped MW from $5.05 to indexed path toward parity); DC Initiative 82 (May 2023); Michigan court ruling (2024).

## Identification Strategy

**Primary: Difference-in-Differences-in-Differences (DDD)**
- Treatment: states that reformed tipped MW (AZ 2017 as flagship) vs. states that kept $2.13 federal floor
- Within-state control: retail trade (NAICS 44-45) vs. accommodation & food services (NAICS 72) — retail has no tipping, same low-wage labor market
- Within-industry control: White workers vs. Black/Hispanic workers — isolates racial gap closure from general wage effects
- DDD coefficient: differential change in minority earnings in food services in reforming states, net of retail trends and white-worker trends

**Secondary: Event-study DiD on AZ Prop 206**
- AZ treated Jan 2017; border states (NM, UT, CO, NV) as controls
- Pre-trend test: 2010Q1–2016Q4 (7 years, 28 quarters)
- Post-treatment: 2017Q1–2024Q4 (8 years)
- Callaway-Sant'Anna for staggered robustness (AZ, DC, MI timing)

**Placebo tests:**
1. Healthcare (NAICS 62) — no tipping, similar low-wage minority share
2. Professional services (NAICS 54) — high-wage, no tipping
3. White-White earnings ratio (should show no DDD effect)

## Data
- **Source:** QWI LEHD, race×ethnicity × NAICS sector, on Azure (`derived/qwi/rh/ns/*.parquet`)
- **Unit:** state × quarter × industry × race/ethnicity
- **Period:** 2005Q1–2024Q4 (80 quarters)
- **Key variables:** EarnS (avg monthly earnings), Emp (employment), HirA (all hires), Sep (separations)
- **Sample:** All 51 states, NAICS 72 (food services) and 44-45 (retail, control)

## Expected Effects
- AZ reform → 5-8pp increase in Black-White earnings ratio in NAICS 72
- Mechanism: base wage floor lifts minority earnings more because tips compensate less for discrimination when base is higher
- No disemployment expected (consistent with minimum wage literature for moderate increases)
- DDD isolates: not general MW effect (retail control), not secular convergence (white worker control)

## Primary Specification
```
ln(Earn_siqrt) = β₁(Reform_st × FoodSvc_i × Minority_r)
               + β₂(Reform_st × FoodSvc_i) + β₃(Reform_st × Minority_r)
               + β₄(FoodSvc_i × Minority_r) + γ_s + δ_t + η_i + θ_r + ε_siqrt
```

Where s=state, i=industry, q=quarter, r=race. β₁ is the DDD estimand: the differential earnings gain for minority workers in food services in reforming states.

## Code Plan
- `00_packages.R` — libraries
- `01_fetch_data.R` — Azure QWI pull (rh/ns, NAICS 72 and 44-45)
- `02_clean_data.R` — construct treatment variables, earnings ratios, sample restrictions
- `03_main_analysis.R` — DDD regression, event-study DiD, diagnostics.json
- `04_robustness.R` — placebo tests, wild cluster bootstrap, leave-one-out
- `05_tables.R` — all tables including SDE appendix
