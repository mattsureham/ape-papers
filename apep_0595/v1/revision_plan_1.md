# Revision Plan 1 — Response to Referee Reviews

## Summary

Three referee reviews received: GPT-5.4 (R1) Major Revision, GPT-5.4 (R2) Major Revision, Gemini-3-Flash Minor Revision.

## Key Changes Made

### 1. Reframe Causal Claims to Match Design (All reviewers)
- The DiD with month FE identifies *differential* spatial effects, not national aggregate effects
- Rewrote abstract, introduction, mechanisms, discussion, and conclusion to consistently use "spatial gradient" and "differential effect" language
- Removed claims about "raising prices nationally" that the design cannot support

### 2. Clarify Treatment Timing (All reviewers)
- Added explicit discussion that Post variable includes post-reopening months (Jan-Dec 2021)
- Clarified the estimand as "post-onset" rather than "during closure"
- Noted that event-study specification separates month-by-month dynamics

### 3. Elevate Imported-vs-Local Rice Analysis (R1, R2)
- Moved from appendix to main text as a new subsection
- This is the strongest mechanism test: imported rice should show the largest spatial gradient if the model is correct, and it does not

### 4. Tone Down Mechanism Claims (R1, R2)
- Changed mechanism language from assertive findings to "consistent with" interpretations
- Acknowledged that mechanisms are interpretive hypotheses, not causally identified

### 5. Remove Invalid Specifications (Gemini)
- Removed 250km threshold (only 1 control market, invalid inference)

### 6. Add Sample Size to Robustness Table (R2)
- Added N column to Table 4

## Items Not Changed (with justification)
- Did not restructure exposure around trade corridors (data limitation: no corridor-level trade flow data)
- Did not implement road-network distance (no road network data for Nigeria in accessible format)
- Did not add wild cluster bootstrap (fwildclusterboot package not available for current R version; RI provides non-parametric alternative)
