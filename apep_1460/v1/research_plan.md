# Research Plan: The Retirement Ratchet

## Research Question

Does lowering statutory retirement ages produce symmetric labor supply responses to raising them? Poland's October 2017 reversal — which immediately dropped the retirement age from 67 back to 60 for women and 65 for men after a 2013 reform had been gradually raising it — provides a rare natural experiment with both directions of the shock.

## Identification Strategy

**Primary: Triple-Difference (DDD)**

Three margins of comparison:
1. **Age:** Women 60-64 (treated — newly eligible at 60) vs. Women 55-59 (control — below threshold in both regimes)
2. **Sex:** Women 60-64 (7-year retirement age drop) vs. Men 60-64 (unaffected — retirement age went from 67 to 65, so 60-64 men remain below threshold in both regimes)
3. **Time:** Pre-reform (2013-Q1 to 2017-Q3) vs. Post-reform (2017-Q4 to 2024-Q4)

The DDD nets out: (a) age-specific trends common to both sexes, (b) sex-specific trends common to all ages, (c) time trends common to all groups. Identifies the causal effect of the retirement age reversal on women 60-64 employment.

**Secondary: Synthetic Control Method (SCM)**

Poland is the only EU country that reversed a retirement age increase. Using 8 CEE/EU donor countries (CZ, SK, HU, DE, AT, LT, LV, EE), construct synthetic Poland for women aged 60-64 employment rate. Pre-treatment: 2010-Q1 to 2017-Q3. Post-treatment: 2017-Q4 to 2024-Q4.

## Expected Effects

- **Immediate employment decline** for women 60-64 after Q4 2017 (−3 to −5pp)
- **No effect** on women 55-59 (below both retirement ages)
- **No effect** on men 60-64 (below both retirement ages in the 60-64 range)
- **Asymmetry:** The employment decline from reversing may exceed the employment gain from the 2013 raise, suggesting a "ratchet" — it's easier to pull workers out than push them in

## Primary Specification

```
emp_rate_{a,s,t} = α + β₁(Female_s × Age60_64_a × Post_t) 
                     + β₂(Female_s × Age60_64_a) + β₃(Female_s × Post_t) 
                     + β₄(Age60_64_a × Post_t) + γ_a + δ_s + λ_t + ε_{a,s,t}
```

Where β₁ is the DDD estimate: the differential change in employment for women 60-64 relative to the triple-difference baseline.

## Data Source

**Eurostat Labour Force Survey**: Dataset `lfsq_ergan` (quarterly employment rates by sex and 5-year age group). Free API, no authentication.

- **Countries:** Poland (treated) + 8 donors (CZ, SK, HU, DE, AT, LT, LV, EE)
- **Age groups:** 55-59, 60-64, 65-69
- **Sex:** Male, Female
- **Time:** 2010-Q1 to 2024-Q4
- **Unit:** Employment rate (%)

## Robustness and Placebo Tests

1. **In-time placebo:** Test at 2013-Q1 (when retirement age started rising) — should see opposite sign
2. **In-space placebo:** DDD using donor countries as pseudo-treated
3. **Pre-trends:** Event study showing quarter-by-quarter DDD coefficients
4. **Age bandwidth:** Women 55-59 vs 60-64 (baseline), then 50-54 vs 60-64
5. **SCM permutation inference:** In-space placebos for each donor country
6. **Men 65-69 as partial treatment:** Retirement age dropped from 67 to 65, so men 65-66 are newly eligible — weaker treatment, expected smaller effect
