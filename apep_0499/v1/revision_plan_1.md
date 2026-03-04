# Revision Plan (Stage C)

## Issues Addressed

### 1. Compositional Evidence (All Reviewers)
- **Added:** Figure 7 showing apartment share trends for treated vs. control
- **Result:** ACV cities shift from 48% to 52% apartment share post-treatment; controls stay flat
- **Impact:** Direct evidence supporting the compositional interpretation

### 2. Control Group Discussion (All Reviewers)
- Acknowledged rural/urban mismatch more explicitly in Limitations
- Added paragraph noting that propensity-score matching is a natural extension
- Department-by-year FE absorbs regional shocks but not within-dept urbanity trends

### 3. COVID Confounding (All Reviewers)
- Strengthened discussion of COVID timing coincidence
- Noted that dept-by-year FE controls for regional pandemic shocks
- Acknowledged that within-dept differential urbanity trends remain a concern

### 4. Code Fixes
- Fixed Occitanie region split (was split into Occitanie/Occitanie2)
- Added set.seed() for bootstrap reproducibility
- Fixed Euro sign rendering in figures
- Removed undefined \floatfoot commands
- Fixed tablenotes without threeparttable

### Not Addressed (Future Work)
- Propensity score matching / synthetic controls (requires extensive new analysis)
- Triple-difference with urbanity measures (needs additional data)
- Dose-response with funding amounts (data not available)
- Repeat-sales indices (DVF doesn't include property identifiers for panel)
