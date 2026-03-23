## Discovery
- **Idea selected:** idea_1763 — SNAP-Medicaid data coordination and enrollment resilience during the 2023-24 unwinding. Selected for novel cross-program angle and largest administrative event in Medicaid history.
- **Data source:** CMS data.medicaid.gov API (monthly enrollment) — API UUID had changed, required debugging. FRED unemployment data not available (missing API key in session).
- **Key risk:** Selection into E14 waivers correlates with state administrative capacity, contaminating the DiD.

## Execution
- **What worked:** CMS API data fetch (after finding correct UUID). Clean panel construction. Pre-trends analysis revealed the selection problem immediately, allowing honest reporting.
- **What didn't:** Pre-trends are significant at longer horizons (-12, -9 months), suggesting E14 states differ in underlying capacity. Post-treatment event study coefficients are imprecise — CIs include zero for all months. The original manifest called for T-MSIS claims data; had to pivot to enrollment (less novel).
- **Review feedback adopted:** All three reviewers flagged the pre-trends violation and imprecise post-treatment estimates. Rewrote abstract, results, and discussion to honestly report imprecision and acknowledge selection concern. Removed overstated "5-6.5 pp" claim, replaced with cautious "suggestive" framing.
