# Lessons — apep_0590 v1

## Discovery
- **Policy chosen:** Mexico's Sembrando Vida agroforestry subsidy (2019-present) — Peltzman effect in environmental policy with clear perverse incentive design flaw, $1.5B+/year program
- **Ideas rejected:** Pinned idea (idea_0259), no alternatives considered
- **Data source:** Hansen/UMD Global Forest Change v1.12 (30m satellite data, 2001-2024) — freely downloadable GeoTIFFs, no API issues
- **Key risk identified too late:** Treatment assignment correlates with geography/ecology, not just marginalization. The program targets tropical southern states; control states are arid north. This makes cross-region DiD almost certain to fail parallel trends.

## Data
- Single-pass tabulation approach (using `tabulate` inside `exact_extract`) was ~24x faster than per-year binary raster approach for zonal statistics.
- The treecover2000 percentage band extraction failed silently (all zeros). Always verify ancillary raster extractions independently.
- Mexico has only 8 never-treated states (186 municipalities) creating severe control group limitations.

## Analysis
- Placebo test (shifting treatment 4 years earlier) was the single most informative diagnostic — decisive rejection.
- HonestDiD sensitivity analysis failed due to near-singular VCV — common when pre-treatment violations are severe.
- The TWFE vs CS-DiD sign reversal (+0.59 vs -0.30) was the paper's strongest finding.

## Writing & Review
- "Honest null result" framing required complete rewrite from initial "finding perverse effects" draft.
- Advisor review required 6 rounds to achieve 3/4 PASS. Main issues:
  - Column count mismatches in LaTeX tables
  - Rounding inconsistencies between text and tables (use same decimal precision everywhere)
  - Claims about "covariate adjustment" when no covariates were specified
  - Geographic facts (Sonora treatment status error)
  - Inference method inconsistencies across tables
- Never argue for identification in Section 5 and then revoke it in Section 6. Present the design as exploratory from the outset if you know pre-trends will fail.

## Key Takeaway
When a program is geographically targeted to ecologically distinct regions, cross-region DiD will almost certainly fail parallel trends. Identify this risk at the idea stage and either (a) find within-region variation or (b) frame the paper as methodological from the start.
