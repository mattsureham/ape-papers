# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-13T17:29:16.686004

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It pursues the core research question—whether state opioid day-supply limits reduced prescription opioid deaths but increased illicit opioid deaths through substitution—using the specified identification strategy (Callaway-Sant’Anna staggered DiD), data source (CDC NVSS drug-specific overdose mortality), and key outcomes (prescription opioids, heroin, fentanyl, cocaine, and psychostimulants as placebos). The paper also incorporates the proposed dose-response analysis (3-day vs. 5-day vs. 7-day limits) and welfare calculation (net lives saved/lost).

No critical elements of the manifest are missing. The paper even exceeds the manifest’s ambition by including robustness checks (Sun-Abraham estimator, leave-one-out analysis) and a nuanced discussion of the "Goldilocks problem" in policy stringency. The only minor deviation is the inclusion of 40 treated states (vs. 39 in the manifest), likely due to updated coding of state laws.

---

### 2. Summary

This paper examines the causal effect of state opioid day-supply limits (3–7 days) on drug-type-specific overdose deaths using a staggered DiD design. While the aggregate effect on total overdose deaths is null, the results reveal a stark dose-response: states with the strictest 3-day limits experienced a significant increase in synthetic opioid (fentanyl) deaths (+8.6 per 100,000) and a reduction in prescription opioid deaths (−1.0 per 100,000), while 7-day limits had no detectable substitution effect. Placebo outcomes (cocaine, psychostimulant deaths) show no treatment effect, supporting the substitution mechanism. The findings suggest that overly aggressive limits may accelerate the transition to illicit markets, while moderate limits reduce prescribing without harm.

---

### 3. Essential Points

**1. Parallel trends assumption for synthetic opioids requires stronger justification.**
The event study in Table 5 shows pre-trend coefficients for synthetic opioids that are noisy and occasionally large in magnitude (e.g., −5.06 at *k* = −2). While none are statistically significant, the synthetic opioid market was undergoing rapid national expansion during this period (2015–2019), and differential trends in fentanyl penetration across states could confound the results. The authors should:
   - Report pre-trend tests for *each dose group* (3-day, 5-day, 7-day) separately, as the 3-day states (FL, TN, KY) are in regions with historically high opioid use and may have had faster fentanyl growth regardless of policy.
   - Include a falsification test using *pre-treatment* synthetic opioid deaths as an outcome (e.g., 2010–2015) to rule out differential trends.

**2. The dose-response analysis lacks a clear counterfactual.**
The paper’s central claim—that 3-day limits caused substitution while 7-day limits did not—relies on comparing treated states to never-treated states. However, the 3-day states are not randomly assigned; they are Southern/Appalachian states with distinct pre-existing trends. The authors should:
   - Test whether the 3-day states had systematically different pre-trends in *prescription opioid deaths* (the intended target of the policy). If these states were already reducing prescribing faster than others, the observed effects may reflect continuation of prior trends.
   - Consider a triple-difference design, interacting treatment with a measure of pre-policy fentanyl prevalence (e.g., synthetic opioid death rates in 2015) to test whether substitution effects are stronger in states where illicit markets were already active.

**3. The welfare calculation is incomplete.**
The paper concludes that 3-day limits caused a net increase in mortality (8.6 synthetic deaths vs. 1.0 prescription deaths avoided), but this ignores:
   - **Non-fatal harms**: Prescription opioids may cause dependence, chronic pain, or other morbidity that is not captured in mortality data. The welfare calculation should acknowledge this trade-off.
   - **Heterogeneity in substitution risks**: The 3-day states may have had more active illicit markets or higher baseline dependence rates. The authors should discuss whether the net harm is generalizable or specific to these states.
   - **Dynamic effects**: The analysis covers only 1–4 years post-treatment. If substitution effects fade over time (e.g., as users adapt), the long-run welfare implications may differ.

---

### 4. Suggestions

#### **Conceptual and Theoretical Improvements**
1. **Clarify the substitution mechanism.**
   The paper assumes that day-supply limits push users from prescription opioids to fentanyl, but the mechanism is underspecified. Possible refinements:
   - Distinguish between *diversion* (leftover pills sold on illicit markets) and *patient-level substitution* (dependent users seeking illicit opioids). The former should reduce prescription deaths without increasing illicit deaths, while the latter should show the opposite. The dose-response pattern suggests patient-level substitution dominates for 3-day limits.
   - Cite qualitative evidence (e.g., Cicero et al. 2015 on patient transitions) to support the claim that 3-day limits create a "supply gap" that 7-day limits do not.

2. **Address alternative explanations for the dose-response.**
   The paper attributes the dose-response to policy stringency, but other explanations are possible:
   - **Implementation differences**: 3-day states may have enforced limits more aggressively (e.g., via audits or penalties). The authors should discuss whether enforcement data are available.
   - **Pre-existing prescribing norms**: 3-day states may have had lower baseline prescribing rates, making the limits more binding. Include a table comparing pre-treatment prescription opioid death rates across dose groups.
   - **Illicit market maturity**: 3-day states may have had more developed fentanyl markets. Test this by interacting treatment with pre-policy heroin death rates (a proxy for illicit market activity).

3. **Expand the welfare discussion.**
   The paper’s welfare calculation is a useful starting point but could be enriched by:
   - **Sensitivity analysis**: Vary the assumed "value" of a prescription opioid death (e.g., if prescription deaths are less likely to involve fentanyl contamination, they may be less harmful per death).
   - **Cost-benefit framing**: Compare the mortality effects to the policy’s benefits (e.g., reduced opioid prescribing, fewer new addictions). Cite estimates of the social cost of opioid use disorder (e.g., Florence et al. 2021) to contextualize the trade-offs.
   - **Heterogeneity**: Discuss whether the net harm of 3-day limits is concentrated in certain populations (e.g., chronic pain patients vs. recreational users).

