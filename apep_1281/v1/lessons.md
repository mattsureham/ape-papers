## Discovery
- **Idea selected:** idea_1866 — multi-cutoff bunching in Australia's FHB subsidies. Chose for method (bunching is highest-rated in tournament), data quality (universe of transactions), and the July 2023 migration experiment.
- **Data source:** NSW Valuer General PSI — nested ZIP structure required custom extraction pipeline. Primary purpose field is messy freeform text.
- **Key risk:** Round-number heaping at $600K/$800K/$1M confounds policy-driven bunching.

## Execution
- **What worked:** The migration test is genuinely clean. $650K is not a round number, so pre-reform bunching there is strong policy evidence. Collapse from b=0.98 to b=0.27 post-reform is compelling.
- **What didn't:** The polynomial sensitivity (degree 5-9 flips sign at $800K) means pooled bunching levels are not reliably identified. Commercial/farm placebo shows more bunching than residential, undermining level comparisons.
- **Review feedback adopted:** Reframed identification to center on migration test rather than pooled levels. Acknowledged endogenous property type selection. Added discussion of Australian contract splitting practices. Noted $650K's non-round-number status as identification strength (from Gemini review).
