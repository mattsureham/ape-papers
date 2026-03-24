# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-13T16:13:05.438808

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It successfully implements the proposed **Callaway-Sant’Anna difference-in-differences (CS-DiD)** design to exploit staggered recreational marijuana legalization across 20 U.S. states (2014–2023) and tests whether earmarked revenue increases education spending or crowds out general-fund appropriations. Key elements from the manifest are preserved:
- **Data sources**: Census Annual Survey of School System Finances (2008–2022) and marijuana tax revenue from the Tax Foundation/state sources.
- **Identification strategy**: CS-DiD with never-treated controls, pre-trend tests, and falsification tests (federal revenue placebo, local property tax, non-education spending).
- **Heterogeneity analysis**: Comparison of earmark vs. non-earmark states, with a focus on the "passthrough ratio" (spending increase per earmarked dollar).
- **Novelty**: First causal study of marijuana revenue fungibility, leveraging staggered adoption for cleaner identification than prior lottery studies.

**Minor deviations**:
- The manifest proposed 24 treated states, but the paper uses 20 (likely due to data availability for 2023 legalizations).
- The manifest mentioned a "welfare test" (fungibility rate vs. Evans & Zhang’s 50–70 cents benchmark), which is addressed but not formally tested against the benchmark.

---

### 2. Summary

This paper provides the first causal evidence on whether earmarked marijuana tax revenue increases education spending or is offset by general-fund cuts. Using staggered legalization across 20 U.S. states and Census school finance data, it finds that:
1. **Earmarking matters**: States earmarking marijuana revenue for education show a significant **$1,175 per-pupil increase** in total spending (vs. $416 in non-earmark states).
2. **Fungibility is incomplete but puzzling**: The spending increase exceeds marijuana revenue by a factor of **5**, suggesting earmarks may act as political signals rather than fiscal constraints.
3. **Robustness**: Results hold after excluding outliers (Alaska) and COVID years, with clean federal revenue placebos.

The paper contributes to the literature on fiscal fungibility, earmarking, and marijuana policy, offering a novel mechanism: earmarks as political commitment devices.

---

### 3. Essential Points

**Three critical issues must be addressed**:

1. **Parallel trends assumption and Alaska’s influence**:
   - The baseline ATT ($716, SE = $806) is insignificant, but excluding Alaska yields a large, significant effect ($1,346, SE = $341). Alaska is a **singleton cohort** (2016 legalization) with extreme per-pupil spending ($23K vs. national average $14K) and an oil-driven fiscal crisis coinciding with legalization. This raises concerns about:
     - **Violation of parallel trends**: Alaska’s pre-trends may not reflect counterfactual spending in other states.
     - **Generalizability**: Results are sensitive to a single outlier, undermining causal claims.
   - **Fix**: Drop Alaska entirely (as in robustness checks) and justify this choice in the main specification. Alternatively, use **synthetic control methods** for singleton cohorts or **leave-one-out jackknife** to assess sensitivity.

2. **Passthrough ratio > 1: Plausibility and mechanisms**:
   - The $1,175 per-pupil increase in earmark states vs. $227 in marijuana revenue implies a **passthrough ratio of 5.2**, which contradicts standard fungibility theory (max = 1). The paper offers three explanations:
     1. **Fiscal spillovers** (e.g., reduced criminal justice costs).
     2. **Political signaling** (earmarks legitimize broader spending).
     3. **Confounding** (correlated economic growth in early-legalizing states).
   - **Problem**: The paper does not empirically distinguish these mechanisms. Without testing them, the passthrough ratio is hard to interpret.
   - **Fix**:
     - **Test spillovers**: Include controls for criminal justice spending (e.g., state corrections budgets) or other tax revenue (e.g., sales/income tax growth).
     - **Test political signaling**: Use legislative voting records or media coverage to measure salience of earmark promises.
     - **Test confounding**: Compare pre-trends in earmark vs. non-earmark states to assess whether early legalizers were already on faster spending growth trajectories.

3. **Heterogeneity analysis power**:
   - The earmark/non-earmark comparison relies on **7 vs. 13 treated states**, respectively. With so few units, the difference ($759) is suggestive but not statistically significant (no SE reported).
   - **Problem**: The paper claims earmarking "matters" but lacks power to confirm this.
   - **Fix**:
     - **Pool earmark states**: Combine earmark states into a single group and test for a **dose-response relationship** (e.g., % of revenue earmarked vs. spending increase).
     - **Use continuous treatment**: Model earmarking as a continuous variable (e.g., % of marijuana revenue earmarked) rather than binary.
     - **Acknowledge limitations**: Clearly state that the heterogeneity analysis is exploratory due to small sample size.

