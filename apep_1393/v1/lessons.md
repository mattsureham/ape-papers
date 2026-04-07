# Lessons Learned: apep_1393

## Discovery
- The merger-IV design from Nguyen (2019) transfers well to racial mortgage disparities when combined with post-2018 HMDA expansion
- HMDA `derived_race` doesn't include Hispanic/Latino as a race category — it's in ethnicity. Pivot to Asian-White as secondary comparison

## Execution
- FDIC API migrated from `banks.data.fdic.gov` to `api.fdic.gov` — old URLs redirect but with issues
- CFPB Data Browser allows max 2 filter criteria per request; download broadly and filter in R
- HMDA `county_code` is already full 5-digit FIPS (e.g., "06037"), not 3-digit requiring state prefix
- 1-year merger window gives cleaner instrument than 3-year (mean exposure 0.70 vs 0.86, better F-stat)
- `fitstat()` in fixest behaves differently for OLS vs IV objects — use `fitstat(fs_model, "f")` for first-stage F

## Review
- All three empirics reviewers flagged county-level aggregation as main weakness; tract-level analysis with distance-to-closed-branch would be the key V2 improvement
- Reviewers want loan-level regressions exploiting DTI/LTV/AUS controls from expanded HMDA
- MSA-year FE preferred over state-year FE for banking market studies
- Table formatting: never use code variable names (`bw_denial_gap`) in table headers; use descriptive English

## Summary
Strong idea with clean first-stage (F=12.2) and sharp result (BW gap widens, AW gap null). The county-level aggregation is the binding constraint for a V2 revision — moving to tract-level with distance measures and loan-level controls would substantially strengthen identification.
