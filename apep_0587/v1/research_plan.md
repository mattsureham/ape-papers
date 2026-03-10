# Initial Research Plan — apep_0587

## Research Question

How do taxpayers respond to the sharp notch created by the UK High Income Child Benefit Charge (HICBC) at £50,000 adjusted net income? Specifically: what share of the behavioral response reflects real labor supply adjustment versus income manipulation through pension contributions? And does bunching at £50,000 dissolve when the threshold shifts to £60,000 in April 2024?

## Identification Strategy

**Bunching estimation at the notch** (Kleven & Waseem 2013; Kleven 2016). The HICBC creates a notch at £50,000 ANI where a 1% charge per £100 above the threshold effectively creates a 100% marginal effective tax rate on Child Benefit. Standard approach:

1. Estimate the counterfactual income distribution by fitting a polynomial (degree 7-10) to the observed density, excluding a window around the notch (£45,000-£55,000)
2. The excess mass below £50,000 relative to the counterfactual identifies the bunching response
3. The "missing mass" above £50,000 identifies the dominated region

**Channel test (mechanism):** Self-employed workers face low frictions in adjusting reported income (via pension contributions, trading losses, Gift Aid). PAYE employees face substantial frictions — their gross pay is set by employers, and the primary avoidance channel is salary sacrifice into pensions. Prediction: bunching should be concentrated among self-employed and those with pension headroom. PAYE-only workers with no pension flexibility should show minimal bunching. This decomposition separates avoidance from real labor supply distortion.

**Reform falsification:** The April 2024 Budget raised the threshold from £50,000 to £60,000. Post-reform:
- Bunching at £50,000 should dissolve (falsification of the original notch)
- New bunching may emerge at £60,000-£80,000 (validation that the same behavioral channel operates at the new threshold)

## Expected Effects and Mechanisms

1. **Excess mass below £50,000:** Expect significant bunching, primarily driven by income manipulation (pension contributions) rather than real labor supply reduction
2. **Self-employed vs. PAYE differential:** Self-employed should show 3-5x more bunching due to lower adjustment frictions
3. **Post-2024 reform:** Bunching at £50,000 should vanish within 1-2 tax years, confirming the response is notch-driven rather than reflecting round-number preferences
4. **Welfare implications:** If most bunching is avoidance (pension contributions), the efficiency cost is a transfer to retirement savings, not a deadweight loss from reduced labor supply

## Primary Specification

- Bin width: £500 or £1,000 income bins
- Counterfactual polynomial: degree 7 (robustness: 5, 9, 11)
- Exclusion window: [£45,000, £55,000] (robustness: ±£3,000, ±£7,000)
- Excess mass statistic: b = (B - B_cf) / B_cf, where B is observed count and B_cf is counterfactual count in the bunching region
- Standard errors: bootstrap (500 replications), resampling residuals

## Planned Robustness Checks

1. **Polynomial degree sensitivity:** Degrees 5, 7, 9, 11
2. **Exclusion window sensitivity:** ±£3k, ±£5k, ±£7k, ±£10k
3. **Bin width sensitivity:** £250, £500, £1,000, £2,000
4. **Round-number placebo:** Test for bunching at £40,000, £45,000, £55,000, £60,000 (pre-reform) — these are round numbers without notches
5. **Time-series stability:** Year-by-year bunching estimates 2013-2024
6. **Pre-2013 placebo:** No bunching should exist at £50,000 before HICBC introduction (2011-2012 vs. 2013-2024)
7. **Post-2024 falsification:** Bunching at £50,000 disappears in 2024/25 data
8. **Gender decomposition:** Women (historically primary Child Benefit claimants) vs. men
9. **Donut-hole estimates:** Exclude observations within ±£1,000 of the threshold

## Method Notes: Bunching Estimation

### Identification Assumption
Absent the notch, the income distribution would be smooth through the threshold. The counterfactual density is recoverable from the observed distribution away from the notch.

### Validity Requirements
1. No other policy creates a discontinuity at exactly £50,000 ANI
2. The income distribution is smooth in the counterfactual (no round-number heaping that would bias estimates)
3. Taxpayers are aware of the threshold and can respond (awareness test via HMRC opt-out data)

### Common Pitfalls
- Sensitivity to polynomial degree choice → report multiple degrees
- Round-number heaping at £50,000 independent of HICBC → pre-2013 placebo and other round-number placebos
- Diffuse bunching (responses spread over multiple bins) → use wider bunching window
- Optimization frictions (some taxpayers can't respond precisely) → leads to underestimation of structural elasticity

### R Packages and Code Patterns
- `bunching` R package (Mavrokonstantis & Mavridis) — direct implementation of Kleven-Waseem
- Manual implementation using `stats::poly()` for counterfactual polynomial
- `ggplot2` for density plots
- Bootstrap SE via custom function

### Key Papers to Cite
- Kleven, H.J. & Waseem, M. (2013). "Using Notches to Uncover Optimization Frictions and Structural Elasticities." QJE 128(2).
- Kleven, H.J. (2016). "Bunching." Annual Review of Economics 8.
- Saez, E. (2010). "Do Taxpayers Bunch at Kink Points?" AEJ: Economic Policy 2(3).
- Chetty, R., Friedman, J.N., Olsen, T. & Pistaferri, L. (2011). "Adjustment Costs, Firm Responses, and Micro vs. Macro Labor Supply Elasticities." QJE 126(2).
- Adam, S., Kelsey, D. & Waters, T. (2020). "Frictions and taxpayer responses." IFS Working Paper.

## Data Sources

1. **NOMIS/ASHE (NM_99_1):** Annual Survey of Hours and Earnings — earnings percentiles for full-time workers. Available via API. Key fields: gross annual pay, percentile distribution, full-time/part-time split.
2. **HMRC HICBC Statistics:** Annual administrative data on HICBC liability — number of taxpayers, total charge, by income band. Available from GOV.UK.
3. **HMRC Self Assessment Statistics:** Income distribution by employment type (self-employed vs. PAYE). Available from GOV.UK.
4. **ONS ASHE Tables:** Published ASHE tables with percentile breakdowns by occupation, sector, region. Available from ONS website.

## Power Assessment

- ~440,000 HICBC-liable taxpayers annually
- ASHE covers ~300,000-500,000 workers in the £40k-£60k range per year
- 11 years of pre-reform data (2013-2023) = 3.3-5.5M worker-year observations near the notch
- Standard bunching estimates are well-powered with samples >50,000 in the relevant income range
- The channel test (self-employed vs. PAYE) requires ASHE microdata or HMRC breakdowns by employment type