---

### 4. Suggestions

#### **Conceptual and Theoretical Improvements**
1. **Reframe the research question**:
   - The manifest asks: *"Does earmarked marijuana revenue increase education spending or crowd out general-fund appropriations?"*
   - The paper answers: *"Earmarked revenue increases spending, but by more than the revenue itself."*
   - **Suggestion**: Clarify the **primary estimand** upfront. Is it:
     - The **average treatment effect** of legalization on spending (current focus)?
     - The **effect of earmarking** (heterogeneity analysis)?
     - The **passthrough ratio** (novelty claim)?
   - **Example**: *"This paper tests two hypotheses: (1) whether marijuana legalization increases education spending, and (2) whether earmarking amplifies this effect beyond the revenue itself."*

2. **Engage more deeply with fungibility theory**:
   - The paper cites Hines & Thaler (1995) and Evans & Zhang (2007) but does not explain **why marijuana earmarks might differ from lottery earmarks**.
   - **Suggestion**: Add a **theoretical framework** section (e.g., in the introduction) contrasting:
     - **Lottery earmarks**: Low salience, small revenue, often for specific programs (e.g., college scholarships).
     - **Marijuana earmarks**: High salience (ballot initiatives), large revenue, often for broad purposes (e.g., K–12 construction).
   - **Prediction**: Marijuana earmarks may have **lower fungibility** due to political commitment effects.

3. **Address alternative explanations for passthrough > 1**:
   - The paper mentions three mechanisms but does not test them. **Suggestions**:
     - **Fiscal spillovers**: Include controls for:
       - State corrections spending (to capture reduced criminal justice costs).
       - Other tax revenue (sales, income) to capture broader economic growth.
     - **Political signaling**: Use data on:
       - Legislative voting records (e.g., Did earmark states pass larger education budgets post-legalization?).
       - Media coverage (e.g., Google Trends for "marijuana schools" in earmark vs. non-earmark states).
     - **Confounding**: Test whether earmark states had **faster pre-trends** in education spending (e.g., event-study plots for earmark vs. non-earmark states).

#### **Empirical and Methodological Improvements**
4. **Improve parallel trends tests**:
   - The paper shows **aggregate pre-trends** (Figure 1 in the appendix would help) but does not:
     - Test for **differential pre-trends** between earmark and non-earmark states.
     - Report **p-values** for pre-trend coefficients (e.g., joint significance test).
   - **Suggestion**:
     - Add a **formal pre-trends test** (e.g., regress pre-treatment leads on treatment, test if coefficients are jointly zero).
     - Show **event-study plots** for earmark vs. non-earmark states separately.

5. **Strengthen the placebo tests**:
   - The federal revenue placebo is clean ($39, SE = $40), but the paper does not test:
     - **Local property tax revenue** (manifest promised this).
     - **Non-education state spending** (manifest promised this).
   - **Suggestion**:
     - Add a **placebo table** with outcomes like:
       - Local property tax revenue (should be null).
       - State spending on corrections, healthcare, or transportation (should increase if fungibility occurs).
     - **Example**: *"If marijuana revenue crowds out general-fund education spending, we should observe increases in other state spending categories."*

6. **Address COVID-19 confounding**:
   - The paper excludes 2020–2021 but does not discuss how **ESSER funds** (federal COVID relief for schools) might bias results.
   - **Suggestion**:
     - Control for **ESSER allocations** (available from the U.S. Department of Education).
     - Test whether **ESSER funds were larger in legalizing states** (e.g., did legalization make states more likely to spend ESSER on education?).

7. **Improve heterogeneity analysis**:
   - The earmark/non-earmark comparison is underpowered. **Suggestions**:
     - **Use a continuous treatment**: Model earmarking as the **% of marijuana revenue earmarked for education** (e.g., CO = 100%, WA = 0%).
     - **Pool earmark states**: Combine all earmark states into one group and test for a **dose-response** (e.g., does spending increase more in states with higher earmark %?).
     - **Add a triple-diff**: Compare earmark vs. non-earmark states **within legalizing states** (e.g., DiD of DiD).

