# Initial Research Plan: NLW Bite and Care Home Closures in England

## Research Question

Does the National Living Wage cause care home closures, capacity reduction, and quality decline in areas where it bites hardest? What are the mechanisms — cost squeeze on publicly-funded homes vs. self-pay homes, workforce exit, quality deterioration?

## Identification Strategy

**Design:** Continuous-treatment Difference-in-Differences (DiD)

**Treatment:** NLW "bite" in each Local Authority, constructed from pre-2016 ASHE wage data:
- Primary: Gap measure = (NLW_2016 - median_care_wage_2015) / median_care_wage_2015
- Robustness: Fraction affected = share of care workers below £7.20 in 2015
- Robustness: Kaitz index = NLW / LA median wage (all occupations)

**Variation:** Cross-sectional variation in NLW bite across ~150 upper-tier LAs in England. High-bite LAs (Northern England, Midlands, Wales — low-wage care sectors) vs. low-bite LAs (London, South East — wages already above NLW).

**Time period:** 2012-2019 (primary, excludes COVID). 2012-2023 (robustness, with COVID controls).

**Estimating equation:**
Y_it = alpha_i + gamma_t + beta × (Bite_i × Post_t) + delta × X_it + epsilon_it

Where:
- Y_it = {care home count, total beds, closure rate, mean CQC rating} in LA i, year t
- alpha_i = LA fixed effects
- gamma_t = year fixed effects
- Bite_i = pre-NLW treatment intensity (time-invariant)
- Post_t = indicator for post-April 2016
- X_it = time-varying controls (LA population, over-65 population, adult social care expenditure)

**Event study:** Replace Post_t with year dummies interacted with Bite_i, omitting 2015 as reference. Plot coefficients for 2012-2019.

## Expected Effects and Mechanisms

**Expected signs:**
- Care home closures: INCREASE in high-bite LAs (cost squeeze)
- Total bed capacity: DECREASE in high-bite LAs
- CQC quality ratings: AMBIGUOUS (closures of worst homes may raise average; surviving homes may cut quality)
- Care worker wages: INCREASE (first stage — NLW is binding)

**Mechanisms:**
1. **Cost channel:** NLW raises wage bill → profit squeeze → closures (especially publicly-funded homes where LA fee rates don't keep pace)
2. **Quality channel:** Cost pressure → understaffing, reduced training → quality decline
3. **Selection channel:** Worst-performing homes close first → surviving homes may be higher quality
4. **Composition channel:** Shift from residential to domiciliary care (cheaper, lower-regulated)

## Primary Specification

```
closure_rate_it = alpha_i + gamma_t + beta × Bite_i × Post_t + delta × Controls_it + epsilon_it
```

Clustered standard errors at LA level (~150 clusters).

## Planned Robustness Checks

1. **Pre-trends:** Event-study plot with joint F-test of pre-treatment coefficients
2. **HonestDiD:** Rambachan & Roth sensitivity under alternative trend assumptions
3. **Alternative bite measures:** Gap, fraction affected, Kaitz index
4. **COVID robustness:** Extend to 2023 with COVID controls
5. **Placebo outcomes:** NHS hospital closures (SIC 86), high-wage sector employment
6. **Heterogeneity:** Publicly-funded vs. self-pay homes; residential vs. nursing care
7. **Alternative clustering:** Wild cluster bootstrap, randomization inference
8. **Social care funding control:** Include DHSC Section 251 expenditure as time-varying control
9. **Bartik instrument robustness:** Use national NLW schedule interacted with pre-period wage structure
10. **Donut specification:** Exclude 2015-2016 transition year

## Exposure Alignment (DiD Requirements)

- **Who is treated:** Care homes in high-bite LAs (where care worker wages were far below NLW)
- **Primary estimand population:** ~150 upper-tier LAs in England
- **Placebo/control:** NHS hospitals (different funding mechanism); high-wage sectors
- **Design:** Continuous-treatment DiD (not staggered, but with multiple "re-treatments" from annual NLW increases)

## Power Assessment

- **Pre-treatment periods:** 4 (2012-2015)
- **Treated clusters:** ~150 LAs (all treated with varying intensity; top quartile = ~38 high-bite LAs)
- **Post-treatment periods:** 4 (2016-2019, primary window)
- **Estimated outcome variance:** Care home closures per LA-year have meaningful variation (some LAs lose 0-2 homes/year, others 5-10)
- **Expected effect size:** If NLW bite of 0.1 (10% gap) causes 2-3 additional closures per LA over 4 years, this is detectable with 150 clusters
- **MDE:** Will be formally computed after data retrieval

## Data Sources

| Source | Variables | Access |
|--------|-----------|--------|
| CQC Care Directory | Care home locations, registration/deactivation dates, bed counts, ratings | Bulk CSV (active) + API (historical) |
| NOMIS ASHE (NM_99_1) | Median wages by SOC × LA | nomisr R package |
| NOMIS BRES | Employment by SIC × LA | nomisr R package |
| DHSC Section 251 | LA adult social care expenditure | data.gov.uk |
| ONS MYE | LA population estimates (total, 65+) | ONS API |
