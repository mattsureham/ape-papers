## Discovery
- **Idea selected:** idea_0130 — Privacy laws and business formation. Chose for first-order policy stakes, clean staggered DiD, and confirmed Census BFS data.
- **Data source:** Census BFS weekly state CSV — downloaded cleanly, 53K+ rows. NAICS sector data was national-only (not state-level), blocking the planned DDD.
- **Key risk:** COVID overlap with California's CCPA (Jan 2020). Addressed with donut-hole and CA exclusion.

## Execution
- **What worked:** The staggered CS-DiD was clean and the null result is genuinely informative. 20 treated states with 10 cohorts provides real variation. Leave-one-out showed remarkable stability [-0.017, -0.002].
- **What didn't:** NAICS sector data only available at national level prevented the promised triple-difference. Had to pivot to application-type heterogeneity instead. The `fwildclusterboot` package isn't available for this R version.
- **Review feedback adopted:** Strengthened pre-trends discussion (mean reversion argument), added explicit limitation about missing sectoral analysis, expanded mechanism discussion with four alternative explanations for the null, acknowledged the counterfactual question (startup vs. retrofit costs).
