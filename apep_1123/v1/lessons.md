## Discovery
- **Idea selected:** idea_1932 — FDAAA 801 transparency mandate, Phase 1 exemption as DiD control
- **Data source:** ClinicalTrials.gov API v2 — zero-friction, no key needed, 176K trials fetched in ~10 min
- **Key risk:** Phase 1 trials are fundamentally different from Phase 2/3 in publication incentives, creating pre-trends

## Execution
- **What worked:** Data quality excellent; 73,113 analysis trials with clean phase classifications. Industry vs non-industry heterogeneity (21.7 pp vs 0) is a compelling descriptive pattern.
- **What didn't:** Parallel trends assumption fails — placebo test significant at p=0.006. Pre-existing divergence between Phase 1 and Phase 2/3 reporting rates means the pooled DiD is biased. Even the industry-specific placebo shows pre-trends.
- **Review feedback adopted:** Toned down causal language throughout. Added alternative clustering (sponsor class, two-way). Acknowledged the pre-trend honestly in abstract, intro, results, and discussion. Reframed contribution as "first attempt at causal inference with suggestive heterogeneity pattern" rather than "clean causal estimate."
- **Lesson for future work:** Using "exempt" phases as control groups in regulatory DiD requires that both groups face the same secular trends. When the exempted group has structurally different incentives (Phase 1 safety studies vs Phase 2/3 efficacy), parallel trends will fail. A better design would use the 2017 Final Rule enforcement change as a within-Phase-2/3 shock, or exploit variation in "applicable clinical trial" status within Phase 2/3.
