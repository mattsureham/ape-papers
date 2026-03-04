# Internal Review — Round 1

**Reviewer:** Claude Code (self-review as Reviewer 2 + Editor)
**Date:** 2026-03-04

## Verdict: MINOR REVISION

## Summary

The paper studies whether voluntary municipal mergers in Switzerland reduce referendum turnout, using 352 staggered merger events over 1991–2024. The identification strategy is strong: three complementary estimators (TWFE, Sun-Abraham, Callaway-Sant'Anna) all find a 1.2–3.1 pp decline. The Swiss voluntary setting addresses the coercion confound in prior Nordic studies.

## Strengths

1. **Clean identification.** The voluntary nature of Swiss mergers eliminates the resentment channel. The staggered timing over 33 years provides excellent variation. Event-study pre-trends are flat.
2. **Methodological rigor.** Three distinct estimators (TWFE, SA, CS-DiD) produce consistent estimates. The heterogeneity-robust estimators reveal that TWFE attenuates the effect through negative weighting.
3. **Rich institutional context.** The description of the five-stage merger process (Section 2) is vivid and makes the setting legible to non-Swiss readers.
4. **Compelling heterogeneity.** The merger-size and population interactions tell a clean story: the community-size mechanism operates most strongly where the proportional change is largest.

## Weaknesses (to address)

1. **Table variable naming.** Tables show code-like variable names (e.g., "turnout_pct" as depvar, "current_bfs" for FE labels). These should be clean academic labels. [UPDATE: Fixed in table regeneration with depvar=FALSE and expanded dict entries.]
2. **Results narration.** The results section was overly focused on "Column X shows..." narration rather than telling the story. [UPDATE: Revised to lead with findings, not table navigation.]
3. **Contribution framing.** The "three literatures" structure read as a checklist. [UPDATE: Rewritten as a single narrative about separating structural effects from political resentment.]
4. **CS-DiD event-study figure.** Figure 2 is largely redundant with Figure 1, as both show the same pattern. Consider moving to appendix in a future revision.
5. **Figure 4 (heterogeneity by size).** The overlapping confidence intervals make this cluttered. A panel layout would improve readability.
6. **Missing balance table.** A formal difference-in-means table with p-values for pre-merger characteristics would strengthen the parallel-trends argument beyond the event-study.

## Minor Issues

- The data section references dataset codes (px-x-1703030000_101) that could be relegated to the appendix.
- The Related Literature subsection (2.5) could be tightened by integrating findings into the narrative rather than giving each paper its own "mini-abstract."
- The dynamic effects in Column (3) of Table 5 show a slight escalation (-1.523 → -1.560 → -1.707) that could be interpreted as gradual erosion rather than the "flat trajectory" claimed in the text. The difference is small (within 0.2 pp) but the characterization should acknowledge this.

## Decision

The paper is well-executed with a clean identification strategy and consistent results across multiple estimators. The key exhibit and prose issues have been addressed. Remaining issues are minor and do not affect the core findings. **Recommend proceeding to external referee review.**
