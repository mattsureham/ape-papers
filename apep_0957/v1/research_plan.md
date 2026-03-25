# Research Plan: State EITC Supplements and Hispanic Employment in Administrative Support

## Research Question

Do state Earned Income Tax Credit supplements increase Hispanic employment in low-wage sectors where workers are most likely to be EITC-eligible? Specifically, does the staggered adoption of state EITCs (31 states, 2000–2022) disproportionately increase Hispanic employment in NAICS 56 (Administrative Support) relative to non-Hispanic employment and relative to sectors with lower EITC eligibility?

## Identification Strategy

**Triple-differences design:**
- **D1 (Policy):** State adopts/expands state EITC (staggered, 2000–2022)
- **D2 (Sector):** NAICS 56 (high EITC-eligibility, median wage ~$36K, bottom quartile ~$22K) vs. control sectors (NAICS 52 Finance, NAICS 54 Professional Services — higher-wage, low EITC eligibility)
- **D3 (Ethnicity):** Hispanic (A2) vs. Non-Hispanic (A1) workers

**Estimator:** Callaway & Sant'Anna (2021) for staggered adoption, applied to the triple-difference structure. State EITC generosity (% of federal credit, 3–40%) as continuous treatment intensity for robustness.

**Parallel trends assumption:** State EITC adoption is driven by state fiscal capacity and political ideology, not by differential trends in Hispanic employment in administrative support. Testable via pre-trend event studies. Additional support: the triple-difference absorbs state-level shocks (D2) and sector-level shocks (D3).

## Expected Effects and Mechanisms

**Theory (Eissa & Liebman 1996 QJE):** EITC subsidizes labor force participation for low-income workers. State supplements amplify this effect. Hispanic workers in NAICS 56 have higher single-parent household rates and lower average wages, making them more EITC-marginal.

**Expected signs:**
- Primary (EmpS): Positive — state EITC increases stable employment for Hispanic workers in EITC-eligible sectors
- Hiring (HirA): Positive — new hires increase as labor supply expands
- Separations (Sep): Ambiguous — could decrease (retention) or increase (churning)
- Payroll: Positive — more workers × similar wages

**Magnitude context:** Federal EITC increased employment of single mothers by 3.3pp (Meyer & Rosenbaum 2001 QJE). State supplements are 3–40% of federal, so expect smaller but economically meaningful effects.

## Primary Specification

```
Y_{s,i,e,t} = α + β₁(EITC_s,t × NAICS56_i × Hispanic_e) + γ(EITC_s,t × NAICS56_i)
              + δ(EITC_s,t × Hispanic_e) + ζ(NAICS56_i × Hispanic_e)
              + θ_{s,t} + λ_{i,t} + μ_{e,t} + ε_{s,i,e,t}
```

Where s=state, i=industry, e=ethnicity, t=quarter. Fixed effects absorb state×time, industry×time, and ethnicity×time variation. β₁ is the triple-difference ATT.

For staggered adoption: Callaway-Sant'Anna applied to the within-state NAICS56×Hispanic cell relative to control cells.

## Data Source and Fetch Strategy

**Primary data:** QWI Race/Ethnicity Panel (rh), already on Azure:
- Path: `az://apepdata/derived/qwi/rh/ns/*.parquet`
- Variables: EmpS (stable employment), HirA (all hires), Sep (separations), Payroll
- Dimensions: state × quarter × industry (NAICS 2-digit) × ethnicity (A1/A2)
- Coverage: ~2000–2022, ~5.3M observations

**Treatment data:** State EITC adoption dates and generosity rates from NCSL and Tax Policy Center. Will be coded manually from published compilations (31 states, well-documented).

**Fetch strategy:**
1. Read QWI Parquet from Azure via Arrow in R
2. Construct state EITC treatment panel from published sources
3. Merge on state × quarter
4. Filter to NAICS 56 (treated sector) + control sectors (NAICS 52, 54)

## Robustness Plan

1. **Pre-trend event study** — CS event study with 8+ pre-quarters
2. **Alternative control sectors** — NAICS 61 (Education), NAICS 62 (Health Care)
3. **Continuous treatment** — EITC generosity (% of federal) instead of binary adoption
4. **Sun-Abraham estimator** — Alternative heterogeneity-robust estimator
5. **Wild cluster bootstrap** — For inference with 50 state clusters
6. **Leave-one-out** — Drop each adopting state to check influence
7. **Placebo ethnicity** — Test on non-Hispanic workers only (should be weaker/null)
