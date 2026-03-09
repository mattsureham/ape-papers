# Revision Plan 1

## Summary of Reviewer Feedback

Three external reviewers (GPT-5.4 R1: Major Revision, GPT-5.4 R2: Reject and Resubmit, Gemini: Minor Revision) raised the following key concerns:

1. **3-firm control group**: Main heterogeneity relies on only 3 streaming/royalty firms
2. **GISTM identification**: Cannot separate GISTM from broader post-2020 changes
3. **Inference**: Need stronger inference given thin control group
4. **Contemporaneous classification**: Firm characteristics measured today, applied historically
5. **Global benchmark**: S&P 500 may be inappropriate for non-US firms
6. **Binary tailings exposure**: Too coarse a measure

## Changes Already Made (Prior Revision Cycle)

### 1. Two-Way Clustering (Section 5.7)
- Re-estimated all key specifications with two-way clustering by event and firm
- Results strengthen: tailings penalty t=-2.77 (vs -2.25), GISTM interaction t=-2.85 (vs -2.02)
- Corrected language: no longer described as "more conservative"

### 2. Leave-One-Streaming-Firm-Out (Section 5.8)
- Dropped each of WPM, FNV, RGLD in turn
- Tailings coefficient ranges from -0.66 to -0.95, all directionally negative

### 3. Brumadinho vs GISTM Disentangling (Section 5.9)
- Created three-period specification: Pre-Brumadinho, Post-Brumadinho/Pre-GISTM, Post-GISTM
- Monotonic increase in tailings penalty across periods
- Post-GISTM effect significant even after separating Brumadinho

### 4. Language Softened Throughout
- Changed "GISTM created market discipline" to "consistent with GISTM codifying a pre-existing mechanism"
- Removed overclaiming about voluntary standards "working"

## Not Addressed (and Why)

- **Continuous tailings exposure**: Global Tailings Portal data is only available post-2020. Acknowledged as limitation.
- **Local-market benchmarks**: Would require 42 firm-specific local indices across 29 years. XME robustness provided as partial check.
- **Time-varying firm classifications**: Business-model distinction (operator vs streamer) is highly persistent. Finer characteristics less stable.
- **Wire-service event date validation**: Requires Bloomberg/Factiva access. Acknowledged as limitation.
- **ICMM membership / compliance data**: Not publicly available at required granularity.
- **Wild cluster bootstrap**: Added permutation test; formal WCB for 3-cluster treatment is at the boundary of what the method supports.
