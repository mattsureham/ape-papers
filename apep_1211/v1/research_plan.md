# Research Plan: Medicaid Reimbursement Rates and the Black-White Earnings Gap in Nursing Homes

## Research Question

Do Medicaid nursing home reimbursement rate increases compress the Black-White earnings gap among nursing home workers? Medicaid covers ~60% of nursing home residents and acts as the dominant price-setter for an industry where Black workers are disproportionately represented. This dual role — insurer of predominantly Black residents, implicit wage-setter for a predominantly Black workforce — makes Medicaid reimbursement a uniquely racialized wage policy.

## Identification Strategy

**Triple-difference (DDD) design:**
1. **First difference:** Before vs after state Medicaid nursing home rate increases
2. **Second difference:** Nursing homes (NAICS 623, Medicaid-dependent) vs ambulatory care (NAICS 621, less Medicaid-dependent)
3. **Third difference:** Black vs White workers within each state-quarter-industry cell

**Key assumption:** Rate changes affect nursing homes directly (not ambulatory care), and within nursing homes should compress the racial earnings gap if pass-through favors lower-wage (predominantly Black) workers.

**Treatment variable:** State-year Medicaid nursing home per-diem rate from CMS Skilled Nursing Facility Cost Reports (HCRIS public use files). Facility-level Medicaid per-diem rates aggregated to state-year medians. Year-over-year rate changes identify treatment timing.

**Estimator:** Callaway-Sant'Anna for staggered DiD; DDD implemented as interaction terms within the CS framework or as a stacked event-study specification.

## Expected Effects and Mechanisms

- **If pass-through favors low-wage workers:** Rate increases compress the Black-White gap (positive effect on relative Black earnings). Mechanism: minimum wage floor effect at the bottom of the nursing home wage distribution where Black workers are overrepresented.
- **If pass-through is captured upstream:** No effect on racial gap — rate increases accrue to administrators/shareholders, not direct-care workers. This null would be equally publishable.
- **If pass-through is race-neutral:** Gap unchanged because Black and White workers benefit proportionally. Less likely given occupational segregation within nursing homes.

## Primary Specification

```
Y_{s,t,r,j} = α + β₁(ΔRate_s,t × Black_r × NH_j) + β₂(ΔRate_s,t × NH_j) + β₃(ΔRate_s,t × Black_r) + γ_s,t + δ_r,j + ε_{s,t,r,j}
```

Where:
- Y = average quarterly earnings (EarnS from QWI)
- s = state, t = quarter, r = race (Black/White), j = industry (623/621)
- ΔRate = change in state Medicaid nursing home per-diem rate
- β₁ = DDD coefficient of interest

## Data Sources

1. **Outcome:** QWI race×ethnicity × NAICS 3-digit from Azure (`az://derived/qwi/rh/n3/*.parquet`). State-quarter-race cells for NAICS 623 (nursing homes) and 621 (ambulatory care). ~11,200 state-quarter-race obs for NAICS 623 alone.

2. **Treatment:** CMS Skilled Nursing Facility Cost Reports (HCRIS). Facility-level Medicaid per-diem rates aggregated to state-year. Publicly available from data.cms.gov.

3. **Placebo industry:** NAICS 721 (accommodation/hotels) — similar demographics, not Medicaid-dependent.

## Fetch Strategy

1. Read QWI parquet from Azure via DuckDB (confirmed accessible)
2. Fetch CMS cost report data from data.cms.gov or construct from CMS expenditure reports
3. If CMS API fails: use FRED/BEA state Medicaid spending + CMS bed counts as proxy
4. Merge on state × year
