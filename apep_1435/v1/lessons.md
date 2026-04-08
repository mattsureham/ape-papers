## Discovery
- **Idea selected:** idea_2234 — comment-period length and rule revision; user-specified.
- **Data source:** Federal Register API (proposed/final rules + RIN linkage).
- **Key risk:** Endogeneity of comment-window length to anticipated rule revision.

## Execution
- **What worked:** RIN-based linkage of proposed→final rules from FR API; agency×year FE with cluster-robust SEs.
- **What didn't:**
  - Federal Register `raw_text_url` is throttled to ~1 file/sec per IP. Bulk text retrieval for 5,820 files was infeasible within the project's hardware/time budget. Pivoted: page-count change as primary outcome on the 3,703-pair full sample, text-distance as secondary on 128 cached pairs.
  - **EO 12866 IV failed:** the significance designation moves the realized comment window by only 3.4 days (mean 48.8 vs 45.4), producing a first-stage F of 1.9 — agencies treat the EO's "60-day floor" as soft guidance. The IV is reported transparently but not used for inference.
- **Reframed:** primary contribution shifted from "does more time change rules?" to "EO 12866's 60-day floor is mostly nominal." The conditional-correlation result on revision is reported as a secondary, more tentative finding.
- **Review feedback adopted:** all three reviewers (codex-mini advisor, GPT-5.4, deepseek-v3.2) converged on (a) reframe around EO implementation gap, (b) soften causal language to "conditional correlation," (c) acknowledge page-count proxy limits. Adopted in one revision pass.

## Field notes
- The Federal Register's documented API is generous on metadata but the underlying full-text endpoint is rate-limited per IP in a way that is invisible until you try to bulk-download. Future text-as-data papers in this corpus should plan for ~1 day of background fetching per ~5,000 documents, or use a cached corpus.
