# Research Plan: The Windfall Trap — How Colleges Absorbed $76 Billion in Emergency Relief

## Research Question

Did HEERF (Higher Education Emergency Relief Fund, 2020-2021) reach students or get absorbed by institutions? Three consecutive federal relief acts injected $76 billion into US colleges using a formula based on Pell share × FTE enrollment. The formula was pre-determined from 2018 IPEDS data, creating quasi-random variation in per-student windfalls. If institutions captured the windfall through revenue substitution rather than passing it through as tuition cuts or financial aid, the largest one-time higher-education appropriation in US history was significantly less effective than intended.

## Identification Strategy

**Design:** Shift-share (Bartik) IV with institution and year fixed effects.

**Instrument:** Predicted HEERF receipt based on pre-pandemic (2018) institutional characteristics:

```
PredictedHEERF_i = (FTE_i_2018 × PellShare_i_2018) / Σ_j(FTE_j × PellShare_j) × TotalHEERF
```

This formula was fixed before the pandemic. The 2018 Pell shares and FTE enrollment are predetermined with respect to pandemic shocks.

**First stage:** Actual per-student federal revenue (2020-2021, from F1A) regressed on predicted HEERF per student.

**Second stage:** Outcomes regressed on instrumented federal revenue per student:
```
Y_{it} = β × FedRevenue_{it}(hat) + μ_i + δ_t + ε_{it}
```

where Y is tuition, grant aid per student, enrollment, or total institutional expenditure.

**Controls:** State×year FE absorbs state-level COVID severity and policy. Institution FE absorbs time-invariant institutional characteristics.

**Pre-trends:** 5 pre-treatment years (2015-2019). Event study with year-specific effects around 2020-2021 HEERF injection.

## Expected Effects and Mechanisms

- **Full pass-through:** β > 0 for grant aid; β < 0 for tuition; β ≈ 0 for enrollment if institutions cut prices rather than expand access
- **Institutional capture:** β ≈ 0 for all student-facing outcomes; HEERF absorbed as general revenue
- **Partial capture:** β > 0 for some outcomes (grant aid increases) but < 1 (not all HEERF reaches students)

## Data Sources

| Data | Source | Status |
|------|--------|--------|
| IPEDS institutional panel | Azure DuckDB (raw/ipeds/ipeds.duckdb) | ✓ Confirmed |
| Finance (F1A) | IPEDS | ✓ 2015-2022, ~1,950 public institutions |
| Student Financial Aid (SFA) | IPEDS | ✓ Pell recipients, grant aid |
| Tuition (IC_AY) | IPEDS | ✓ In-state/out-of-state tuition |
| Enrollment (EFFY) | IPEDS | ✓ 12-month unduplicated headcount |
| HEERF allocation data | ED fsapartners.ed.gov | To fetch |

## Design Parameters

- Institutions: ~1,950 public (4-year and 2-year)
- Years: 2015-2022 (5 pre + 2 treatment + 1 post)
- Observations: ~15,600 institution-years
- Treatment: Per-student HEERF ($800-$12,000 range)
- Clustering: State level (~50 clusters)
- Pre-period parallel trends: 5 years (2015-2019)
