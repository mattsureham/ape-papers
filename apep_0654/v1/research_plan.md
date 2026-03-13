# Research Plan: Unlock and Hire — Universal License Recognition and Establishment-Level Labor Market Dynamics

## Research Question
Do Universal License Recognition (ULR) laws — which allow workers licensed in one state to practice in the adopting state without duplicative exams — increase job creation in licensed occupations, or do they merely accelerate worker turnover without net employment gains?

## Identification Strategy
**Triple-difference (DDD):** State × licensed-vs-unlicensed industry × post-ULR adoption.

26 states adopted ULR laws between 2019 and 2023 in staggered fashion. ~24 states remain non-adopters (including CA, NY, TX, IL). Treatment timing varies by state, creating clean variation for Callaway-Sant'Anna staggered DiD.

**DDD Design:**
- Compare licensed sectors (NAICS 62 Health, 54 Professional Services, 23 Construction, 61 Education) to placebo sectors (NAICS 44-45 Retail, 72 Accommodation/Food)
- Within treated vs. never-treated states
- Before vs. after ULR adoption

This identifies the ULR-specific effect net of any state-level trends and any national sector trends.

## Expected Effects and Mechanisms
1. **Job creation channel:** If licensing barriers constrained firm growth by limiting qualified labor supply, ULR should increase job creation (FrmJbGn) in licensed sectors.
2. **Turnover channel:** If ULR merely increases labor pool fluidity, we should see higher hiring AND higher separations with flat net employment — pure churn.
3. **Wage channel:** Standard labor supply expansion predicts wage compression in licensed occupations (more competition for positions).

## Primary Specification
```
Y_{siqt} = α_s + γ_{i×t} + β₁(Treated_{st} × Licensed_i) + X'δ + ε_{siqt}
```
- Y: new hires, separations, job creation, job destruction, turnover, earnings
- α_s: state FE; γ_{i×t}: industry-by-quarter FE
- Standard errors clustered at state level
- Weighted by employment

## Data Source
Census QWI from Azure Blob Storage (derived/qwi/se/ns/*.parquet — sex-by-education panel):
- County × quarter × industry × education level
- 2014Q1-2025Q1 panel
- Outcomes: EarnS, EarnHirNS, HirN, Sep, FrmJbGn, FrmJbLs, TurnOvrS, Emp

## Treatment Timing (26 states)
Arizona (2019Q2), Montana (2019Q3), Pennsylvania (2019Q3), Utah (2020Q2), Mississippi (2020Q3), Idaho (2020Q3), Iowa (2020Q3), Missouri (2020Q3), Wyoming (2020Q3), Indiana (2021Q3), Kansas (2021Q3), New Hampshire (2021Q3), West Virginia (2021Q2), Ohio (2022Q2), Alabama (2022Q3), Louisiana (2022Q3), Georgia (2022Q3), Kentucky (2022Q3), South Carolina (2022Q2), Tennessee (2022Q1), Arkansas (2023Q3), Nebraska (2023Q4), North Carolina (2023Q4), Oklahoma (2023Q4), Virginia (2023Q3), North Dakota (2023Q3)
