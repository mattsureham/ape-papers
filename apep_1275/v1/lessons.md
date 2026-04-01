# Lessons Learned: apep_1275 v1

## Discovery
- Pakistan 2022 floods provide excellent continuous treatment variation from satellite data
- UNOSAT flood extent maps via HDX are freely available and high-quality
- MODIS NDVI via ORNL DAAC API works but is slow (one point at a time) — only retrieved 141 of 751 planned tehsils due to API rate limits and timeouts
- The dual cropping calendar (kharif/rabi) creates a natural within-unit heterogeneity test

## Analysis
- Non-monotonic dose-response requires both continuous AND binned specifications to be convincing
- The quadratic specification captures the turning point but the binned specification is more transparent
- Pooled event studies across different crop seasons can show false pre-trend violations when seasonal dynamics differ — always run season-specific event studies
- Province-level clustering with only 8 provinces is aggressive but actually strengthened results here

## Process
- Session interrupted mid-execution; data was cached in RDS files enabling clean restart
- V1 format constraint (no figures) forces clearer textual description of results — may actually improve readability
- SDE table format has strict validation requirements (8 mandatory fields, panel structure, magnitude classification)
- Need ≥10 bib entries for V1 validation

## Summary
Paper documents non-monotonic agricultural dose-response to flooding across seasons. Core finding: moderate flooding (20-50% of area) produces near-zero winter crop damage, consistent with soil moisture replenishment offsetting infrastructure disruption. Effect magnitudes are small (SDE ~0.04 for kharif, ~0.016 for rabi).
