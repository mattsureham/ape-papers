# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-27T12:40:42.897173

---

### 1. Idea Fidelity

The paper largely pursues the original idea but deviates in two critical ways:

1. **Sectoral Scope**: The manifest focuses on construction, but the paper expands to professional services and ambulatory health care, arguing that the "verification chill" is ethnicity-wide, not industry-specific. This is a significant departure—while the DDD strategy is preserved, the interpretation shifts from a targeted enforcement effect to a broad behavioral response. The manifest’s "frozen labor market" framing is retained, but the mechanism is redefined.

2. **Mechanism Tests**: The manifest proposes decomposing hiring into *HirN* (new hires) and *HirR* (recalls) and testing whether *HirR* is unchanged. The paper does this but omits the earnings test (new-hire wage premium compression), which was a key part of the original welfare interpretation. The earnings results in Table 1 are statistically insignificant and not discussed, despite their centrality to the manifest’s hypothesis.

The identification strategy (DDD + Callaway-Sant’Anna) is correctly implemented, and the QWI data source is used as specified. The paper’s expansion to cross-sector spillovers is creative but risks diluting the original focus on construction.

---

### 2. Summary

The paper uses Census QWI data to show that state E-Verify mandates reduce Hispanic labor market fluidity by compressing both hiring and separation rates, creating a "frozen" labor market. A triple-difference design reveals that this effect is not construction-specific: Hispanic workers in professional services experience identical declines, while non-Hispanic workers are unaffected. The results suggest a worker-side deterrence mechanism, where Hispanic workers (regardless of documentation status) avoid job transitions due to perceived verification risk. The paper reframes E-Verify as a mobility tax rather than a demand shock.

---

### 3. Essential Points

**1. The DDD Null is Overinterpreted**
The paper argues that the DDD’s null result (Table 1, Panel A) proves the effect is ethnicity-wide, not industry-specific. This is plausible but incomplete. The DDD’s power is limited by the small number of treated states (8), and the null could reflect:
   - **Contamination**: If Hispanic workers in services are also deterred (as the paper claims), the DDD’s comparison group is invalid. The paper acknowledges this but does not test alternative DDD specifications (e.g., using non-Hispanic construction as the comparison).
   - **Heterogeneity**: The effect may vary by state (e.g., Arizona’s law is stricter than Louisiana’s). The leave-one-out robustness (Table 3) shows coefficients ranging from 0.009 to 0.060, suggesting instability. A more rigorous approach would estimate state-specific DDDs or use a stacked DiD to account for staggered adoption.

**2. Magnitudes Are Plausible but Need Context**
The DD estimates (0.033-point decline in hiring, 0.037 in separations) are economically meaningful (8–10% of pre-treatment means) but require validation:
   - **Mechanical Effects**: The paper does not address whether the declines reflect reduced hiring of undocumented workers (a compliance effect) or reduced mobility of documented Hispanics (a deterrence effect). The cross-sector spillover suggests the latter, but this should be tested directly (e.g., by interacting with local undocumented population shares).
   - **Dynamic Effects**: The paper treats the effect as static. A dynamic DiD (e.g., event-study plots) would show whether the freeze persists or attenuates over time. The manifest’s "smoke test" log hints at pre-trends (e.g., Georgia’s pre-2012 gaps), which should be formally tested.

**3. Standard Errors Are Appropriate but Inference is Fragile**
The paper uses state-clustered standard errors and wild cluster bootstrap (WCB), which is correct given the small number of treated states. However:
   - **DDD Inference**: The DDD’s null results are not subjected to WCB or permutation tests. Given the small number of treated states, the DDD’s standard errors may be unreliable. The paper should report WCB *p*-values for the DDD or use a randomization inference approach.
   - **Multiple Testing**: The paper tests 5 outcomes (hiring, separations, recalls, stability, earnings) across multiple specifications. A Bonferroni or false discovery rate adjustment would strengthen confidence in the results.

---

### 4. Suggestions

**A. Strengthen the DDD Interpretation**
1. **Alternative Comparison Groups**: Estimate the DDD using non-Hispanic construction as the comparison group (instead of Hispanic services). If the effect is truly ethnicity-wide, the DDD should remain null. If it becomes significant, the spillover interpretation is weakened.
2. **State-Specific DDDs**: Report state-by-state DDD estimates (e.g., in an appendix) to assess heterogeneity. The leave-one-out results suggest Georgia drives the effect—why? Is this due to firm-size thresholds (Georgia’s law phased in by employer size) or enforcement intensity?
3. **Event-Study Plots**: Replace the static DD with an event-study specification to show pre-trends and dynamic effects. The manifest’s "smoke test" log shows pre-2012 gaps for Georgia, which could bias the DD. Event studies would clarify whether the freeze is immediate or gradual.

**B. Validate the Mechanism**
1. **Earnings Test**: The manifest emphasizes that trapped workers should experience compressed new-hire wage premiums. The paper reports insignificant earnings effects (Table 1, Panel A) but does not discuss them. This is a missed opportunity. The paper should:
   - Test whether the new-hire wage premium (EarnHirNS - average earnings) declines for Hispanic workers post-E-Verify.
   - Decompose earnings effects by industry to see if construction workers (who face higher compliance costs) are more affected.
