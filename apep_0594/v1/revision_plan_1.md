# Revision Plan 1 — apep_0594 v1

**Date:** 2026-03-11
**Triggered by:** Stage C external reviews (GPT R1: MAJOR REVISION, GPT R2: REJECT AND RESUBMIT, Gemini: MAJOR REVISION)

## Changes Implemented

### 1. Design Terminology (Priority: High)
- Replaced all "shift-share" references with "continuous-treatment DiD"
- Retained Bartik citations for context only

### 2. Mean Reversion (Priority: High)
- Added dedicated paragraph in Threats to Validity
- Added region-specific linear trends robustness (beta=-0.250, SE=0.117)
- Added COVID exclusion robustness (beta=-0.208, SE=0.235)

### 3. Weighted Specification Inference (Priority: High)
- Added wild cluster bootstrap for weighted spec (p=0.009)
- Present both unweighted and weighted estimates transparently

### 4. Relabeling Claim Calibration (Priority: Critical)
- Removed categorical language ("labeling exercise," "changed labels, not jobs")
- Reframed as "consistent with substantial relabeling"
- Acknowledged fijo discontinuo legal protections
- Presented employment null as informative but not definitive

### 5. Robustness Expansion (Priority: Medium)
- Region-specific linear trends
- COVID quarter exclusion
- Weighted bootstrap p-value
- All added to Appendix C table and discussed in robustness section

### 6. Literature and Tone (Priority: Medium)
- Toned down "first causal evidence" and magnitude claims
- Removed drug policy analogy
- Cautious pre-trend language

## Changes NOT Made (with rationale)
- Pre-2020 treatment intensity: Regional rankings highly stable; noted as limitation
- Region-sector panel: Data not available at this granularity from EPA
- Direct fijo discontinuo measurement: Requires MCVL administrative access
- Binned event study: Quarterly granularity preferred for 11-year visual
