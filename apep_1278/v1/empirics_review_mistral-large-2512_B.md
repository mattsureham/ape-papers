# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-04-01T22:22:39.898236

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It exploits the staggered adoption (and cancellation) of VAT receipt lotteries across 10 EU member states to estimate their causal effect on VAT compliance gaps, using the Callaway & Sant’Anna (2021) estimator as proposed. The key elements of the identification strategy—staggered DiD, cancellation reversals as falsification tests, and the use of CASE/Eurostat data—are all faithfully implemented. The paper even improves upon the manifest by excluding Malta (an outlier due to early adoption) and incorporating a placebo test (income tax revenue). No critical elements of the original idea are missed.

---

### 2. Summary

This paper provides the first cross-country causal analysis of VAT receipt lotteries, exploiting staggered adoption across 10 EU member states (2013–2021) and three subsequent cancellations. Using the heterogeneity-robust Callaway–Sant’Anna estimator, it finds no detectable effect on VAT compliance gaps (ATT = 1.29 percentage points, 95% CI: [-1.21, 3.78]). The null is reinforced by cancellation reversals (gaps continued to fall post-cancellation) and a placebo test. The paper highlights how conventional TWFE estimators can produce misleading results under staggered adoption, contributing to both the tax compliance and DiD methodology literatures.

---

### 3. Essential Points

The authors must address **three critical issues** to strengthen the paper’s credibility:

1. **Parallel trends assumption**:
   - The pre-treatment summary statistics (Table 1) show that lottery adopters had *much* larger VAT gaps (23.0% vs. 8.0%) and lower GDP per capita than never-adopters. This raises concerns about differential trends.
   - The paper mentions an event-study specification in Section 4 but does not report it. **Include a formal event-study plot** (e.g., Figure 1) showing pre-trends for all cohorts, with never-treated countries as the reference. If pre-trends are not parallel, the DiD design is invalid. The cancellation reversals are suggestive but not a substitute for this test.

2. **Concurrent reforms**:
   - The discussion (Section 5) notes that EU-wide anti-evasion measures (e-invoicing, SAF-T, etc.) may confound the lottery effect. However, the paper does not attempt to control for these.
   - **Add a robustness check** that includes a time-varying control for the adoption of other anti-evasion policies (e.g., a dummy for e-invoicing mandates, sourced from EU reports or country legislation). If the null persists, it strengthens the claim that lotteries are ineffective.

3. **Statistical power**:
   - With only 26 countries (9 treated, 17 controls) and 442 country-years, the study may be underpowered to detect small effects. The wild cluster bootstrap CI ([-4.95, 0.55]) is wide, and the cancellation reversals (e.g., Poland’s 10.3pp drop post-cancellation) suggest large underlying trends.
   - **Clarify the minimal detectable effect (MDE)** given the sample size. If the MDE is larger than the effect sizes reported in single-country studies (e.g., Naritomi 2019’s 22% increase in reported revenue), the null may reflect low power rather than true ineffectiveness.

---

### 4. Suggestions

#### **Conceptual and Theoretical Improvements**
1. **Mechanism heterogeneity**:
   - The paper notes that baseline compliance and digital payment penetration may limit lottery effectiveness but does not test this empirically.
   - **Suggested analysis**:
     - Split the sample into high- vs. low-gap countries (e.g., median split) and estimate separate ATTs. Table SDE (Appendix) hints at heterogeneity (SDE = -0.60 for low-gap countries vs. -0.04 for high-gap), but this is not explored in the main text.
     - Interact the lottery treatment with pre-treatment digital payment penetration (e.g., % of transactions via card, from ECB or World Bank data) to test whether lotteries work better in cash-heavy economies.

2. **Prize size and design**:
   - The manifest mentions decomposing effects by prize size, but the paper treats all lotteries as homogeneous.
   - **Suggested analysis**:
     - Collect data on prize structures (e.g., annual prize value as % of GDP or VAT revenue) and test whether larger prizes yield larger effects. This could explain why single-country studies (e.g., São Paulo’s high-value prizes) find effects while the cross-country null holds.

3. **Tax morale and enforcement complementarities**:
   - The discussion speculates that lotteries may require enforcement follow-up (e.g., audits triggered by receipt data) but does not test this.
   - **Suggested analysis**:
     - Interact the lottery treatment with a measure of tax authority enforcement capacity (e.g., audit rates, from OECD or EU reports). If lotteries only work in high-enforcement environments, this could reconcile the cross-country null with single-country successes.

