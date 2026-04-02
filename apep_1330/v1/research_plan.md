# Research Plan: The Windfall Trap — HEERF and the Institutional Absorption of Emergency Higher Education Relief

## Research Question
Did U.S. colleges and universities absorb the $76 billion Higher Education Emergency Relief Fund (HEERF, 2020–2021) into institutional budgets, or did they pass it through to students via tuition reductions and expanded financial aid? What was the incidence of the largest one-time federal higher education appropriation in American history?

## Identification Strategy
**Reduced-form / ITT design** exploiting the pre-determined HEERF allocation formula directly:

- **Treatment:** Predicted per-student HEERF (from 2018 Pell Grant share × FTE formula) × Post-2020 indicator
- **Design:** Institution and state × year FE absorb time-invariant characteristics and state-level shocks
- **Estimand:** The reduced-form effect of a $1,000 increase in formula-predicted HEERF per student on institutional outcomes

NOTE: Originally planned as a Bartik IV (predicted HEERF → actual federal revenue → outcomes), but the first stage was weak because federal revenue includes research grants that swamp the HEERF signal. Pivoted to reduced form, which is cleaner: the allocation formula IS the exogenous variation.

The formula is exogenous because it uses pre-pandemic (2018) institutional characteristics frozen before COVID-19.

## Expected Effects and Mechanisms
- **Windfall capture hypothesis:** Institutions absorb HEERF into general revenue, maintaining tuition and expanding non-student spending. Grant aid increases only mechanically (the 50% student-aid mandate).
- **Pass-through hypothesis:** Institutions reduce net price for students, expand Pell grant awards, and increase enrollment.

If windfall capture dominates, we expect: near-zero tuition response, grant aid increase ≈ 50% of HEERF (mechanical floor), enrollment unaffected or declining, completions unchanged.

## Primary Specification
Two-stage least squares:
- **Stage 1:** HEERF_it = α + γ × PredictedHEERF_i × Post_t + δ_s(i),t + X_it'β + ε_it
- **Stage 2:** Y_it = α + τ × HEERF̂_it + δ_s(i),t + X_it'β + u_it

Where PredictedHEERF_i uses 2018 Pell share × FTE, Post_t = 1{t ∈ {2020,2021}}, δ_s(i),t are state × year FEs, and X_it includes COVID controls.

Standard errors clustered at the institution level.

## Data Source and Fetch Strategy
- **Primary:** IPEDS via Azure DuckDB (az://raw/ipeds/ipeds.duckdb)
  - Finance (F1A): total revenue, federal revenue
  - Student Financial Aid (SFA): grant aid, Pell recipients
  - Institutional Characteristics (IC_AY): tuition
  - Enrollment (EFFY): 12-month headcount
  - Completions (C_A): degrees awarded
  - Directory (HD): institution metadata, state, sector
- **Controls:** State-level COVID deaths from CDC, state fiscal transfers
- **Sample:** 1,946 public institutions, 2015–2022 (8 years)

## Key Risks
1. HEERF correlates with COVID severity → control for state COVID deaths and lockdown stringency
2. Only 1 post-HEERF year (2022) → limited ability to test persistence
3. Simultaneous state appropriation changes → state × year FEs absorb this
4. HEERF had a 50% student-aid mandate → mechanical pass-through floor confounds voluntary pass-through
