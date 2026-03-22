## Discovery
- **Idea selected:** idea_0775 — SNAP BBCE adoption and the access-work tradeoff
- **Data source:** ACS 1-year (SNAP receipt, 2005-2022) + FRED LAUS (unemployment) + constructed BBCE adoption panel
- **Key risk:** Endogenous adoption timing (states adopted during Great Recession)

## Execution
- **What worked:** ACS SNAP data (B22003) available from 2005, giving 4+ pre-periods for the 2009 adoption cohort. FRED unemployment data clean and available from 2000. CS-DiD (Callaway-Sant'Anna) produced clear results with 7 treatment cohorts and clean pre-trends at k=-1 and k=-2.
- **What didn't:** Initial attempt used ACS B23025 (employment status) which wasn't available before 2011 — fatal for a design where most adoption was 2006-2010. Pivoted to SNAP participation as the sole outcome (dropped labor supply). USDA SNAP Policy Database download failed at all URLs; had to construct BBCE timing manually from published literature (CBPP, Anders & Rafkin 2025).
- **Key finding:** CS-DiD ATT = 0.0151 (1.5 pp increase in SNAP participation), highly significant. Effect grows over time (k=0: +0.001 → k=10: +0.036). TWFE is attenuated at 0.0095 — textbook negative weighting bias.
- **Pre-trend concern:** k=-4 and k=-3 show small positive coefficients (significant in CS-DiD), possibly reflecting anticipatory effects or concurrent Great Recession dynamics. k=-2 and k=-1 are clean.
- **Review feedback adopted:** TBD
