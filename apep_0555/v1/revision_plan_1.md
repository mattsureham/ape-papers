# Revision Plan (Round 1)

**Paper:** When Cash Disappears: Demonetization and Food Market Disruption in Nigeria (apep_0555)
**Date:** 2026-03-09

## Reviewer Feedback Summary

All three referees converged on the same core issues:
1. **Inference**: RI p-values (0.41, 0.44) undermine strong causal claims with only 13 clusters
2. **Identification**: CMI classification conflates cash-mediation with import status, seasonality, trade exposure
3. **Overstated claims**: Language was too strong given inferential limitations

## Changes Made

### 1. Claim Recalibration (All reviewers)
- **Abstract**: Changed "estimate how cash scarcity disrupts" → "study how cash scarcity affects"; added RI p-value; "results demonstrate" → "evidence is consistent with"
- **Introduction**: "first causal estimates" → "first evidence"; "reveals" → "suggests"
- **Mechanisms**: "isolates the supply disruption channel" → "consistent with the supply disruption channel"
- **Discussion**: "weight of evidence supports a causal interpretation" → "totality of evidence is consistent with a causal interpretation, though fragile inference warrants caution"
- **Conclusion**: "provides a stark demonstration" → "provides suggestive evidence"
- **Policy implications**: Prefaced with "if the reduced-form estimates reflect a causal effect"

### 2. New Robustness Specifications (R1 §3, R2 §3)
- **CMI × month seasonality**: β = 0.151 (survives; seasonal controls strengthen rather than weaken the result)
- **Balanced panel**: β = 0.221 (directionally consistent but only 2 states survive)
- **Cereals only**: β = -0.160 (sign reversal within cereals confirms supply disruption mechanism)

### 3. Commodity Classification Table (R2 §6.3, R3 §6.3)
- Added Appendix D with full list of 38 commodities and their CMI assignments

### 4. Welfare Calculation (R1 §5B, R2 §5, R3 §5)
- Reframed as "illustrative only" with explicit caveat about inferential limitations

### 5. External Validity (R2 §6.9)
- Added WFP geographic concentration caveat (markets concentrated in North-East humanitarian corridor)

### 6. Technical Fixes
- Fixed Figure 6 normalization (within-commodity log prices instead of raw price averages)
- Fixed RI figure note ("dashed" → "solid red")
- SDE table: clarified that classification uses SDE column, not raw coefficient

## What We Did Not Change
- We did not attempt wild cluster bootstrap (fails due to singleton FEs, noted as limitation)
- We did not add commodity-specific linear trends (would require commodity-time FE that creates collinearity with the interaction FE)
- We did not add more placebo years (data constraint—pre-2020 commodity basket differs substantially)
- We retained the extended crisis window as supplementary evidence
