# Internal Review — Round 1

**Paper:** apep_0533 v1 — Salary History Bans and the Gender Earnings Gap
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-05

## Verdict: **MINOR REVISION**

## Summary

This paper evaluates the effect of salary history bans on the gender earnings gap using QWI administrative data and a triple-difference design. The key finding is a precisely estimated null: the bans had no detectable effect on the aggregate gender gap. The design is strong (DDD with built-in mechanism test, 20 treated states, 31 controls, 60 quarters), the result is robust across estimators (TWFE, CS-DiD, Sun-Abraham, RI), and the null is informative given the paper's statistical power.

## Strengths

1. **Strong identification.** The DDD design with new hires vs. continuing workers is clever and provides a built-in placebo. The within-state, within-period comparison absorbs many confounders.
2. **Universe data.** QWI administrative records avoid the measurement error and small-sample issues of CPS-based studies.
3. **Honest null.** The paper presents the null forthrightly rather than mining for significance.
4. **Comprehensive robustness.** RI, Sun-Abraham, CS-DiD, excluded bundled states, pre-trend F-test—all point the same way.
5. **Good policy discussion.** The "Why the Null?" and "Implications" sections add genuine value.

## Weaknesses and Suggestions

### Methodology
1. The CS-DiD standard errors use manual aggregation due to a `did` package bug. The paper should acknowledge this more prominently and note the uncertainty around those SEs.
2. The power analysis claims MDE of 0.007 log points but the DDD MDE is 0.020. The abstract should reference the DDD MDE since that's the primary specification.

### Writing
3. The abstract is long (150+ words). Trim to 140 words for cleaner page 1 fit.
4. The introduction's third contribution paragraph (QWI decomposition as design tool) feels thin. Either expand with a concrete example or fold into the conclusion.

### Tables/Figures
5. Table 3 (CS-DiD) should note the software compatibility issue more clearly.
6. The industry heterogeneity figure could benefit from a horizontal reference line at zero for easier visual interpretation.

### Minor
7. Some sections refer to "I" and others use passive voice inconsistently. Standardize.
8. The Acknowledgements section has placeholder contributor names that need to be filled at publish time.

## Overall Assessment

A solid contribution that reports a credible null result. The main limitation is the cell-level aggregation of QWI data, which the paper acknowledges honestly. The DDD design is the paper's signature contribution—it should be marketed more aggressively in the abstract and introduction. Minor revisions to address the above points would strengthen the paper.
