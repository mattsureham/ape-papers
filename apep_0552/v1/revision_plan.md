# Revision Plan — apep_0552 v1

## Reviews received
- Internal (Claude Code): Minor Revision
- GPT-5.4 R2: Reject and Resubmit
- Gemini-3-Flash: Major Revision

## Key themes across all reviews

### 1. Reframe core claim (ALL reviewers)
**Issue:** Paper overclaims "clean decomposition" of information vs regulation. The channel-specific designs (RDD, triple-diff) fail empirically.
**Action:** Rewrite abstract, intro, and conclusion to frame the paper around two robust findings: (a) post-reform price penalty for passoire properties, (b) strategic manipulation at thresholds. Channel decomposition is exploratory/suggestive.

### 2. Heterogeneity puzzle (Gemini, Internal)
**Issue:** Houses > apartments and rural > urban — opposite to regulatory prediction. Suggests informational/renovation-cost channel dominates.
**Action:** Address this honestly in results and discussion. Reinterpret as evidence that renovation costs and informational salience may outweigh the pure regulatory channel.

### 3. Pre-treatment limitations (GPT R2, Internal)
**Issue:** One pre-period cannot validate parallel trends.
**Action:** Soften all language. Already partially done but need another pass.

### 4. RDD under manipulation (GPT R2, Internal)
**Issue:** McCrary tests show manipulation → standard RDD causal claims invalid.
**Action:** Already framed as suggestive. Further soften RDD and DiDisc interpretation.

### 5. Methodology change confound (ALL)
**Issue:** Concurrent DPE methodology change means DiD captures both effects.
**Action:** Acknowledge more explicitly in the interpretation. The DiD estimate is a composite of regulatory and methodological effects.

## Changes to implement
1. Rewrite abstract — two main findings, modest claims
2. Rewrite key introduction paragraphs — remove "first clean experiment"
3. Soften results language throughout
4. Address heterogeneity puzzle in discussion
5. Recompile PDF
