# Research Plan: apep_0886

## Research Question

Did the American Rescue Plan's $24 billion childcare stabilization grant program increase female employment in childcare-adjacent industries? Specifically, does state-level variation in the speed and scale of grant disbursements causally affect maternal labor supply, and did the September 2023 grant expiration reverse these gains?

## Identification Strategy

**Design: Difference-in-Difference-in-Differences (DDD)**

1. **First difference (time):** Pre-disbursement vs. post-disbursement quarters
2. **Second difference (treatment intensity):** Early-disbursing states (Q4 2021) vs. late-disbursing states (Q2-Q3 2022)
3. **Third difference (gender):** Female workers vs. male workers in the same industry-state-quarter cell

The DDD isolates the female-specific employment response from confounding labor demand shifts that affect both genders equally. Male workers in the same childcare industries (NAICS 624, 623, 611) serve as within-cell controls since childcare supply shocks primarily relax constraints for mothers, not fathers.

**Treatment variable:** Binary indicator for state having disbursed ARP childcare stabilization grants, based on ACF quarterly progress reports. Staggered across states from Q4 2021 to Q3 2022.

**Exogeneity argument:** Grant timing was driven by state administrative capacity (CCDF reporting infrastructure) and political decisions about outreach mechanisms, not local labor market conditions. CCDF formula allocations were predetermined by pre-existing formula weights.

## Expected Effects and Mechanisms

- **Primary:** Positive effect on female employment in childcare-adjacent industries. Grants subsidized provider wages and operating costs → expanded effective childcare supply → reduced childcare constraints for working mothers → higher female employment.
- **Magnitude:** CEA descriptive estimates suggest 2-3pp increase in maternal LFPR. With the DDD isolating the female-specific channel, we expect smaller but cleaner estimates.
- **Reversal:** Grant expiration (September 2023) should produce negative employment effects in states that did not bridge funding with state appropriations.
- **Heterogeneity:** Stronger effects for less-educated women (E1/E2 ≤HS) who face more binding childcare cost constraints.

## Primary Specification

```
Y_{s,i,g,t} = α + β₁(Post_st × Female_g) + β₂(Post_st) + β₃(Female_g)
              + γ_{s,i,g} + δ_{i,t} + λ_{s,t} + ε_{s,i,g,t}
```

Where:
- Y = log employment (EmpS) or quarterly earnings (EarnS)
- s = state, i = industry (3-digit NAICS), g = gender, t = quarter
- Post_st = 1 after state s begins disbursing stabilization grants
- Female_g = 1 for female workers
- γ_{s,i,g} = state × industry × gender FE
- δ_{i,t} = industry × quarter FE
- λ_{s,t} = state × quarter FE (absorbs state-level macro trends)
- Clustering: state level (50 clusters)

β₁ is the DDD coefficient of interest: the differential change in female employment in treated states, relative to male employment, after grant disbursement.

**Estimator:** Callaway-Sant'Anna (2021) for staggered treatment, with gender as an additional interaction. If CS implementation is computationally prohibitive at this scale, use TWFE with Sun-Abraham (2021) interaction-weighted estimator as robustness.

## Robustness

1. **Event study:** Dynamic effects by quarters since disbursement (pre-trend test)
2. **Placebo industry:** Manufacturing (NAICS 31-33) — low childcare constraints, should show null DDD
3. **Placebo gender:** Male-only DiD should show null
4. **Education heterogeneity:** Effects by education level (E1/E2 vs E3/E4/E5)
5. **Grant expiration:** September 2023 expiration as second shock — states with vs without bridge funding
6. **Leave-one-out:** Drop each early-disbursing state to check robustness

## Data Source and Fetch Strategy

**Primary data:** QWI SE (Sex × Education) panel
- Azure path: `az://derived/qwi/se/n3/{state}.parquet`
- Variables: EmpS, EarnS, HirN, SepS by state × county × quarter × sex × education × industry (3-digit NAICS)
- Period: 2019Q1-2024Q4 (8 pre-quarters + treatment + post)
- Coverage: All 50 states + DC

**Treatment timing:** Construct from published ACF/Child Care Aware tracking data
- Early disbursers (Q4 2021): TX, FL, GA, OH, NC, AZ, IN, OK, MO, KY, LA, AL, SC, MS, AR, KS, NE, WV, ID, ND, SD, WY, MT, AK, HI, UT
- Late disbursers (Q2-Q3 2022): WA, MA, CT, NJ, CA, NY, IL, MI, MN, CO, OR, MD, VA, PA, WI, NM, NH, VT, ME, RI, DE, DC, IA, NV

**Fetch strategy:**
1. Read QWI SE Parquet files from Azure for all states
2. Filter to relevant industries (624, 623, 611) + placebo (31-33)
3. Aggregate to state × industry × sex × quarter level
4. Merge treatment timing
5. Validate sample sizes and pre-trends
