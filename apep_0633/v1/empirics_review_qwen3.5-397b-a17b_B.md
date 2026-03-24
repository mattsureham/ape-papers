# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-13T16:12:48.110039

---

1. **Idea Fidelity**

The paper adheres closely to the original idea manifest. The core research question (does earmarked marijuana revenue increase education spending or crowd out general funds?), the data source (Census Annual Survey of School System Finances, 2008–2022), and the identification strategy (Callaway-Sant'Anna staggered DiD) match the proposal exactly. There is a minor discrepancy in the number of treated states: the manifest proposed 24 states, while the paper analyzes 20. This is likely due to data availability constraints for revenue onset dates versus legalization dates, which is a reasonable empirical adjustment. The falsification tests (federal revenue) and heterogeneity analysis (earmark vs. non-earmark) proposed in the manifest are executed as planned. The paper successfully operationalizes the feasibility check outlined in the idea phase.

2. **Summary**

This paper provides the first causal evidence on the fiscal fungibility of earmarked marijuana tax revenue, exploiting staggered state legalization between 2014 and 2023. The author finds that states earmarking revenue for education exhibit significant increases in per-pupil spending, whereas non-earmarking states do not. However, the magnitude of the spending increase exceeds the marijuana revenue collected by a factor of five, suggesting that earmarks function less as direct fiscal pipelines and more as political commitment devices that facilitate broader spending expansions.

3. **Essential Points**

1.  **Interpretation of the "Passthrough > 1" Result:** The central finding—that education spending increases by \$1,175 per pupil despite only \$227 in marijuana revenue—fundamentally challenges the causal narrative. If the treatment is "marijuana revenue," the effect cannot logically exceed the dose unless there are massive multiplier effects or omitted variable bias. The current explanation ("political cover" or "correlated growth") is speculative. The authors must clarify whether they are estimating the effect of *legalization* (which brings revenue and political change) or the effect of *revenue* (which is fungible). As written, the claim that earmarking "increases spending" is confounded by the possibility that states prone to legalization are simply prone to spending growth.
2.  **Fragility to Outliers (Alaska):** The main result shifts from statistically insignificant (\$716, SE=\$806) to highly significant (\$1,346, SE=\$341) solely upon excluding Alaska. With only 20 treated units, the analysis is overly sensitive to singleton cohorts. In a staggered DiD design with such a small treated sample, reliance on a specific exclusion restriction to achieve significance undermines the robustness required for an *AER: Insights* publication. The authors must demonstrate that the result holds under alternative weighting schemes or control group constructions without arbitrary exclusions.
3.  **Selection Bias and Parallel Trends:** Early-adopting states (Colorado, Washington, Oregon) are economically and politically distinct from the "never-treated" control group (which includes many Southern and Midwestern states). While the federal revenue placebo is clean, it does not rule out state-level economic shocks (e.g., tourism booms, tech growth) that correlate with both legalization and education budget expansions. The parallel trends assumption is plausible but not convincingly demonstrated without visual event-study evidence. If pre-trends differ between early legalizers and controls, the causal estimate is biased.

4. **Suggestions**

To strengthen the paper for publication, I recommend the following substantive and presentational improvements. These suggestions focus on bolstering the identification strategy, refining the economic narrative, and enhancing transparency.

**1. Strengthening Identification with Economic Controls and SCM**
Given the small sample size (N=20 treated), the standard CS-DiD may not adequately balance covariates between treated and control states. I strongly recommend augmenting the regression model with time-varying state-level economic controls. Specifically, include state unemployment rates, per-capita GDP, and housing price indices from the Bureau of Economic Analysis or BLS. These factors drive both tax revenue (including marijuana) and education budget capacity. If the result persists after controlling for general economic health, the claim that marijuana policy *specifically* drives spending becomes more credible.

Furthermore, consider supplementing the CS-DiD with a Synthetic Control Method (SCM) analysis for the earliest adopters (CO, WA, OR). With only 31 control states, constructing a synthetic counterfactual for Colorado using a weighted combination of non-legalizing states could provide a more transparent visual of the counterfactual trend. If the synthetic Colorado diverges from actual Colorado post-2014 only in education spending (and not in other budget categories), this would bolster the causal claim significantly.

**2. Reframing the Narrative: Political Economy vs. Fungibility**
The current title and abstract frame the paper as a test of fiscal fungibility. However, the finding that spending increases *more* than the revenue implies the mechanism is not standard fungibility (which predicts 0–100% passthrough). I suggest reframing the contribution to emphasize the *political economy of earmarking*. The story is not that "money isn't fungible," but rather that "earmarks change the political cost of spending."
*   **Action:** Revise the title to reflect this nuance, e.g., *"Earmarks as Political Cover: Marijuana Legalization and Education Spending."*
*   **Action:** In the discussion, explicitly test the "political cover" hypothesis if possible. While legislative voting data may be out of scope, you could correlate the spending effect with the margin of victory for the legalization ballot initiative. If states where legalization passed narrowly (higher voter salience) show larger spending effects, this supports the political accountability mechanism over the correlated growth hypothesis.

**3. Visualizing Pre-Trends (Event Study)**
The text mentions event-study aggregation but does not provide a figure. For a DiD paper, especially one relying on the parallel trends assumption with heterogeneous treatment timing, a visual event-study plot is essential.
*   **Action:** Add a figure plotting the dynamic treatment effects ($\beta_k$ for $k$ years relative to legalization) with 95% confidence intervals.
*   **Action:** Ensure the pre-treatment coefficients are jointly insignificant. If there is a visible ramp-up in spending *before* legalization (anticipation effects), the identification strategy needs to account for this (e.g., by dropping anticipation years or modeling the trend).

**4. Clarifying Data Construction and State Counts**
There is a discrepancy between the manifest (24 states) and the paper (20 states). While likely due to data availability, this should be explicitly addressed to ensure reproducibility.
*   **Action:** Add a footnote or appendix table listing the exact 20 treated states and their treatment years. Explicitly state which 4 states from the original list were excluded and why (e.g., "sales began after 2022," "revenue data unavailable").
*   **Action:** Clarify the revenue data construction. The paper mentions using Tax Foundation data but notes availability for only 52 state-year observations. How is the treatment defined for states where revenue data is missing? Is it purely based on legalization date? If treatment is based on legalization but the mechanism is revenue, this mismatch needs clarification.

**5. Deepening the Fungibility Test**
The current test compares total spending in earmark vs. non-earmark states. A sharper test of fungibility would examine *composition*.
*   **Action:** If the Census data allows, distinguish between "State Source Revenue" allocated to education vs. "Local Source Revenue." True fungibility often manifests as local governments reducing their effort when state earmarks increase. If local revenue drops while state revenue rises in earmark states, that is direct evidence of fungibility within the education sector.
*   **Action:** Alternatively, examine non-education state spending (as suggested in the manifest's falsification tests). If earmark states show *larger* increases in non-education spending than non-earmark states, it suggests the marijuana revenue freed up general funds for other uses, while the education increase came from elsewhere. This would nuance the "passthrough > 1" conclusion.

**6. Addressing the COVID-19 Confounder**
The paper excludes 2020–2021 in one robustness check, but many treatment cohorts occur during or immediately after the pandemic (e.g., IL 2020, NY 2021). Federal ESSER funds drastically altered education finance during this period.
*   **Action:** Consider restricting the main sample to pre-2020 treatments and outcomes where possible, or explicitly control for federal pandemic relief funds received by each state. The current "Exclude 2020–2021" check is good, but if the treated units are primarily post-2019, this check removes most of the treatment variation. Be transparent about how much identifying variation remains after COVID exclusions.

**7. Standard Errors and Inference**
With 51 clusters (states), standard clustered standard errors may be biased downward (Bertrand et al. 2004). The paper uses a multiplier bootstrap, which is appropriate, but given the small number of treated clusters, inference is still precarious.
*   **Action:** Report wild-cluster bootstrap p-values (Cameron, Gelbach, and Miller 2008) in addition to the current standard errors. This is now standard practice for state-level DiD with few treated units.
*   **Action:** Consider a permutation test (placebo treatment assigned randomly to control states) to generate an empirical distribution of the treatment effect. If the actual estimate lies in the extreme tail of this distribution, it adds confidence beyond parametric standard errors.

**8. Polishing the Abstract and Conclusion**
The abstract currently highlights the "\$1,175 increase" prominently. Given the sensitivity to Alaska and the passthrough > 1 issue, this point estimate should be qualified.
*   **Action:** Modify the abstract to emphasize the *difference* between earmark and non-earmark states rather than the absolute level of the spending increase. The relative comparison is more robust to common shocks than the level estimate.
*   **Action:** In the conclusion, avoid definitive causal language regarding the *mechanism* (e.g., "earmarks serve as political cover"). Instead, use language like "consistent with a political cover mechanism" or "suggests earmarks may lower the political cost of spending."

By addressing these points, particularly the robustness of the identification strategy and the nuance of the economic mechanism, the paper can move from a suggestive correlation to a robust causal insight suitable for a top-field journal. The core idea is novel and valuable; the execution requires tightening to match the strength of the claim.
