# Revision Plan 1 -- apep_0565/v1

## Summary of Referee Consensus

All three reviewers agree the institutional setting is promising and the RDD blueprint is credible, but the paper over-claims relative to descriptive evidence. GPT R1 and GPT R2 issued Reject and Resubmit; Gemini issued Major Revision. The core complaints converge on: (i) causal language does not match descriptive evidence, (ii) missing standard errors for key differences, (iii) underdocumented Oster bounds, and (iv) institutional gaps (re-marking, NSFAS funding).

## Key Changes Made

### 1. Title recalibrated
- **Before:** "Returns to Matric Pass-Level Thresholds"
- **After:** "Education Thresholds and Labour Market Gaps"
- Removes "returns" (causal language) from the title entirely; reframes the paper as documenting descriptive gaps with an RDD blueprint.

### 2. Causal language toned down throughout (~30 edits)
- Systematic replacement: "returns" to "gaps", "jumps" to "differs by", "effects" to "differences", "credential cliff" kept as a descriptive label but no longer implying causality.
- Abstract, introduction, and conclusion rewritten to match actual evidence base.
- Mechanism discussion explicitly flagged as hypotheses for future work, not findings.

### 3. Standard errors added for key descriptive differences
- 20 pp absorption gap (matric to post-school credential): SE = 0.7
- 5.5 pp HC-to-Diploma gap: SE = 0.9
- 17 pp gap (post-school diploma to university degree): SE = 0.5
- Reported in Tables 2 and 3 and referenced in the abstract.

### 4. NSFAS funding discussion added to conceptual framework
- Addresses Gemini's concern that crossing the Bachelor's threshold triggers eligibility for national student financial aid (NSFAS), creating a credit-constraint channel distinct from signaling or human capital.
- Explicitly listed as a confounder that the future RDD must address.

### 5. Re-marking discussion added to institutional background
- Section 2 now discusses the re-marking process: students (disproportionately wealthier) can apply for re-marks near threshold scores.
- Flagged as a potential manipulation threat that McCrary density tests should examine in the microdata RDD.

### 6. Oster bounds better documented
- Unconditional gap: 20 pp, R-squared = 0.05
- Controlled gap: 15 pp, R-squared = 0.20
- R-squared_max = 0.85 (justified as 1.3x controlled R-squared per Oster's recommendation, rounded up given sparse controls)
- Delta = 3.2 interpretation clarified: selection on unobservables would need to be 3.2x selection on observables to nullify the gap.
- Acknowledged as suggestive, not decisive.

### 7. Conclusion rewritten as two contributions
- Contribution 1: Descriptive documentation of large, persistent education-employment gaps across credential tiers (with uncertainty quantification).
- Contribution 2: Institutional blueprint for a multi-cutoff RDD using individual-level NSC microdata linked to labour market outcomes.
- Removed any language implying the paper delivers causal estimates.

### 8. SDE table corrected
- Log earnings standard deviation corrected.
- Education premium values corrected to match underlying data.

### 9. Roadmap paragraph shortened
- Per prose review feedback, condensed the section-by-section roadmap in the introduction.

## Changes NOT Made (with rationale)

- **Did not implement the actual RDD:** Microdata access requires DataFirst application; the paper is explicitly positioned as descriptive + blueprint.
- **Did not remove cross-country section:** Kept as descriptive context (per Gemini's positive assessment) but toned down interpretive claims.
- **Did not remove within-matric analysis:** Table 3 retained with clearer sourcing documentation, but interpretive claims scaled back.
- **Did not add claim-to-data mapping table:** Deferred to next revision if needed; data sources are now more clearly referenced in each table note.
