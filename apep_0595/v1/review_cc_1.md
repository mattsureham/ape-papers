# Internal Review — Claude Code (Round 1)

## Summary

This paper studies the spatial price effects of Nigeria's 2019 border closure using a difference-in-differences design comparing border-proximate to interior markets. The central finding is a null spatial gradient: no differential price effect between border and interior markets for rice or other staple cereals.

## Strengths

1. **Clean natural experiment:** The sudden, comprehensive, and unanticipated nature of the closure provides strong identification.
2. **Well-powered null with appropriate framing:** The paper correctly frames the null as informative rather than a failure, and provides multiple robustness checks.
3. **Comprehensive commodity analysis:** Testing across rice, maize, sorghum, and millet strengthens credibility.
4. **Honest treatment of limitations:** The paper acknowledges enforcement heterogeneity and data limitations.

## Issues Found and Resolved

1. **Summary statistics used wrong price variable** (price vs price_per_kg) — Fixed by updating 06_tables.R
2. **Market count inconsistency** (25 vs 21 border markets) — Fixed by reconciling with actual rice sample
3. **Non-tradeable placebo row with N=0** — Removed from Table 3
4. **Wild cluster bootstrap claimed but not computed** — Removed all references
5. **Figure numbering duplicated** (ggplot titles + LaTeX captions) — Removed "Figure N:" from ggplot titles
6. **250km threshold invalid** (1 control market) — Removed from paper and Table 4
7. **Causal claims exceeded design** — Reframed throughout as spatial gradient/differential
8. **USD price inconsistency** — Removed USD row from summary statistics
9. **HonestDiD claimed without results** — Added numerical bounds from saved output

## Verdict

Paper is ready for external review and publication after the above fixes.
