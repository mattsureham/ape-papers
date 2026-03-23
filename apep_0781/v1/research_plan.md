# Research Plan: The Layoff Tax — UI Wage Base Increases and Employer Separation Behavior

## Research Question
Do increases in state UI taxable wage bases reduce employer-initiated separations, and are effects concentrated in low-wage industries where the marginal tax cost increase is binding?

## Identification Strategy
**Triple-Difference (State × Industry Wage Level × Post-Increase)**

Treatment: State raises UI taxable wage base above previous level. ~20 states with increases during 2000–2020, staggered. 8 states stuck at $7,000 federal minimum (CA, AZ, FL, GA, MI, MS, NE, TN) serve as never-treated controls.

Key mechanism: experience-rated UI taxes make layoffs costly. Raising the wage base increases the marginal per-worker tax liability. The bite is largest for workers earning near or below the new threshold — low-wage industries (retail, food service) should respond more than high-wage industries (finance, professional services).

**Triple-diff**: Separation rate response in low-wage NAICS vs high-wage NAICS within the same state, before and after wage base increase. This absorbs state-level confounders (recessions, political composition) and industry-level trends.

## Expected Effects and Mechanisms
- Employers face higher marginal cost of layoffs → reduce separations
- Effect concentrated in low-wage industries (retail 44-45, accommodation/food 72) where workers earn below the new wage base
- High-wage industries (finance 52, professional services 54) serve as within-state placebo
- Net effect on employment ambiguous: fewer separations but potentially fewer hires too

## Exposure Alignment
The treatment (SUTA wage base increase) directly affects employers' UI tax liability. The exposure is well-aligned with the outcome (separation rates) because experience-rated UI taxes make each layoff costly, and the cost increase from a wage base increase is mechanically larger for workers earning below the new threshold. Low-wage industries have more below-threshold workers.

## Primary Specification
```
log(Sep_{s,i,t}) = α_s + γ_t + δ_i + β₁(Post_{s,t} × LowWage_i) + β₂(Post_{s,t}) + β₃(LowWage_i × Year) + X_{s,t}Γ + ε_{s,i,t}
```
Where Sep is quarterly separations from QWI, Post is indicator for post-wage-base-increase, LowWage is indicator for below-median-wage industry. State, quarter, and industry fixed effects.

## Data Sources
1. **Census QWI API**: State × quarter × NAICS industry. Variables: Sep (separations), Emp (employment), EarnS (earnings). Industries: retail (44-45), accommodation/food (72), manufacturing (31-33), finance (52), professional services (54). Period: 2000Q1–2023Q4.
2. **DOL ET Handbook 394**: Annual state-level UI taxable wage base. Download from oui.doleta.gov/unemploy/statelaws.asp. Code treatment dates from annual changes.
3. **BLS QCEW** (alternative): Quarterly employment/wages by state-industry for validation.

## Sample Size Expectations
- 51 states × ~96 quarters × 5 industries ≈ 24,480 state-industry-quarter observations
- ~20 treated states with wage base increases
- 8 never-treated controls at $7,000 federal minimum
- Pre-periods: 5+ years before each increase
