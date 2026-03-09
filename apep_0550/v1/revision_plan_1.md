# Revision Plan — Stage C

## Summary of Changes

All three referees (R&R from R1, Major Revision from R2 and Gemini) raised consistent concerns. The revision addresses:

### 1. Claim Calibration (All reviewers)
- Replaced "precisely estimated null" with "no evidence of large retail price effects" throughout
- Added explicit confidence intervals and effect size bounds
- Narrowed scope to "monitored retail prices" — not farm laws broadly
- Softened political economy claims (protests may have been about MSP, not retail prices)

### 2. Design Rhetoric (R1, R2)
- Replaced "remarkably clean" and "powerful" symmetric design language
- Acknowledged OFF coefficient is not a direct reversal test
- Added formal β1 = β2 equality test (p = 0.34)
- Split OFF period into post-stay and post-repeal sub-periods (both null)

### 3. Robustness Battery (R1, R2)
- **State-specific linear trends**: ON = 0.018 (0.108), essentially zero
- **Balanced sample**: 122 of 139 cells observed in all phases, identical results
- **Multiple placebo dates**: 7 alternative onset dates, actual coefficient within distribution
- **Formal pre-trend test**: WLS regression of pre-period coefs on time, p = 0.43

### 4. Inference (R1, R2)
- Attempted wild cluster bootstrap (incompatible with feols + high-dimensional FE)
- RI provides the non-parametric complement; acknowledged 28-cluster limitations
- Added Cameron, Gelbach, Miller (2008) citation for cluster inference concerns

### 5. Literature (R1, R2)
- Added de Chaisemartin & D'Haultfoeuille (2020) on continuous-treatment DiD
- Added Cameron, Gelbach, Miller (2008) on cluster inference
- Acknowledged reverse-treatment placebo is mechanically uninformative

### 6. Limitations Section (All reviewers)
- Expanded from 5 brief items to 6 substantive paragraphs
- Explicitly addresses: outcome scope, short treatment window, treatment measurement, market composition, cluster inference, commodity coverage

### What Was NOT Changed
- WCB could not be implemented due to fwildclusterboot/feols incompatibility
- Wholesale data unavailable (AGMARKNET inaccessible)
- Market-level regressions not feasible (WFP data already at market level, aggregated to state-commodity-month)
- First-stage evidence on implementation not available
