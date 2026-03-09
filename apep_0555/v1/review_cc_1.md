# Internal Review (Round 1) — Claude Code Self-Review

**Paper:** When Cash Disappears: Demonetization and Food Market Disruption in Nigeria
**Paper ID:** apep_0555
**Timestamp:** 2026-03-09T16:30:00

## Summary

The paper studies how Nigeria's 2022 naira redesign affected food markets through a within-market, across-commodity DiD design using WFP price data. Main finding: cash-mediated commodity prices rose ~8.8% relative to banking-mediated goods. A within-rice comparison shows local rice fell 7.2% relative to imported rice, consistent with supply disruption.

## Key Issues Identified

### Critical
1. **Inference fragility**: 13 state clusters produce borderline CRVE. RI fails to reject null (p = 0.41-0.44). Paper must honestly present this limitation.
2. **CMI classification conflates cash-mediation with import status**: High-CMI goods are local staples; low-CMI are imports. Need to address seasonality, exchange rate exposure, trade policy confounds.
3. **Geographic descriptions were incorrect**: State list in paper did not match actual data. Fixed during advisor review cycle.

### Important
4. **Figure 6 normalization bug**: Raw price averaging across commodities with different scales created misleading price crash. Fixed to within-commodity normalized log prices.
5. **Overstated causal claims**: Abstract/intro used "demonstrates," "first causal estimates," "reveals." Softened throughout.
6. **Welfare calculation too precise**: Reframed as illustrative.

### Minor
7. Contributor placeholder (@CONTRIBUTOR_GITHUB) — replaced with @ai1scl.
8. 68 vs 56 markets in abstract — fixed.

## Assessment

The paper makes a genuine contribution by extending demonetization evidence to Sub-Saharan Africa and identifying a novel mechanism decomposition through the rice comparison. The main limitation is the tension between conventional inference and RI in a 13-cluster setting. After softening claims and adding robustness checks, the paper honestly presents what the evidence can and cannot support.

**Recommendation:** Proceed to external review with softened claims.
