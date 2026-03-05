# Reply to Reviewers

## Overview of Changes

This revision addresses the core concerns raised by all three reviewers. The most consequential changes are:

1. **Added distance polynomial to all specifications** — The preferred specification now includes a quadratic polynomial in signed distance to the boundary, which approximately halves the estimated boundary differential (from 13-16% to 6-8%). This addresses GPT R2's concern that the omission of the running variable was "a major design flaw."

2. **Reframed from causal to descriptive** — The paper now consistently describes findings as "boundary price differentials" rather than "causal effects of designation." The abstract, introduction, identification section, and conclusion have all been rewritten to reflect this more measured interpretation.

3. **Corrected boundary FE interpretation** — Section 5 now clearly states that boundary fixed effects absorb the *average* price level at each boundary but do *not* absorb systematic inside-outside differences.

4. **Added geocoding precision discussion** — New paragraph in the identification section discussing how DVF geocoding imprecision becomes first-order at narrow RDD bandwidths.

5. **Softened mechanism claims** — The mechanisms section now describes findings as "descriptive heterogeneity" rather than mechanism tests.

---

## Point-by-Point Responses

### GPT-5.4 R1

**Concern: 2024 boundary revision timing.** Clarified in Section 2: revised boundaries took effect January 1, 2025; all transactions in sample (2020-2024) were under the 2015 boundaries.

**Concern: Retained (Placebo) labeling.** Changed to "Retained QPV" throughout all tables and figures.

**Concern: Missing N in tables.** Added N columns to all relevant tables.

**Concern: Donut instability.** The donut table is now included (Table 4) with honest discussion of the instability, particularly at the 200m donut where the gained estimate jumps and the retained estimate flips sign.

**Concern: Bandwidth sensitivity interpretation.** Rewritten correctly: with the distance polynomial, estimates are now stable across bandwidths (5-8%), confirming that the prior bandwidth-dependent pattern was driven by spatial gradient contamination.

### GPT-5.4 R2

**Concern: The central causal claim is not identified.** ADDRESSED. The paper is now framed as documenting boundary price differentials, with explicit acknowledgment that the cross-sectional design cannot separate designation effects from pre-existing neighborhood quality differences.

**Concern: The parametric specification omits the running variable.** ADDRESSED. All specifications now include a quadratic distance polynomial (signed_dist + signed_dist²). This approximately halves the estimates, confirming the reviewer's diagnosis that the original specification loaded on spatial gradients.

**Concern: Boundary FE interpretation overstated.** ADDRESSED. Section 5 now clearly states boundary FEs absorb the average level but not side-specific differences.

**Concern: Covariate imbalance is direct evidence against local comparability.** ADDRESSED. The paper now acknowledges this honestly rather than downplaying it, noting that the income-based selection criterion ensures co-discontinuities in neighborhood characteristics.

**Concern: The "gained" vs "retained" comparison is too noisy.** ACKNOWLEDGED. The commune-level classification limitation is discussed more prominently with its implications for interpretation.

**Concern: Mechanism claims are not identified.** ADDRESSED. Section 7 is now titled "Mechanisms" but explicitly describes the property-type heterogeneity as descriptive rather than causal mechanism evidence.

**Concern: Missing methodological literature (Keele and Titiunik 2015).** ADDRESSED. Added citation and discussion in the boundary discontinuity literature section.

### Gemini-3-Flash

**Concern: Geocoding precision at narrow bandwidths.** ADDRESSED. New paragraph in Section 5 discusses how DVF geocoding (parcel-centroid interpolation) becomes first-order at the 17-27m RDD bandwidths.

**Concern: Commune-level proxy for Retained status.** ACKNOWLEDGED. The classification limitation and potential measurement error are discussed more prominently. Obtaining ZUS polygons for spatial overlay would improve precision but is not feasible with currently available bulk data.

**Concern: Donut instability.** ADDRESSED. The donut discussion now honestly characterizes the instability as a genuine concern rather than spinning it as robustness evidence.

**Concern: Over-claiming on mechanism.** ADDRESSED. The paper no longer claims the similarity of gained/retained coefficients supports a labeling mechanism. It presents three alternative interpretations with equal weight.

### Changes NOT Made (and Why)

1. **Pre-reform data (DiD around 2015 reform):** DVF data before 2020 is not available. This is acknowledged as the key limitation.

2. **ZUS polygon overlay:** National ZUS shapefiles are not available for bulk download. The commune-level proxy is acknowledged as imperfect.

3. **Additional covariates (census, school, crime):** Would require a major new data pipeline that is beyond the scope of this revision.

4. **Higher-level clustering (commune, department):** The main estimates use boundary-level clustering as appropriate for the design. Alternative clustering could be explored in future work.
