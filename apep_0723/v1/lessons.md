## Discovery
- **Idea selected:** idea_0907 — EU Youth Employment Initiative RDD at 25% threshold
- **Data source:** Eurostat (yth_empl_110, edat_lfse_22, lfst_r_lfe2emprt) — keyless, worked perfectly via eurostat R package
- **Key risk:** Whether the threshold generates enough dosage variation given heterogeneous implementation

## Execution
- **What worked:** Eurostat data access was flawless. 212 NUTS2 regions, 99 treated, 113 control across 26 countries. McCrary density test (p=0.67) supports no manipulation. The RDD design is clean.
- **What didn't:** The result is a precise null: NEET coef=+0.026 (SE=1.56, p=0.79), Youth employment coef=-0.94 (SE=2.74, p=0.73). The YEI had no detectable effect at the 25% threshold. Agent-written R code needed many fixes (column names, file paths, rdrobust accessor format).
- **Review feedback noted:** Likely explanations for the null include: (1) EUR 8.8B spread across 100+ regions may be too diffuse per-region, (2) heterogeneous national implementation dilutes the treatment, (3) the threshold may have been set too low to create meaningful dosage variation.

## Key Lesson
Precise nulls on large EU programs are valuable — they challenge the assumption that threshold-based allocation rules automatically create evaluable treatment contrasts. When spending is distributed across many regions and implementation varies by country, the RDD threshold may not generate sufficient dosage variation for detection.
