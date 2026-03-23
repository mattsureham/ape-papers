## Discovery
- **Idea selected:** idea_0679 — Japan's Barrier-Free Act creates a textbook RDD at 3,000 daily users with freely downloadable MLIT data
- **Data source:** MLIT S12 (station passengers) + L01 (official land prices) — both freely downloadable, no API keys needed
- **Key risk:** Running variable (station ridership) is post-treatment only; L01 2005 wave returned 404

## Execution
- **What worked:** The diff-in-disc design was the right call. Cross-sectional RDD showed a 17% gap, but pre-treatment prices were also discontinuous. The diff-in-disc cleaned this up to a credible 2.9% effect. McCrary test was perfect (p=0.998).
- **What didn't:** MLIT data format varies wildly across years — some files use Japanese column names, others use S12_XXX codes. The 2012 and 2021 files had Shift-JIS encoding issues. Had to settle on the 2019 file for best coverage.
- **Method insight:** For threshold-based RDDs where the threshold correlates with unobserved heterogeneity (e.g., urban vs rural), diff-in-disc should be the default specification, not just robustness. The cross-sectional RDD was biased by a factor of 6x.
- **Review feedback adopted:** Added ITT framing (92% compliance → TOT ≈ 3.2%), strengthened threats to validity section on running variable endogeneity and pre-treatment contamination, added former 5,000 threshold as confirmatory placebo test.
