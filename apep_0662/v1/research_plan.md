# Research Plan: apep_0662

## Research Question

Do automatic criminal record sealing ("clean slate") laws increase aggregate employment but widen racial employment gaps through intensified statistical discrimination?

## Motivation

Doleac and Hansen (2020, JLE) showed that ban-the-box (BTB) laws — which delay criminal history inquiries — reduced young Black male employment by 3.4pp through statistical discrimination. Clean slate laws go further: they *permanently destroy* employer access to criminal records. The statistical discrimination incentive is theoretically stronger. Yet Agan et al. (2024, NBER WP 32394) found null individual-level effects in Pennsylvania for *non-conviction* sealing. We test the aggregate equilibrium prediction: does clean slate increase overall employment while widening racial gaps?

## Identification Strategy

**Method:** Callaway-Sant'Anna (2021) staggered DiD with group-time ATTs.

**Treatment:** State-level enactment of clean slate automatic record sealing laws, staggered 2018-2023:
- 2018: PA
- 2019: UT, NJ, CA
- 2020: MI
- 2021: CT, DE, VA
- 2022: OK, CO
- 2023: MN, NY

**Control group:** ~38 never-treated states (as of Dec 2024)

**Unit of observation:** State-month (BLS LAUS) or state-quarter (Census QWI)

## Data Sources

1. **BLS LAUS** (primary): Monthly state-level unemployment rate, employment, labor force, E-pop ratio. 2014-2025. All 50 states + DC. API: no key needed.

2. **Census QWI** (secondary): Quarterly state-level employment, average earnings, hires, separations. 2014-2024. Stratified by sex, age, industry. Census API key from .env.

3. **ACS 1-Year** (racial gap test): State-level employment by race (Tables B23002B for Black, B23002H for White non-Hispanic). 2012-2023. Census API.

## Expected Effects and Mechanisms

**Aggregate effect:** Ambiguous. Barrier removal increases record-holder labor supply → higher employment. But if employers substitute away from groups likely to have records, displacement could offset.

**Racial gap:** The Doleac-Hansen prediction: employers who can no longer check records discriminate based on observable characteristics correlated with criminal history (race, age, neighborhood). Black men 25-54 without college degrees are the group most likely to be statistically discriminated against.

**Earnings composition:** If clean slate brings lower-wage record-holders into employment, average earnings may fall even as total employment rises.

## Primary Specification

```
Y_{s,t} = α_s + γ_t + Σ_g β_g × 1[G_s = g] × 1[t ≥ g] + ε_{s,t}
```

Using `did::att_gt()` with:
- `yname`: unemployment rate or E-pop ratio
- `tname`: year-month (numeric)
- `idname`: state FIPS
- `gname`: enactment year (first treated period)
- `control_group`: "nevertreated"

## Key Tests

1. **Aggregate employment effect** (BLS LAUS E-pop ratio)
2. **Racial gap test** (ACS: Black vs. White employment gap)
3. **Earnings composition** (QWI average earnings)
4. **Hiring dynamics** (QWI hires and separations)

## Exposure Alignment

Treatment is at the state level — all workers in a state are exposed once the clean slate law is enacted. The ACS race-specific E-pop ratios capture employment rates for the entire working-age population (16-64) by race, which includes both record-holders (directly affected by barrier removal) and non-record-holders (potentially affected by statistical discrimination). The design estimates the net effect of these two channels at the state level, which is the appropriate estimand for the aggregate equilibrium question.

## Robustness

- Sun-Abraham interaction-weighted estimator
- Exclude COVID period (Feb 2020 - Jun 2021)
- Implementation date (vs. enactment date) as treatment timing
- Wild cluster bootstrap (13 treated clusters is borderline)
- HonestDiD/Rambachan-Roth bounds for pre-trend sensitivity
