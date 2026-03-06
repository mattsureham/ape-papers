# Revision Plan — Round 1 (Post External Review)

## Summary of Reviews
- GPT R1: MAJOR REVISION — inference, measurement, overclaiming
- GPT R2: REJECT AND RESUBMIT — inference, Google Trends construction, weather, claims
- Gemini: MAJOR REVISION — WCB needed, Delhi outlier, multiple testing

## Changes Implemented

### 1. Wild Cluster Bootstrap Inference (ALL reviewers)
- Implemented manual WCB using Rademacher weights (fwildclusterboot unavailable for R 4.3.2)
- WCB p-values: full sample 0.69, high-internet 0.45, monsoon 0.32
- Result: subsample significance was artefact of few-cluster bias
- Paper now transparently reports WCB results and recalibrates all claims

### 2. Leave-One-State-Out Analysis (ALL reviewers)
- Full LOSO analysis: 20/21 states maintain negative interaction
- Only Delhi flips sign when dropped
- Results reported in new robustness subsection with honest discussion

### 3. Triple Interaction (GPT R2, Gemini)
- Replaced median split emphasis with continuous triple interaction
- Temp × Ag Share × Internet: β = -0.73, p = 0.049 (conventional CRVE, all 21 clusters)
- This is now the paper's strongest statistical result

### 4. Claim Recalibration (ALL reviewers)
- Removed "robust" claims from conclusion
- Abstract rewritten to feature triple interaction instead of subsample p-values
- "We document" → "suggestive patterns consistent with"
- Policy implications explicitly labeled as speculative
- Attention substitution framed as sign-pattern evidence, not demonstrated mechanism

### 5. Delhi Leverage Discussion (ALL reviewers)
- Robustness section acknowledges sign flip honestly
- LOSO analysis provides systematic diagnostic
- Paper discusses implications for interpretation

## Not Addressed (acknowledged as limitations)
- State-centroid weather (would require full data pipeline rebuild)
- Multilingual search terms (would require new data collection)
- District-level analysis (Google Trends doesn't support Indian districts)
- Individual-level WVS data (requires manual registration)
- Multiple testing adjustment (acknowledge but argue convergent evidence approach)
