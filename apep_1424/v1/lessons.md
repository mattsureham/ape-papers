# Lessons — apep_1416 v1

## Discovery
- Judge leniency IV for housing markets was an untouched angle despite 5+ prior APEP papers using the same instrument for other outcomes (crime, labor, remittances).
- The idea scored well on novelty (new outcome) and identification (proven IV), but the housing outcome at county level turned out to be too geographically aggregated.

## Execution
- **Critical lesson: Always include entity fixed effects when the instrument varies within entity over time.** Initial specs with only year FE showed spectacular results (rent +1.60, t=6.9, F=407) but the placebo test on lagged outcomes showed identical effects — a clear sign of between-court confounding (lenient courts in expensive cities). Adding court FE was essential and collapsed all effects to null.
- The EOIR parquet from deportationdata.org (317MB) was far more efficient than the full 4.26GB EOIR zip file.
- County FIPS matching required care: the `county_fips_code` field is already 5-digit, not 3-digit. Double-prefixing produced invalid codes.
- ACS fips was integer vs character — type mismatch silently produced zero merge matches.
- `noncitizen_share` had 12 NAs that propagated into summary stats as "NA & NA" in LaTeX.

## Review
- All three reviewers (codex-mini, deepseek-v3.2, qwen3.5-397b) independently identified geographic mismatch as the primary concern — courts serve wide catchment areas, diluting county-level effects.
- Reviewers suggested ZIP-code level analysis, housing supply elasticity heterogeneity, and power calculations as V2 improvements.
- The null result was well-received as informative given the strong first stage and clean placebos.

## Summary
A well-identified null result. The legal status channel (asylum grants) does not detectably affect county-level housing markets, likely due to geographic diffusion of treatment effects. The paper's main contribution is bounding the legal status premium and sharpening the immigration-housing literature: whatever drives the positive effects found by Saiz (2007) and Howard (2020), it is not the legal status margin at county scale.
