# Research Plan: The Texture Penalty — CROWN Act Adoptions and Black Worker Earnings

## Research Question
Do state-level CROWN Acts — which prohibit workplace discrimination based on hair texture and protective hairstyles — improve labor market outcomes for Black workers? Specifically, does the CROWN Act reduce the "texture penalty" (the earnings gap attributable to hair-texture-based appearance discrimination)?

## Identification Strategy
**Triple-difference (DDD)** exploiting three sources of variation:
1. **Time:** Before vs. after CROWN Act adoption
2. **Geography:** States that adopted CROWN Acts vs. states that did not (staggered, 2019-2023)
3. **Demographics:** Black workers vs. white workers (within each state-year)

The DDD absorbs: state-year shocks common to all races, race-year trends common to all states, and state-race fixed effects. The identifying assumption is that absent the CROWN Act, Black-white earnings gaps would have followed parallel trends across CROWN and non-CROWN states.

**Estimator:** Callaway and Sant'Anna (2021) extended to DDD, or stacked DiD with cohort-specific controls.

## Expected Effects and Mechanisms
- **Primary:** Positive effect on Black median earnings (especially for Black women)
- **Mechanism 1: Expanded job access.** Workers no longer penalized for natural hair in hiring/promotion → access to higher-paying roles
- **Mechanism 2: Reduced compensating behavior.** Workers no longer spend time/money on hair straightening/alterations for professional settings → lower compliance costs
- **Null prediction:** If hair discrimination was already declining, or if CROWN Acts lack enforcement teeth, effects may be negligible

## Primary Specification
```
Y_{sdt} = α + β(CROWN_{st} × Black_d) + γ(CROWN_{st}) + δ(Black_d) + μ_s + λ_t + ρ_d + θ_{st} + φ_{dt} + ψ_{sd} + ε_{sdt}
```
Where s=state, t=year, d=demographic group (Black/white × male/female). β is the DDD estimand: the differential change in outcomes for Black workers in CROWN states, net of common state-year and race-year trends.

## Treatment Assignment
| Year | States Adopting | Cumulative |
|------|-----------------|------------|
| 2019 | CA, NY, NJ | 3 |
| 2020 | MD, CO, WA, VA | 7 |
| 2021 | CT, DE, NM, NV, NE, OR, IL | 14 |
| 2022 | ME, TN, MA, LA | 18 |
| 2023 | MN, TX, MI, AR | 22 |
| 2024 | NH, VT, AK | 25 (beyond ACS data window) |

## Data Source and Fetch Strategy
**Census ACS 1-year estimates via API:**
- `B20017B` — Black median earnings by sex (state-level)
- `B20017A` / `B20017H` — White / non-Hispanic white median earnings by sex
- `B23002B` — Black employment by sex and age
- `B23002A` / `B23002H` — White employment by sex and age

**Years:** 2017, 2018, 2019, 2021, 2022, 2023 (6 years; 2020 excluded due to ACS COVID non-response)

**Unit of observation:** State × year × race × sex (4 demographic groups × ~51 states × 6 years ≈ 1,224 observations)

## Robustness Checks
1. Event-study pre-trends (limited to 2 pre-periods given 2019 first adoption)
2. Leave-one-out: drop each early adopter (CA, NY, NJ)
3. Permutation/randomization inference for p-values given clustered structure
4. Alternative comparison: Black women vs. white women (isolating race channel)
5. Heterogeneity by Black population share (effects concentrated where more Black workers)

## Key Risks
- Only 2 clean pre-treatment years (2017-2018)
- State-level aggregates may be too coarse to detect effects
- COVID disruption in 2020-2021 may contaminate early treatment effects
- Enforcement variation across states not observed
