# Research Plan: Paying for Diplomas — Performance-Based Funding and the Cream-Skimming Margin

## Research Question

Do performance-based funding (PBF) formulas for public higher education increase degree completions — and if so, do they accomplish this by improving student success or by shifting enrollment away from at-risk students?

## Identification Strategy

**Staggered DiD (Callaway-Sant'Anna 2021):**
- Unit: Public 4-year institution
- Treatment: Year PBF 2.0 formula takes effect in institution's state
- ~30 treated states (2009–2020), ~18–20 never-PBF controls
- Clustering: State level

**Built-in placebo:** Private institutions in PBF states should show no effect.

## Data

IPEDS via Azure DuckDB at `raw/ipeds/ipeds.duckdb` (23 tables, 162K inst-year obs, 2002–2024).

## Outcomes

1. Bachelor's completions (c_a table)
2. 6-year graduation rate (gr table)
3. Pell share of enrollment (sfa table) — cream-skimming test
4. Minority enrollment share (ef_a table) — cream-skimming test
5. Total enrollment (effy table) — scale effect

## Exposure Alignment

Treatment (PBF adoption) is assigned at the state level and affects all public institutions receiving state appropriations. The treated population is public four-year institutions (IPEDS sector 1) in adopting states. Private institutions in the same states serve as an unexposed placebo group since they do not receive state appropriations subject to PBF formulas. Community colleges are excluded because their PBF formulas, metrics, and implementation timelines differ substantially from those governing four-year institutions.

## Table Plan

| # | Content |
|---|---------|
| 1 | Summary statistics |
| 2 | Main CS-DiD: completions + graduation rates |
| 3 | Cream-skimming: Pell share, minority share |
| 4 | Robustness: private placebo, alternative specs |
| App | SDE table |
