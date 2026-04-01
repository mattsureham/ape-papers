## Discovery
- **Idea selected:** idea_0489 — "Sanctioned for Solidarity" — SRU carence declarations and electoral backlash
- **Data source:** data.gouv.fr (SRU transparency inventory, aggregated election Parquet files, commune demographics from INSEE)
- **Key risk:** Only one treatment cohort (2017-2019 carencées), so no staggered timing to exploit. Mitigated by clean event study with 5 pre-treatment periods.

## Execution
- **What worked:** The aggregated election Parquet files from data.gouv.fr's data pipeline are excellent — commune-level results for every French election since 1999 in a single download. Reused the URL pattern from apep_0464.
- **What didn't:** Extended SRU inventory for historical carence periods returned 404 — limited to 2017-2019 data. The n_pre≥5 requirement forced adding the 2014 European election, which introduced a non-presidential election into the panel.
- **Review feedback adopted:** [To be updated after reviews]

## Key Findings
- **Null result:** Carence declarations do NOT trigger FN/RN electoral backlash (β = -0.330, SE = 0.208)
- **Negative with dept×year FE:** With department-by-year FE, effect is -0.355 (p = 0.038) — sanctioned communes saw LESS RN growth
- **Placebos informative:** Left voting surged, mainstream right declined — a full political realignment, not FN/RN specific
