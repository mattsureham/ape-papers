## Discovery
- **Idea selected:** idea_0964 — UK calorie labeling 250-employee threshold (firm-size RDD angle)
- **Data source:** ONS UK Business Counts via NOMIS API (NM_142_1) — worked smoothly once geography codes were discovered (2092957699=England, 2092957701=Scotland, 2092957700=Wales). The LEGAL_STATUS dimension was a hidden gotcha: must filter for "Total" to avoid duplicate rows.
- **Key risk:** Aggregate data (country × industry × year) provides only 225 observations with 15 clusters. Scotland has tiny cell sizes (5-10 firms) in the 250+ bands.

## Execution
- **What worked:** The triple-difference design (England × food services × post-2022) with permutation inference (p=0.935) and placebo tests produced a clean, convincing null. The NOMIS API returned complete enterprise-level data from 2010-2024 without issues.
- **What didn't:** The original idea called for an RDD at the 250-employee threshold, but exact firm-level employment counts aren't available in ONS aggregate data. Had to pivot to a DDD approach, which is coarser. Reviewers noted this divergence.
- **Review feedback adopted:** Softened the null interpretation (can rule out >13% effects but not 5-10%), added paragraph explaining why RDD was abandoned, addressed anticipation effects, noted Scotland's small cell sizes as a limitation, added corporate restructuring as an undetectable avoidance channel.
