# Research Plan: The Hidden Wage Floor — Salary History Bans and the Industry Geography of Pay Compression

## Research Question
Do state salary history bans compress gender pay gaps uniformly, or do they redistribute wage-setting power differently across industries — compressing pay in low-gap sectors while potentially widening gaps in high-gap sectors through statistical discrimination?

## Identification Strategy
**Callaway–Sant'Anna (2021) staggered DiD** with triple-difference.

- **Treatment:** 16 states with private-employer salary history bans, staggered 2017–2023 (7 cohorts)
- **Control:** 34 never-adopting states
- **Triple difference:** Women vs men × treated vs control × high-gender-gap vs low-gender-gap industry

The triple-difference design nets out: (i) national industry trends, (ii) state-specific shocks, (iii) gender-invariant policy effects, and (iv) industry-invariant gender trends.

### Treatment Timing
| Cohort | States | Effective Date |
|--------|--------|----------------|
| 2017 Q4 | DE, OR | Dec 2017, Oct 2017 |
| 2018 Q1 | CA, MA, VT | Jan, Jul, Jul 2018 |
| 2019 Q1 | CT, HI, IL, WA, ME, AL | Jan–Sep 2019 |
| 2020 Q1 | NJ, MD | Jan, Oct 2020 |
| 2021 Q1 | CO, NV | Jan, Oct 2021 |
| 2023 Q1 | RI | Jan 2023 |

## Expected Effects and Mechanisms

### Main Hypothesis
Salary history bans remove employers' primary anchoring tool for wage-setting. Two competing mechanisms:

1. **Barrier removal (optimistic):** Without anchoring to low prior salaries, women and minorities receive offers based on job value → gender gap compresses.
2. **Statistical discrimination (pessimistic, Doleac–Hansen):** When individual-level information is removed, employers rely more on group-level priors (gender × industry wage norms) → gap widens in sectors where employers hold strong priors about gender productivity.

### Predicted Heterogeneity
- **Low-gap industries** (Wholesale 42, Manufacturing 31–33, pre-ban gap ~14–17%): Barrier removal dominates → gap compresses
- **High-gap industries** (Finance 52, Professional 54, Arts 71, pre-ban gap ~30–43%): Statistical discrimination may dominate → gap may widen or show smaller compression
- **Race channel:** Black/Hispanic new hires may see larger earnings gains (correcting racial anchoring) OR hiring rate declines (Doleac–Hansen statistical discrimination)

## Primary Specification
```
Y_{c,i,s,q} = α_c + γ_{i,q} + β₁ × (Female × Post × HighGap) + β₂ × (Female × Post)
              + β₃ × (Post × HighGap) + Controls + ε

Where:
  c = county, i = industry, s = sex, q = quarter
  Female = 1 for women
  Post = post-ban indicator (varies by state cohort)
  HighGap = 1 for industries with pre-ban gender gap > 25%
  Y = new-hire earnings (EarnHirNS), hiring rate (HirN/Emp), separation rate (Sep/Emp)
```

CS-DiD with group-time ATTs for the event study.

## Data Source and Fetch Strategy

### Primary: Census QWI on Azure
- **Path:** `az://derived/qwi/sa/ns/*.parquet` (sex × age × NAICS)
- **Path:** `az://derived/qwi/se/ns/*.parquet` (sex × education × NAICS)
- **Path:** `az://derived/qwi/rh/ns/*.parquet` (race × ethnicity × NAICS)
- **Panel:** 3,144 counties, 1990–2025 quarterly, 20+ NAICS sectors
- **Key variables:** EarnHirNS (new-hire earnings), HirN (new hires), Sep (separations), Emp (employment), EarnS (average earnings), TurnOvrS (turnover)

### Access Method
DuckDB/Arrow queries against Azure Parquet files. Already confirmed accessible.

## Robustness Checks
1. Event study with pre-trend test (4+ quarters pre)
2. Bacon decomposition
3. Randomization inference (500 permutations)
4. Border county pairs
5. Exclude 2020 COVID quarters (sensitivity)
6. Sun & Abraham (2021) interaction-weighted estimator
7. Placebo: men 45–54 (not targeted by ban)
8. Dose-response: early adopters vs late adopters

## SDE Appendix Plan
- Primary outcome: gender earnings gap (new-hire earnings, women vs men)
- Secondary: hiring rate gender gap, separation rate gender gap
- Race-specific: Black–White new-hire earnings gap
