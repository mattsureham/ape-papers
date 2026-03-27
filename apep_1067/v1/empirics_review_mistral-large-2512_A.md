# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-27T13:37:32.044754

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest, pursuing the core research question of strategic manipulation of bridge sufficiency ratings (SR) at the federal funding threshold of 50. The identification strategy—bunching estimation at SR=50 with MAP-21 as a natural experiment—is faithfully implemented, and the key elements of the manifest (data source, heterogeneity analysis, placebo tests) are all present. The paper even exceeds the manifest’s scope by adding robustness checks (polynomial order sensitivity) and a standardized effect size table.

Two minor deviations:
- The manifest proposed cross-sectional heterogeneity by *federal funding dependency* (share of bridge funding from federal sources), but the paper instead uses *owner type* (state DOT vs. local/federal). This is a defensible simplification but should be justified.
- The manifest’s "smoke test" log (showing raw bunching ratios for 13 states) is not replicated in the paper, though the results are directionally consistent.

### 2. Summary

This paper provides compelling evidence that U.S. states strategically manipulated bridge sufficiency ratings to qualify for federal replacement funding under the Highway Bridge Program (HBP). Using bunching estimation on the universe of 620,000+ bridges (2000–2018), the authors document a sharp discontinuity at the SR=50 funding threshold, which attenuates after MAP-21 (2012) eliminated the sufficiency-based formula. The results are robust to placebo tests, owner heterogeneity, and alternative specifications, offering a clear case of Goodhart’s Law in infrastructure policy.

### 3. Essential Points

**1. Clarify the counterfactual and manipulation region.**
   - The paper excludes SR bins [46, 53] to estimate the counterfactual density, but this range is *ad hoc*. The manifest’s preliminary evidence (e.g., a 37.7% drop from SR=49 to 50) suggests the manipulation region might be narrower (e.g., [48, 51]). The authors should:
     - Justify the [46, 53] window (e.g., show that results are insensitive to ±1 bin).
     - Report results for alternative windows (e.g., [48, 51], [45, 54]) in an appendix.
   - The polynomial order (7) is also arbitrary. While Table 5 shows robustness, the authors should explain why order 7 is the baseline (e.g., AIC/BIC comparison or visual fit).

**2. Address potential mechanical explanations for the discontinuity.**
   - The paper argues that the SR formula’s subjectivity creates scope for manipulation, but the discontinuity could also arise from:
     - **Rating formula nonlinearities**: The SR formula (55% structural adequacy + 30% serviceability + 15% essentiality) might mechanically produce bunching at 50 if, for example, the structural adequacy component is discrete (e.g., 0–9 scale). The authors should:
       - Simulate the SR distribution under random draws of the underlying components to test whether the observed discontinuity could emerge mechanically.
       - Show that the discontinuity is absent in the *component* ratings (e.g., deck/superstructure/substructure) to rule out mechanical bunching.
     - **Inspection rounding**: If inspectors round ratings to the nearest integer, bridges with "true" SR=49.5–50.4 might cluster at 50. The authors should:
       - Test for bunching at other integer thresholds (e.g., SR=60, 70) where rounding could also occur. The placebo tests in Table 5 are reassuring but do not fully address this.
       - Exploit the fact that SR is reported to one decimal place in the raw data (though binned for analysis). If rounding drives the discontinuity, the raw data should show no bunching at 50.0.

**3. Strengthen the MAP-21 natural experiment.**
   - The paper treats MAP-21 as an exogenous shock, but the reform’s timing might correlate with other changes affecting bridge ratings (e.g., fiscal stress post-2008, changes in inspection protocols). The authors should:
     - Show event-study plots of bunching intensity (e.g., annual $\hat{b}$ estimates) to confirm that the attenuation is abrupt in 2013 and not part of a pre-existing trend.
     - Test for differential trends in bunching by states’ pre-MAP-21 HBP dependency (as proposed in the manifest). If MAP-21’s effect is causal, states more reliant on HBP funds should show larger declines in bunching.
     - Address whether MAP-21’s shift to deck-area-based funding created *new* incentives for manipulation (e.g., inflating deck area ratings). If so, the post-2012 results might understate the true attenuation.

### 4. Suggestions

**A. Data and Measurement**
1. **Leverage the panel structure**: The paper pools all years but could exploit within-bridge variation. For example:
   - Estimate a bridge-level fixed-effects model of SR as a function of time-to-MAP-21, controlling for bridge age and traffic.
   - Test whether bridges rated just above 50 pre-MAP-21 were more likely to be "pushed" below 50 than those rated farther above.
2. **Exploit subjective components**: The SR formula’s serviceability (30%) and essentiality (15%) components are subjective. The authors could:
   - Test whether bunching is stronger for bridges where these components are more influential (e.g., low structural adequacy scores, where serviceability/essentiality determine SR).
   - Compare bunching for bridges with vs. without "special reductions" (which are also subjective).