8. **Clarify the passthrough ratio**:
   - The paper calculates the passthrough ratio as **ATT / marijuana revenue per pupil** but does not:
     - Explain how this relates to Evans & Zhang’s (2007) 50–70 cent benchmark.
     - Test whether the ratio is **statistically different from 1** (complete non-fungibility).
   - **Suggestion**:
     - **Formal test**: Regress spending on marijuana revenue (instrumented by legalization) and test if the coefficient = 1.
     - **Benchmark**: Compare to lottery studies (e.g., "Our passthrough ratio of 5.2 is 7–10x higher than the 50–70 cent estimates for lottery earmarks").

#### **Presentation and Transparency**
9. **Add key figures**:
   - **Event-study plots**: Show dynamic effects of legalization on spending (e.g., leads/lags for earmark vs. non-earmark states).
   - **Map of earmarking structures**: Visualize which states earmark and how much.
   - **Revenue vs. spending trends**: Plot marijuana revenue and education spending over time for earmark vs. non-earmark states.

10. **Improve table clarity**:
    - **Table 1 (summary stats)**: Add a **column for earmark vs. non-earmark states** (not just legalizing vs. non-legalizing).
    - **Table 2 (main results)**: Report **SEs for the earmark/non-earmark difference** in Panel C.
    - **Table 3 (robustness)**: Add a **row for "exclude early legalizers"** (CO/WA/OR) to test if results are driven by Western states.

11. **Discuss external validity**:
    - The paper focuses on **20 states**, but marijuana legalization is expanding. **Suggestions**:
      - **Generalizability**: Are results driven by early adopters (CO/WA/OR), which may differ from later legalizers (e.g., NY, NJ)?
      - **Policy relevance**: How might results change if more states legalize (e.g., will earmarking effects weaken as legalization becomes less salient)?

12. **Address data limitations**:
    - The Census data end in **2022**, but 5 states legalized in **2022–2023** (RI, MO, CT, NY, VA). **Suggestions**:
      - **Extend data**: Use preliminary 2023 data if available (e.g., state education department reports).
      - **Acknowledge**: State that results may not generalize to newer legalizers.

#### **Minor but Helpful Suggestions**
13. **Clarify treatment timing**:
    - The paper defines treatment as the **fiscal year of first sales**, but some states (e.g., VT) legalized without sales. **Suggestion**:
      - **Sensitivity check**: Use **legalization year** (not sales year) as treatment.
      - **Justify**: Why fiscal year (not calendar year) is appropriate.

14. **Discuss inflation**:
    - All dollar amounts are **nominal**. **Suggestion**:
      - **Robustness check**: Re-estimate models with **real per-pupil spending** (CPI-adjusted).
      - **Note**: Inflation is unlikely to bias results (treatment and control states face the same inflation), but real dollars are more interpretable.

15. **Improve discussion of mechanisms**:
    - The paper mentions **political signaling** but does not cite relevant literature. **Suggestions**:
      - **Theory**: Cite work on **earmarks as commitment devices** (e.g., Besley & Coate 2003 on political accountability).
      - **Empirics**: Compare to studies on **ballot initiative salience** (e.g., Matsusaka 2004 on direct democracy).

16. **Add a policy implications section**:
    - The conclusion is **academic** ("open question"). **Suggestion**:
      - **Policy takeaway**: If earmarking works as a political signal, should advocates push for **more earmarks** in marijuana legalization campaigns?
      - **Caveat**: If results are driven by early adopters, earmarking may be **less effective** in later legalizing states.

---

### **Final Assessment**
This is a **strong and novel** paper that makes a **genuine contribution** to the literature on fiscal fungibility and marijuana policy. The staggered DiD design is well-suited to the research question, and the heterogeneity analysis (earmark vs. non-earmark) is a key strength. However, the **three critical issues** (parallel trends, passthrough ratio, heterogeneity power) must be addressed before publication. With revisions, this paper could be a **high-impact AER: Insights piece**.

**Recommendation**: **Revise and resubmit** with:
1. A **clearer theoretical framework** for why marijuana earmarks differ from lottery earmarks.
2. **Stronger tests of mechanisms** (spillovers, political signaling, confounding).
3. **Improved robustness** (drop Alaska, add placebo tests, extend data).
4. **More transparent presentation** (event-study plots, passthrough ratio tests).
