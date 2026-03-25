# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-03-25T20:42:08.778608

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It exploits the staggered adoption of tobacco billboard advertising bans across Swiss cantons (1997–2017) to estimate causal effects on per-capita healthcare costs, using the FOPH OKP Dashboard as specified. The identification strategy—staggered difference-in-differences (DiD) with Callaway and Sant’Anna (2021) and never-treated cantons as controls—matches the manifest’s plan. The built-in placebo test (non-smoking-related cost categories) and event-study design are faithfully implemented. The paper even extends the original idea by decomposing effects by cost category and exploring heterogeneity across early/late adopters. No key elements of the identification strategy, data source, or research question are missed.

---

### 2. Summary

This paper provides the first causal estimate of the fiscal consequences of tobacco advertising bans, exploiting staggered cantonal billboard bans in Switzerland (1997–2017). Using administrative healthcare cost data, it finds that bans reduce per-capita costs by 5.4%, driven by hospital expenditures (13.3% decline in inpatient costs). Effects grow over time, consistent with the health-stock mechanism, and placebo tests (non-smoking-related costs) support the identification. The paper contributes novel evidence to the literature on tobacco regulation and fiscal returns to public health policies.

---

### 3. Essential Points

The authors must address **three critical issues** to strengthen the paper’s credibility:

1. **Policy Bundling and Confounding Cantonal Shocks**
   The paper acknowledges that cantons adopting billboard bans may also implement other tobacco control policies (e.g., smoke-free laws, sales restrictions). However, it does not adequately rule out that these co-treatments drive the results. The authors should:
   - Provide a table or appendix listing other tobacco control policies by canton and year, and test whether their adoption correlates with billboard bans.
   - Re-estimate the main results controlling for these policies (if data permits) or argue why they are unlikely to confound the results (e.g., timing mismatches, different mechanisms).

2. **Inference with Few Clusters**
   With only 26 cantons (16 treated, 10 controls), standard cluster-robust inference is unreliable. The wild cluster bootstrap *p*-value (0.16) suggests the main result is not statistically significant at conventional levels. The authors should:
   - Emphasize that the results are *suggestive* rather than definitive, and interpret them alongside the pattern evidence (event study, placebo tests).
   - Report alternative inference methods (e.g., randomization inference, Fisher sharp null tests) to assess robustness.

3. **Mechanism and Smoking Prevalence Data**
   The paper relies on the health-stock mechanism (reduced smoking → lower disease incidence → lower costs) but does not directly link the bans to smoking prevalence. The authors should:
   - Incorporate smoking prevalence data from Stoller (2026) as a mediator. Show that billboard bans reduce smoking prevalence *and* that prevalence reductions predict cost declines.
   - Test whether the cost effects are attenuated when controlling for smoking prevalence (if data permits).

---

### 4. Suggestions

#### **Conceptual and Methodological Improvements**
1. **Clarify the Policy’s Scope and External Validity**
   - The paper notes that billboard bans target only outdoor advertising, but the abstract and introduction imply broader implications. Clarify that the results apply to *billboard* bans specifically, not comprehensive advertising restrictions.
   - Discuss whether the Swiss context (high healthcare costs, universal insurance) limits generalizability to other countries.

2. **Strengthen the Placebo Test**
   - The placebo categories (physiotherapy, SPITEX) show some marginally significant effects, which could reflect indirect health improvements (e.g., reduced smoking → better respiratory function → less physiotherapy). The authors should:
     - Acknowledge this ambiguity and discuss whether it undermines the placebo test.
     - Consider alternative placebo outcomes (e.g., non-smoking-related hospitalizations like appendicitis or trauma).

3. **Improve Event-Study Interpretation**
   - The event study shows growing effects over time, but the pre-trends are noisy. The authors should:
     - Plot the event study with confidence intervals to visually assess pre-trend parallelism.
     - Test for joint significance of pre-trends (e.g., *F*-test for coefficients from *t* = −10 to *t* = −1).