2. **Documentation Status**: The paper argues that the spillover reflects worker-side deterrence among *documented* Hispanics. This is testable:
   - Use ACS data to estimate the share of documented vs. undocumented Hispanics in each county-industry cell. Interact this with the DDD to see if effects are larger in high-undocumented-share areas.
   - Test whether the effect is larger in industries with higher E-Verify usage (e.g., construction vs. services) or in states with stricter enforcement (e.g., Arizona vs. Louisiana).
3. **Recall Rates**: The paper finds no effect on recalls (Table 1), which is consistent with the frozen labor market hypothesis. However, this could also reflect data limitations (recalls are a small share of hires). The paper should:
   - Report the share of hires that are recalls in the pre-period (Table 1 shows recalls are ~4% of employment for Hispanics).
   - Test whether the *composition* of hires shifts toward recalls post-E-Verify (e.g., by estimating a multinomial logit for hire type).

**C. Improve Robustness**
1. **Alternative Specifications**:
   - **Stacked DiD**: Use Callaway-Sant’Anna (2021) or Sun-Abbring (2021) to account for staggered adoption. The paper mentions Callaway-Sant’Anna in the manifest but does not implement it.
   - **Synthetic Controls**: Construct synthetic control groups for treated counties to address concerns about parallel trends.
2. **Placebo Tests**:
   - **False Treatment Dates**: Assign placebo treatment dates to control states and re-estimate the DD/DDD. The manifest’s "smoke test" log suggests pre-trends for Georgia—this should be formalized.
   - **Untreated Industries**: Test whether the effect spills over to other low-unauthorized-share industries (e.g., retail). If the spillover is truly ethnicity-wide, it should appear in all industries.
3. **Sample Restrictions**:
   - **Hispanic Employment Thresholds**: The paper restricts to counties with ≥50 Hispanic construction workers. Test sensitivity to this threshold (e.g., 25, 75, 100) and report results in an appendix.
   - **County-Level Trends**: Include county-specific linear trends to absorb unobserved heterogeneity. The manifest’s within-county ethnicity comparison should make this redundant, but it’s a useful robustness check.

**D. Clarify the Welfare Interpretation**
1. **Mobility vs. Employment**: The paper argues that the welfare cost is not captured in employment levels but in forgone mobility. This is compelling but needs quantification:
   - Estimate the implied wage loss from forgone job transitions using external estimates of the wage gain from mobility (e.g., 5–10% per transition, as cited in the paper). The manifest’s "smoke test" log suggests ~8,400 forgone transitions per year—this should be linked to dollar losses.
   - Compare the mobility cost to the employment cost (e.g., using estimates from Lubotsky et al. 2020). Is the mobility channel larger or smaller than the employment channel?
2. **Monopsony Connection**: The paper links the results to monopsony power, but this is underdeveloped. To strengthen this:
   - Test whether the effect is larger in labor markets with fewer employers (e.g., rural counties or industries with high concentration).
   - Estimate whether the freeze reduces wage growth for Hispanic workers (e.g., by regressing wage changes on job transitions pre- and post-E-Verify).

**E. Address Potential Confounds**
1. **Great Recession**: The 2008–2013 adoption period overlaps with the Great Recession and recovery. The paper includes quarter fixed effects, but the recession may have differentially affected Hispanic workers in construction vs. services. Test whether the effect persists in a post-2010 sample.
2. **Other Immigration Policies**: Some treated states (e.g., Arizona, Alabama) enacted other immigration policies (e.g., SB 1070) during the sample period. The paper should control for these or test whether the effect is larger in states with multiple policies.
3. **Industry-Specific Shocks**: The paper compares construction to services, but these industries may have experienced differential trends (e.g., housing recovery post-2012). Include industry-specific linear trends or use a more stable comparison industry (e.g., manufacturing).

**F. Presentation Improvements**
1. **Tables**:
   - **Table 1**: Add a column for the pre-treatment mean of recalls (currently missing). Also, report the share of hires that are recalls (HirR / (HirN + HirR)).
   - **Table 2**: Add a column for the DDD’s *Hispanic × Post* coefficient (β₂ in Equation 2) to show the ethnicity-wide effect directly.
   - **Table 3**: Add a column for the DD’s WCB *p*-values (currently only reported in the text).
2. **Figures**:
   - **Event-Study Plot**: Replace the static DD with a dynamic event-study plot showing pre-trends and post-treatment effects. This is critical given the staggered adoption and potential pre-trends.
   - **Map**: Show treated vs. control counties to visualize the geographic variation.
3. **Text**:
   - Clarify the distinction between *HirN* (new hires) and *HirR* (recalls) in the introduction. The manifest emphasizes this, but the paper’s abstract and introduction do not.
   - Discuss the earnings results (even if insignificant) to address the manifest’s hypothesis about wage premium compression.

---

### Final Assessment

The paper delivers a clear, economically meaningful result: E-Verify freezes Hispanic labor markets by reducing mobility, and this effect is ethnicity-wide, not industry-specific. The DDD null is a clever insight, but the paper overinterprets it without sufficient robustness checks. The magnitudes are plausible, but the mechanism needs validation (e.g., earnings tests, documentation status interactions). The standard errors are appropriate, but inference is fragile due to the small number of treated states.

**Recommendation**: Revise and resubmit with:
1. A dynamic event-study specification to address pre-trends.
2. Alternative DDD comparison groups (e.g., non-Hispanic construction).
3. Tests of the earnings and documentation status mechanisms.
4. More rigorous inference for the DDD (e.g., WCB or permutation tests).

The paper’s core contribution—reframing E-Verify as a mobility tax—is novel and important, but the current version leaves key questions unanswered.
