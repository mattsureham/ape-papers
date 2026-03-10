# Revision Plan — apep_0573/v1 (Round 1)

## Context
Three external referee reviews received: GPT R1 (Reject & Resubmit), GPT R2 (Reject & Resubmit), Gemini (Major Revision). Core concerns: treatment timing misalignment, pre-trends, C-S SME divergence, claims too strong.

## Changes Made

### 1. Claim Calibration (All Reviewers)
- Reframed all causal claims as "reduced-form associations with transposition timing"
- Replaced "precisely estimated null" with more cautious language
- Added Rambachan-Roth bounds alongside baseline CIs in main results
- Softened RI language from "strongest possible confirmation" to "strong supplementary evidence"
- Added explicit RI caveat: does not fix treatment mismeasurement

### 2. Treatment Timing Limitation (R1 §1.1, R2 §A-B)
- Added new first limitation in Section 6.4 discussing gap between legal transposition and actual implementation
- Acknowledged award-date vs notice-date measurement issue
- Noted possibility of treatment attenuation toward zero

### 3. C-S SME Cohort Decomposition (R3 §3.1, R1 §1.3)
- Ran cohort-level decomposition: aggregate ATT (-0.202) driven by single 2017Q1 cohort (CY, FI, HR, LV, SE; ATT = -0.495)
- Added to main text (Section 5.2) and Appendix D
- Provides important context on fragility of this finding

### 4. Pre-trends Honesty (R1 §1.2, R2 §C, R3 §2)
- Removed claim that raw trends "evolve in parallel"
- Added F-test acknowledgment in raw trends figure discussion
- Added explicit note that RI does not address endogenous timing

### 5. Bootstrap Clarification (R2 §B)
- Renamed "Wild Cluster Bootstrap" to "Pairs Cluster Bootstrap"
- Added Cameron et al. (2008) citation
- Reported bootstrap CI alongside p-value

### 6. Other Fixes
- Added processing_days variable definition
- Fixed figure 7 legend (7→8 on-time states)
- Replaced placeholder contributor text with actual names
- Explained unbalanced panel (1,189 vs 1,680 expected cells)
- Added UK/Brexit data handling note

## Not Addressed (Outside Scope of Single Revision)
- Full redesign with notice-level data and monthly aggregation
- Provision-specific implementation dates
- First-stage evidence on procedure type changes (data limitation)
- Formal balance test on transposition timing predictors
