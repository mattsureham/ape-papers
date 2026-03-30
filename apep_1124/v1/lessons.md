## Discovery
- **Idea selected:** idea_1956 — EU IUU fishing sanctions + GFW satellite data. Novel data + quasi-experimental ID + clear policy puzzle.
- **Data source:** Global Fishing Watch v3 (Zenodo 14982712, fishing-vessels-v3.csv, 115 MB). BigQuery failed (no ADC), Comtrade API returned empty.
- **Key risk:** AIS coverage expansion could confound effort measurement; absorbing treatment conflates active and lifted sanctions.

## Execution
- **What worked:** GFW vessel-level data aggregated cleanly to flag×year panel. Sun-Abraham estimator via fixest ran without issues. Treatment panel from EU Commission press releases was straightforward to construct.
- **What didn't:** `did` package v2.3.0 has a bug in `.checkTypos` — switched to fixest::sunab(). BigQuery ADC not configured. Comtrade preview API returned no data for any country.
- **Review feedback adopted:** Softened "precisely estimated null" language (CIs too wide for that claim). Added absorbing treatment as explicit limitation. Added MDE/power discussion. Clarified that total effort ≠ IUU fishing.