3. **Address missing SR data**: The paper drops bridges with missing SR (Table 1 notes 11.5M observations from 780K bridges). Missingness could be non-random (e.g., states skipping inspections for low-SR bridges). The authors should:
   - Test whether missingness is correlated with pre-MAP-21 bunching intensity.
   - Report the share of missing SR by year/state to rule out compositional changes.

**B. Heterogeneity and Mechanisms**
1. **Federal funding dependency**: The manifest proposed testing whether states more reliant on HBP funds show more bunching. The paper could:
   - Merge state-level HBP apportionment data (available from FHWA) and interact pre-MAP-21 bunching with federal funding share.
   - Test whether states with tighter fiscal constraints (e.g., lower own-source revenue) bunch more.
2. **Political economy**: The authors could explore whether bunching varies with:
   - State political alignment (e.g., governors’ parties, congressional delegation ideology).
   - State DOT capacity (e.g., inspection staff per bridge).
3. **Bridge characteristics**: The paper shows owner heterogeneity but could also test:
   - Traffic volume: High-traffic bridges might be less manipulated (higher political cost of misrating).
   - Bridge age: Older bridges might be more likely to be "pushed" below 50.
   - Urban/rural: Rural bridges might be more manipulated (lower scrutiny).

**C. Robustness and Placebo Tests**
1. **Alternative counterfactuals**: The paper uses a 7th-order polynomial, but other approaches could be tried:
   - Local linear regression (as in McCrary 2008) for the counterfactual.
   - Spline-based counterfactuals (e.g., cubic splines with knots at 10, 20, ..., 90).
2. **Dynamic effects**: The paper pools 2013–2018 as "post-MAP-21," but the incentive change might have taken time to diffuse. The authors could:
   - Estimate bunching annually to show the time path of attenuation.
   - Test whether bunching declined more in states that adopted NHPP rules earlier.
3. **Placebo reforms**: The authors could test for bunching at SR=50 in:
   - States with no HBP funding (e.g., low-bridge states).
   - Years before HBP was established (1978) to confirm the discontinuity is not mechanical.

**D. Policy Implications**
1. **Cost of manipulation**: The paper estimates excess bridges below 50 but could quantify the fiscal cost:
   - Multiply excess bridges by the average HBP apportionment per bridge to estimate misallocated funds.
   - Compare this to the cost of alternative funding formulas (e.g., deck-area-based).
2. **Design lessons**: The authors could discuss how to design formula-based transfers to minimize gaming:
   - Avoid sharp thresholds (e.g., use continuous formulas like NHPP).
   - Use objective metrics (e.g., structural condition ratings) rather than composite scores.
   - Randomize audits of subjective ratings (as in tax enforcement).
3. **External validity**: The paper could speculate on whether similar manipulation occurs in:
   - Other infrastructure programs (e.g., airports, dams, transit).
   - Other countries with condition-based funding (e.g., EU cohesion funds).

**E. Presentation and Clarity**
1. **Visuals**: The paper lacks figures, which would strengthen the argument. Suggested additions:
   - A histogram of SR distribution (2000–2018) with the counterfactual overlaid (as in Kleven 2016).
   - Event-study plot of annual $\hat{b}$ estimates (pre/post MAP-21).
   - State-level maps of bunching intensity (pre/post MAP-21).
2. **Standardized effect sizes**: Table 6 is useful but could be expanded:
   - Report SDEs for the diff-in-bunching estimates (pre/post MAP-21).
   - Compare SDEs to other bunching studies (e.g., tax evasion, school report cards).
3. **Terminology**: The paper uses "manipulation" and "gaming" interchangeably. The authors should:
   - Define these terms explicitly (e.g., "manipulation" = intentional misrating; "gaming" = exploiting formula rules).
   - Acknowledge that some "manipulation" could reflect benign rounding or inspector discretion.

**F. Minor Suggestions**
1. **Abstract**: The abstract could better highlight the natural experiment (MAP-21) and the magnitude of the effect (e.g., "bunching declined by X% after MAP-21").
2. **Institutional background**: The paper could clarify:
   - Whether states receive lump-sum HBP funds or reimbursements for specific bridges.
   - How HBP funds are allocated within states (e.g., do state DOTs prioritize bridges near 50?).
3. **Literature**: The paper could engage more with the infrastructure economics literature, e.g.:
   - \citet{aschauer1989public} on infrastructure investment.
   - \citet{duflo2012infrastructure} on corruption in infrastructure.
   - \citet{humphreys2015infrastructure} on political economy of infrastructure.

### Final Assessment

This is a strong paper with a credible identification strategy, novel data, and clear policy implications. The core results (bunching at SR=50, attenuation post-MAP-21, owner heterogeneity) are convincing, but the authors must address the mechanical explanations and strengthen the MAP-21 natural experiment. With these revisions, the paper would make a significant contribution to the literatures on intergovernmental transfers, infrastructure investment, and strategic behavior. **Revise and resubmit.**
