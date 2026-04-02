## Discovery
- **Idea selected:** idea_0998 — Nigeria's staggered cashless policy rollout, a textbook staggered DiD missed by the literature
- **Data source:** World Bank Development Indicators (API) — state-level data from NBS/CBN proved inaccessible via API
- **Key risk:** Single treated unit (Nigeria) in cross-country design after state-level data pivot

## Execution
- **What worked:** The "branch exodus" finding is economically large (-1.9 branches/100k, 30% decline) and remarkably robust (leave-one-out range [-2.01, -1.74]). Permutation inference appropriate for single-unit case.
- **What didn't:** State-level data (NBS, CBN, Google Trends) all failed — NBS returned PDF not Excel, CBN URLs 404'd, Google Trends API returned errors for Nigerian sub-regions. This forced a pivot from 37-state staggered DiD to cross-country, fundamentally weakening identification.
- **Review feedback adopted:** Toned down causal language throughout (from "causal evidence" to "coincides with" / "suggestive evidence"). Made limitations about oil recession confound and pre-trends more prominent. Acknowledged the design can't separate policy from macro shocks.
- **Key lesson for future Nigeria papers:** NBS data is not reliably accessible via API. Consider alternative sources: bank annual reports for branch counts, NIBSS for payment data, or VIIRS nightlights for economic activity proxy. The staggered rollout remains a strong design if state-level data can be obtained through alternative channels.