4. **Address Heterogeneity More Rigorously**
   - The paper finds larger effects for early adopters but does not explore why. The authors should:
     - Test whether early adopters had higher baseline smoking prevalence or healthcare costs.
     - Discuss whether early adopters’ bans were stricter or better enforced.

5. **Quantify the Fiscal Impact**
   - The CHF 79 per-capita savings is modest, but the paper could contextualize it better:
     - Aggregate the savings across Switzerland’s 8.7 million insured (CHF 690 million annually).
     - Compare the savings to the cost of implementing/enforcing the bans (if data exists).

#### **Data and Robustness**
6. **Report Alternative Specifications**
   - The paper focuses on Callaway and Sant’Anna (2021) but should also report:
     - Sun and Abraham (2021) interaction-weighted estimates for all outcomes.
     - A dynamic TWFE specification (e.g., de Chaisemartin and D’Haultfœuille 2020) to compare with CS-DiD.

7. **Explore Alternative Control Groups**
   - The paper uses never-treated cantons as controls, but some may be "future-treated." The authors should:
     - Re-estimate using only cantons that never adopt bans (10 cantons) as controls.
     - Compare results to a specification using all cantons as controls (including future-treated).

8. **Address Potential Spillovers**
   - Billboard bans in one canton might affect neighboring cantons (e.g., reduced cross-border advertising exposure). The authors should:
   - Test for spillovers by including a "share of neighboring cantons with bans" variable.
   - Discuss whether spillovers could bias the estimates.

#### **Presentation and Clarity**
9. **Improve Table and Figure Readability**
   - **Table 1 (Summary Statistics):** Add a column for the *difference* between treated and control cantons in the pre-period to highlight the level gap.
   - **Table 2 (Main Results):** Add a column with wild cluster bootstrap *p*-values for all specifications.
   - **Event Study:** Plot the dynamic effects with 95% confidence intervals (not just point estimates).

10. **Clarify the Role of Geneva**
    - Geneva (treated in 1997) is dropped from the CS-DiD analysis due to no pre-period. The authors should:
      - Report results including Geneva (e.g., using a synthetic control or alternative estimator).
      - Discuss whether its exclusion affects the results.

11. **Discuss Potential Bias from Urbanization**
    - Treated cantons are more urban, and urbanization may correlate with healthcare costs. The authors should:
      - Control for urbanization (e.g., population density) in robustness checks.
      - Discuss whether urban cantons’ higher costs reflect unobserved confounders.

12. **Expand the Literature Review**
    - The paper cites Saffer (2000) and Blecher (2008) but could better situate itself in the literature on:
      - Advertising bans and health outcomes (e.g., Wakefield et al. 2008 on youth smoking).
      - Fiscal returns to public health policies (e.g., Cawley and Ruhm 2011 on obesity).

#### **Minor Suggestions**
13. **Clarify the "Health-Stock Mechanism"**
    - The paper repeatedly invokes the health-stock mechanism but does not define it clearly. Add a sentence explaining that smoking-related diseases (e.g., cancer, COPD) develop over decades, so cost reductions emerge gradually.

14. **Report Effect Sizes in Levels and Logs**
    - The paper reports log effects (5.4%) but also mentions CHF 79. Clarify whether the 5.4% is relative to the treated cantons’ mean or the full sample mean.

15. **Discuss Data Limitations**
    - The FOPH OKP data are gross costs, not net of premiums or subsidies. The authors should:
      - Acknowledge that the fiscal savings may not directly translate to lower premiums.
      - Discuss whether the data capture all healthcare costs (e.g., private insurance, out-of-pocket).

16. **Improve the Abstract**
    - The abstract is strong but could better highlight the key innovation: "first causal estimate of the fiscal return to tobacco advertising regulation."

---

### **Overall Assessment**
This is a well-executed paper with a compelling research design and novel findings. The identification strategy is credible, and the empirical approach aligns with the research question. With the suggested improvements—particularly addressing policy bundling, inference with few clusters, and the mechanism—it could make a strong contribution to the literature. The authors should revise the paper to emphasize the *pattern* of evidence (event study, placebo tests) over the aggregate *p*-value, given the inference limitations. **Recommendation: Revise and Resubmit.**
