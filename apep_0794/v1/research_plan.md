# Research Plan: Testing Without Tests

## Research Question

Did the COVID-forced transition to test-optional admissions diversify the racial and socioeconomic composition of US college enrollment? We exploit the fact that virtually all 1,084 test-requiring institutions dropped SAT/ACT requirements in 2020, using pre-COVID selectivity (SAT 25th percentile) as continuous treatment intensity.

## Identification Strategy

**Continuous Treatment Intensity DiD.**

- **Treatment:** All 1,084 institutions that required SAT/ACT in 2019 became test-optional in 2020–2023 due to COVID testing center closures. This is exogenous — driven by public health, not diversity goals.
- **Intensity:** Pre-COVID SAT 25th percentile score. Institutions with higher SAT thresholds relied more heavily on standardized tests, so dropping them represents a larger screening disruption.
- **Unit fixed effects:** Institution FE absorb time-invariant characteristics.
- **Time fixed effects:** Year FE absorb aggregate trends (demographics, financial aid changes).
- **Estimating equation:** Y_{it} = α_i + γ_t + β(Post_t × SAT25_i) + X_{it}δ + ε_{it}
  - Y = racial share (Black, Hispanic), Pell share, admission rate, yield, net price
  - Post = indicator for 2020–2023
  - SAT25 = standardized pre-COVID SAT 25th percentile (2019)
  - X = time-varying controls (state appropriations, total applications)

## Key Threats and Solutions

1. **COVID confounds:** Many things changed in 2020 beyond test requirements.
   - **Placebo:** ~800 institutions that were ALREADY test-optional before 2019. These experienced the same COVID shock but NO change in testing policy. If β reflects test-optional effects (not COVID), the placebo group should show no intensity gradient.
   - **Triple-difference:** Compare intensity gradient among newly test-optional vs. always test-optional institutions.

2. **Selectivity trends:** More selective schools may have different enrollment trends.
   - **Pre-trends:** Event study 2016–2019 should show flat coefficients.
   - **Controls:** State funding, institutional spending, total applications.

3. **Composition changes vs. reallocation:** Increased minority enrollment at selective schools could reflect reallocation from less selective schools.
   - **Aggregate analysis:** Check total minority enrollment across the system.

## Expected Effects and Mechanisms

- **Mechanism:** Test-optional removes a barrier disproportionately affecting Black and Hispanic applicants (well-documented SAT score gaps). More selective schools, where test scores play a larger role in admission decisions, should see the biggest compositional shifts.
- **Expected β:** Positive for minority shares at high-SAT institutions (they become more accessible). Possibly negative for admission rates if applications surge.
- **Null hypothesis:** Test-optional is cheap talk — schools use other screening mechanisms (GPA, essays, LORs), and compositional effects are negligible. This would be an important finding.

## Primary Specification

```
share_black_{it} = α_i + γ_t + β(Post_t × SAT25_i) + ε_{it}
```

Clustered standard errors at institution level. Robustness: state-by-year FE, wild bootstrap, alternative intensity measures (SAT midpoint, admission rate).

## Data Sources

- **IPEDS (Azure):** `raw/ipeds/ipeds.duckdb` — 23 tables, 7,000+ institutions, 1997–2024
  - `adm`: Admissions data (test requirements, SAT scores, applications, admits)
  - `ef_a`: Enrollment by race/ethnicity/gender
  - `sfa`: Student financial aid (Pell grants, net price by income quintile)
  - `ic`: Institutional characteristics (sector, Carnegie class)

## Fetch Strategy

1. Connect to Azure DuckDB via `scripts/lib/azure_data.R`
2. Query `adm` for test requirements and SAT scores (2014–2023)
3. Query `ef_a` for enrollment by race (2014–2023)
4. Query `sfa` for financial aid (2014–2023)
5. Merge on `unitid` × `year`
6. Classify treatment intensity from 2019 SAT 25th percentile