#### **Empirical and Robustness Improvements**
4. **Alternative estimators**:
   - The paper relies on Callaway–Sant’Anna (CS) as the gold standard but does not compare it to other modern DiD methods.
   - **Suggested analysis**:
     - Report results from **Borusyak et al. (2024)** (imputation-based DiD) and **de Chaisemartin & D’Haultfœuille (2020)** (DID_multiplegt) to assess sensitivity to estimator choice. If all methods agree on the null, it strengthens the conclusion.

5. **Dynamic effects**:
   - The paper aggregates ATTs across all post-treatment periods but does not explore whether effects grow or decay over time.
   - **Suggested analysis**:
     - Report **group-time ATTs** (e.g., Figure 2) to show how the effect evolves in the years after adoption. For example, do lotteries have a short-term "novelty effect" that fades (as in Poland’s 18-month experiment)?

6. **Measurement error in VAT gaps**:
   - The VAT gap is an *estimate* (from CASE/EC), not a directly observed outcome. Measurement error could attenuate treatment effects.
   - **Suggested analysis**:
     - Use **VAT revenue/GDP** (a directly observed outcome) as the primary specification and treat the VAT gap as a robustness check. If the null holds for both, it mitigates concerns about measurement error.

7. **Placebo tests**:
   - The income tax placebo test is a strength, but it could be expanded.
   - **Suggested analysis**:
     - Test for effects on **corporate tax revenue** (another non-VAT outcome) and **excise tax revenue** (a VAT-adjacent outcome that might respond to reduced cash transactions).
     - Conduct a **synthetic control placebo test** (e.g., for Malta, the always-treated country) to check for spurious effects.

#### **Presentation and Clarity**
8. **Event-study plot**:
   - As noted in Essential Points, the paper must include an **event-study plot** (e.g., Figure 1) showing pre- and post-treatment trends for all cohorts. This is critical for assessing parallel trends and dynamic effects.

9. **Table formatting**:
   - Table 1 (summary statistics) should include **p-values for differences** between adopters and non-adopters (e.g., t-test for VAT gap difference).
   - Table 2 (main results) should report **wild cluster bootstrap CIs** alongside analytical SEs for the CS estimator.

10. **Discussion of external validity**:
    - The paper contrasts its null with single-country studies (Naritomi 2019, Wan 2010) but does not discuss why the mechanism might differ across contexts.
    - **Suggested addition**:
      - Compare the **informal sector size** (from ILO or Schneider’s shadow economy estimates) and **enforcement capacity** (e.g., audit rates) between the EU and Brazil/China. If the EU has smaller informal sectors and stronger enforcement, lotteries may be redundant.

11. **Policy implications**:
    - The conclusion states that "the better bet is mandatory digital reporting infrastructure," but the paper does not test this.
    - **Suggested addition**:
      - Include a **brief analysis** of e-invoicing mandates (e.g., Italy 2019) using the same DiD framework to compare their effect sizes to lotteries. This would provide direct evidence for the policy recommendation.

#### **Minor Suggestions**
12. **Data transparency**:
    - The paper cites Eurostat and CASE data but does not provide a **replication package**. Include a GitHub repository with:
      - Cleaned data (VAT gaps, revenue, treatment dummies).
      - Code for all analyses (CS estimator, TWFE, robustness checks).
      - A README explaining data sources and variable definitions.

13. **Literature review**:
    - The introduction cites Gordon (1990) and Naritomi (2019) but omits recent work on **third-party reporting** (e.g., Kleven et al. 2011, Pomeranz 2015) and **behavioral responses to lotteries** (e.g., Hallsworth et al. 2017 on tax morale).
    - **Suggested addition**:
      - Briefly discuss how receipt lotteries fit into the broader literature on **audit mechanisms** (e.g., random audits vs. third-party reporting) and **behavioral nudges** (e.g., social norms, moral suasion).

14. **Terminology**:
    - The paper uses "VAT gap" and "VAT compliance gap" interchangeably. **Standardize terminology** (e.g., always use "VAT gap" to match EC/CASE reports).

15. **Appendix content**:
    - The appendix includes a **standardized effect size table** (Table SDE), which is useful but could be expanded.
    - **Suggested additions**:
      - Report **effect sizes by cohort** (e.g., Slovakia vs. Italy) to show heterogeneity.
      - Include a **power analysis** (e.g., using the `powerDD` R package) to quantify the MDE.

---

### **Final Assessment**
This is a **strong and novel paper** that makes a valuable contribution to the tax compliance literature. The cross-country design, use of modern DiD methods, and cancellation reversals are all strengths. However, the **parallel trends assumption** and **concurrent reforms** are critical threats that must be addressed before publication. With the suggested improvements—particularly the event-study plot, robustness checks for concurrent reforms, and power analysis—the paper would be a compelling addition to *AER: Insights*. As it stands, it is **revise-and-resubmit**.
