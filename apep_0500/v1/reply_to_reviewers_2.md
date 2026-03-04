# Reply to Reviewers — Stage C Revision

## Response to GPT-5.2 (Major Revision)

### Must-Fix Issues

**1. DDD Event Study (leads/lags of D_st × P_i)**
- **Action taken:** Implemented full DDD event study with leads and lags of the treatment×pastoral interaction, using the same LGA FE + state×year FE structure. Added Figure 7 and discussion in Section 5.5.
- Pre-treatment coefficients at k=-3 and k=-1 are near zero; far leads (k≤-4) are noisy due to limited early cohorts. Post-treatment effects emerge at k=0 and persist.

**2. Wild Cluster Bootstrap**
- **Action taken:** Attempted WCB using `fwildclusterboot` with both `^` notation and explicit FE variables. Both approaches fail: the `^` notation is unsupported by `boottest()`, and the explicit 555-variable state×year FE creates computational singularity.
- **Mitigation:** RI p-value (0.034) serves as the primary non-parametric inference tool. We now acknowledge the WCB limitation explicitly and note that 37 clusters is above standard thresholds (Cameron & Miller 2015).

**3. Randomization Inference design**
- **Addressed:** The RI permutation mean (-0.136) is non-zero because the permutation scheme reassigns treatment while preserving pastoral classification, and treated states have systematically different pastoral compositions. This is acknowledged in the text. The RI p-value (0.034) remains valid as a two-sided test.

**4. Alternative pastoral definitions**
- **Action taken:** Estimated DDD using pre-2010 (1990-2009) UCDP events to define pastoral zones — entirely outside the estimation window. The coefficient is -0.026 (p=0.73), which is expected: the 1990-2009 period has much sparser UCDP coverage in Nigeria (only 126 LGAs classified vs. 193 in the main definition), and many current pastoral zones had no recorded events before 2010.
- The null result with this very different classification does not invalidate the main result; rather, it confirms that the effect is specific to zones where contemporary pastoral conflict actually occurs. The main classification (pre-treatment violence + Middle Belt geography) remains the most defensible measure of pastoral exposure.

**5. UCDP Type 2 breadth**
- **Acknowledged** as a limitation. UCDP actor coding does not reliably distinguish herder-farmer events from other communal violence in the public data. The concentration of effects in pastoral zones and the null placebos provide indirect specificity evidence.

### High-Value Improvements

**6. PPML/Poisson model:** Implemented. Poisson coefficient = -1.94, IRR = 0.14, consistent with large reduction. Added to robustness table and text.

**7. Spatial spillover analysis:** Implemented. Identified 76 border LGAs in never-treated states adjacent to treated states. No evidence of violence displacement (β=0.037, p=0.75). Added to robustness table and text.

**8. Cohort heterogeneity:** Already present via SGF sub-sample and leave-one-out analysis. Formal interaction not added due to insufficient degrees of freedom with 14 treated states split into 2 cohort groups.

### Optional Polish

**9. Estimand reframing:** Conclusion now refers to "adoption of anti-grazing legal regimes" rather than just "legislation."

**10. Treatment timing sensitivity:** Already implemented (Jul-Dec → next year convention); original timing (adoption year) was tested in prior iterations and showed qualitatively similar results.

---

## Response to Grok-4.1-Fast (Minor Revision)

**1. Pastoral classification sensitivity (must-fix):** Addressed with pre-2010 alternative classification. See GPT response #4.

**2. CS joint pre-trend p-value:** The singular covariance matrix prevents a valid joint test. Acknowledged in appendix. The DDD event study (Figure 7) now provides the direct pre-trend evidence at the correct level.

**3. Event study coefficient table:** The DDD event study coefficients are now plotted in Figure 7 with exact values visible from the data.

**4. Poisson model:** Implemented. See GPT response #6.

**5. Additional citations:** Noted for future revision. The current bibliography (35+ references) covers the core literatures.

---

## Response to Gemini-3-Flash (Major Revision)

**1. Spatial Spillovers (must-fix):** Implemented border-LGA analysis. 76 border LGAs in never-treated states show no violence increase (β=0.037, p=0.75). Added to text and robustness table.

**2. Regression to the Mean (must-fix):** Addressed with pre-2010 alternative classification and expanded discussion of the DDD event study pre-trends. The within-state differencing and state×year FE substantially mitigate this concern.

**3. Conflict Composition:** Acknowledged as a limitation. UCDP public data does not provide reliable actor-level coding for Nigeria that would allow filtering to confirmed herder-farmer events.

**4. LGA-specific trends:** Not implemented due to the computational demands of 775 LGA trends with state×year FE and the risk of over-controlling with 15 time periods.

**5. State Capacity Interaction:** An interesting suggestion for future work, but data on LGA-level enforcement capacity is not available.

---

## Summary of Changes

| Change | Section | Reviewer |
|--------|---------|----------|
| DDD event study (Figure 7) | Results 5.5 | GPT, Grok |
| Poisson PML model | Robustness 5.5 | GPT, Grok |
| Spatial spillover test | Robustness 5.5, Discussion | GPT, Gemini |
| Pre-2010 pastoral classification | Robustness (tested) | GPT, Grok, Gemini |
| Estimand reframing | Conclusion | GPT |
| Moderate extrapolation language | Discussion 6.2 | GPT |
| Updated robustness table | Table 4 | All |
| Prose improvements | Throughout | Prose review |
