# Internal Review — Round 1

**Paper:** Can You Hear Me Now? The Null Effect of EU Roaming Abolition on Cross-Border Tourism
**Reviewer:** Claude Code (Internal)
**Date:** 2026-03-11

## Verdict: MINOR REVISION

## Strengths

1. **Excellent framing of a null result.** The paper opens with a vivid hook (German tourist in Strasbourg), states the null clearly, and develops three mechanism-based explanations. This is how null results should be presented.

2. **Strong identification strategy.** The spatial DiD between border and interior NUTS2 regions is clean, with multiple built-in placebos (domestic tourism, external borders). Pre-trends are convincingly flat (joint F=0.67, p=0.62).

3. **Comprehensive robustness.** Leave-one-out, CEM matching, Rambachan-Roth sensitivity, placebo timing, extended sample, distance-based treatment — thorough battery that all confirms the null.

4. **Good literature positioning.** Three clear contributions: RLAH literature (extending beyond telecom), border effects (digital vs physical), salience/transaction costs.

5. **Discussion teaches a principle.** The "shallow vs deep barriers" framework in the Discussion is genuinely useful for policymakers. The conclusion's metaphor ("oiling a door that was never locked") is memorable.

## Issues to Address

### Methodology (Minor)

1. **Figure 4 y-axis scaling.** The domestic placebo figure shows one series starting near 0 and climbing to ~100, while the other starts at ~85. This looks like a data issue — possibly an outlier year dragging the index down, or the base year calculation has a problem. Both series should be comparable to Figure 3's range. Check the underlying data.

2. **Table 3 variable names.** The table shows raw variable names (`border_post`, `internal_post`, `log_foreign`) rather than formatted labels like Table 2. Should use consistent formatting.

3. **Within R² values.** The within R² values in Table 2 are extremely low (0.00079 for column 1). While this is expected when the treatment effect is null, it's worth noting in the text that the region and year FEs explain most variation, and the treatment interaction adds essentially nothing — which is precisely the null result.

### Writing (Minor)

4. **Section numbering gap.** The roadmap paragraph (end of intro, p.3) references "Section 2... Section 3... Section 4... Section 5... Section 6... Section 7... Section 8" — verify these all match actual section numbers.

5. **Figure placement.** Figure 1 (border map) sits on a page by itself with substantial white space. Consider adjusting placement.

### Exhibits

6. **Figure 3 legend.** The legend labels show "Border regions" (triangle) and "Interior regions" (circle), but the colors are hard to distinguish in grayscale printing. Consider using more distinct line patterns.

## Summary

A well-executed null result paper with strong identification and thoughtful mechanism discussion. The main issues are cosmetic (Figure 4 scaling, Table 3 formatting). The paper is ready for external review after these minor fixes.