#### **Empirical and Robustness Improvements**
4. **Improve the event study presentation.**
   - The current event study (Table 5) aggregates all treated states, masking heterogeneity. Split the event study by dose group (3-day, 5-day, 7-day) to show whether pre-trends differ.
   - Add a figure plotting the event study coefficients with 95% confidence intervals for the three key outcomes (prescription opioids, synthetic opioids, total overdose). This would make the pre-trend tests more intuitive.

5. **Address compositional effects in the Callaway-Sant’Anna estimator.**
   The synthetic opioid ATT in Table 2 is large and negative (−6.01), but this is driven by the estimator’s aggregation method. The authors should:
   - Report the *median* group-time ATT for synthetic opioids to show whether the negative effect is widespread or driven by outliers.
   - Compare the CS results to the Sun-Abraham estimator, which is less sensitive to compositional effects.

6. **Test for spillovers to neighboring states.**
   If day-supply limits push users to illicit markets, they may also increase overdose deaths in nearby states (e.g., via drug trafficking). The authors could:
   - Estimate a spillover effect by including a weighted average of neighboring states’ treatment status as a control.
   - Test whether never-treated states bordering 3-day states experienced faster fentanyl growth.

7. **Clarify the placebo outcome results.**
   The cocaine death ATT in Table 2 is negative and significant (−4.59, *p* < 0.05), which is puzzling given that cocaine is a placebo. The authors should:
   - Investigate whether this is driven by a specific state or year (e.g., a cocaine overdose spike in a never-treated state).
   - Report the cocaine ATT separately for each dose group to check for heterogeneity.

8. **Improve the standardized effect size table.**
   Table A1 is useful but could be more informative:
   - Add a column for the *minimum detectable effect* (MDE) for each outcome, given the sample size and variance.
   - Group outcomes by hypothesized effect (prescription opioids, illicit opioids, placebos) to highlight the substitution pattern.
   - Discuss whether the effect sizes are large relative to other opioid policies (e.g., PDMPs, naloxone access laws).

#### **Data and Measurement Improvements**
9. **Address potential misclassification in overdose deaths.**
   The CDC data rely on death certificates, which may misclassify drug types (e.g., fentanyl deaths miscoded as heroin). The authors should:
   - Cite validation studies of the CDC data (e.g., Ruhm 2019) to assess the likely magnitude of misclassification.
   - Test robustness to using *any opioid* deaths (T40.0–T40.4) as an outcome, which may be less prone to misclassification.

10. **Explore county-level variation.**
    State-level data may mask important heterogeneity. The authors could:
    - Replicate the main results using county-level overdose data (available from CDC WONDER) to increase power and test for within-state variation.
    - Test whether effects are stronger in urban counties (where illicit markets are more active) or rural counties (where prescribing rates are higher).

11. **Include additional controls for concurrent policies.**
    Many states adopted multiple opioid policies during this period (e.g., PDMPs, naloxone access laws). The authors should:
    - Add controls for other policies (e.g., PDMP adoption, naloxone standing orders) to rule out confounding.
    - Test whether the dose-response persists when controlling for these policies.

#### **Policy Implications**
12. **Discuss generalizability to other contexts.**
    The paper’s findings are specific to U.S. states in 2016–2019. The authors should discuss:
    - Whether the results apply to other countries (e.g., Canada, where fentanyl markets are also active).
    - Whether the dose-response would hold for other prescription limits (e.g., morphine milligram equivalents, MMEs).
    - How the rise of xylazine (a fentanyl adulterant) might alter the substitution dynamics.

13. **Propose alternative policy designs.**
    The paper concludes that 7-day limits are "just right," but this may not be the only solution. The authors could suggest:
    - **Tiered limits**: Stricter limits for high-risk patients (e.g., those with prior opioid use disorder) and looser limits for low-risk patients.
    - **Tapering support**: Pairing limits with mandatory referrals to addiction treatment or pain management clinics.
    - **Safe supply programs**: Discuss whether providing pharmaceutical-grade opioids to dependent users could mitigate substitution risks.

14. **Acknowledge limitations of the "Goldilocks" framing.**
    The paper’s conclusion—that 7-day limits are optimal—relies on the assumption that the null effect for 7-day states reflects no substitution. However, it could also reflect:
    - **Type II error**: The sample may lack power to detect small substitution effects for 7-day states.
    - **Delayed substitution**: Substitution may occur gradually, and the 1–4 year follow-up may be too short to detect it.
    The authors should discuss these possibilities and suggest avenues for longer-term research.

---

### **Final Assessment**
This is a strong paper that makes a novel and policy-relevant contribution. The core finding—that the effect of day-supply limits depends on their stringency—is compelling and well-supported by the data. The authors have anticipated many potential critiques (e.g., parallel trends, placebo outcomes) and addressed them thoughtfully. With the revisions suggested above—particularly around parallel trends for synthetic opioids, the dose-response counterfactual, and the welfare calculation—the paper would be suitable for publication in *AER: Insights*.

The most critical issue is the parallel trends assumption for synthetic opioids, which is not fully convincing in the current draft. If the authors can demonstrate that the 3-day states did not have systematically different pre-trends in fentanyl deaths, the paper’s causal claims would be significantly strengthened. The other essential points (dose-response counterfactual, welfare calculation) are important but less likely to overturn the main results. The suggestions section provides actionable ways to improve the paper’s clarity, robustness, and policy relevance.
