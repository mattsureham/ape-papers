# Research Plan: Who Keeps House?

## Research Question

Did the 1924 Johnson-Reed Act — by cutting off the supply of immigrant domestic servants from Southern and Eastern Europe — cause native-born white women to enter the labor force? Does the effect work through the domestic-servant channel specifically, with married women gaining labor force participation while unmarried women who served as domestics lost employment?

## Identification Strategy

**Bartik Difference-in-Differences.** Treatment intensity = county-level share of restricted-origin (S/E European) immigrants in 1920. The 1924 Act imposed quotas at 2% of 1890 foreign-born stock, cutting S/E European immigration by ~87%. Counties with higher pre-existing concentrations of restricted-origin immigrants experienced larger labor supply shocks in the domestic service sector.

**Key assumptions:**
1. Pre-existing immigrant settlement patterns (1920) are predetermined relative to native women's LFP changes 1920-1930
2. No county-level shocks correlated with both immigrant concentration and women's LFP changes (testable with 1910-1920 placebo)

**Placebo:** 1910-1920 linked panel (pre-Act period). If exposure predicts LFP changes before the Act, the design fails.

## Expected Effects and Mechanisms

1. **Married women:** LFP should INCREASE in high-exposure counties. As immigrant domestic servants became scarce, households that previously relied on cheap domestic help faced rising costs. Married women may have entered the workforce to substitute for lost household production services, or employers in other sectors hired native women to fill vacancies left by the immigrant supply shock.

2. **Unmarried women:** LFP may DECREASE in high-exposure counties. Unmarried immigrant women disproportionately worked as domestic servants. The immigration restriction reduced competition for these jobs BUT also reduced demand for them as fewer immigrant households existed to employ domestics. Net effect is empirically open.

3. **Occupational upgrading:** Among women who were already in the labor force, high-exposure counties may show movement from domestic service into manufacturing, clerical, or professional occupations.

## Primary Specification

Individual-level regression on the linked 1920-1930 panel:

ΔY_i = α + β × Exposure_c(i) + X_i'γ + State_s(i) + ε_i

Where:
- ΔY_i = change in labor force participation (OCCSCORE > 0 in 1930 vs 1920)
- Exposure_c(i) = county share of S/E European immigrants in 1920
- X_i = individual controls: age in 1920, marital status in 1920, literacy, farm status, number of children
- State_s(i) = state fixed effects (absorb state-level trends)

Heterogeneity: separate by marital status (married vs. unmarried), by urban/rural, by baseline occupation.

Clustering: county level (unit of treatment variation).

## Data Source and Fetch Strategy

**Azure MLP:** `linked_1920_1930.parquet` (53.6M individuals, confirmed on Azure)
- Native-born white women aged 18-55: 12,924,394
- Variables: OCCSCORE, OCC1950, MARST, NCHILD, RELATE, OWNERSHP, FARM, LIT, AGE, SEX, RACE, BPL, COUNTY (ICPSR)

**Placebo panel:** `linked_1910_1920.parquet` (pre-Act period)

**Exposure construction:** From the same MLP data — count restricted-origin immigrants by county in 1920 using BPL (birthplace) codes for S/E European countries.

**Processing:** DuckDB queries via Azure connection. R for all econometric analysis.
