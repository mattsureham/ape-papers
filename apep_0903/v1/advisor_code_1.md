# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T10:57:18.869061

---

**Idea Fidelity**

The paper largely follows the original manifest. It exploits the Second Home Initiative’s sharp 20 % threshold, uses the Federal Housing Inventory panel, and focuses on whether the ban converted housing toward long-term residents. The key missing element is that the identification strategy in the manuscript relies on the 2017–2025 Housing Inventory to determine the running variable, rather than the pre-policy second-home share that motivated the threshold. Because the running variable is observed after the ban’s implementation (2016), the continuity assumption for a sharp RDD is left unexamined, which undermines the core strategy described in the manifest.

---

**Summary**

The paper uses a regression discontinuity design around the 20 % second-home share threshold created by Switzerland’s Second Home Initiative to test whether the construction ban shifted housing stock from vacation to permanent use. Using 16 semi-annual waves of the Federal Housing Inventory, the author finds a precisely estimated null effect on changes in second-home shares, supporting the interpretation that the policy froze development without converting existing stock. Robustness checks (bandwidths, polynomials, placebo thresholds, McCrary test) reinforce the conclusion.

---

**Essential Points**

1. **Running Variable Measured Post-Treatment:** The running variable—each municipality’s second-home share—is defined using the first observed wave of the federal housing inventory (2017), but the treatment (ban) went into force in 2016. If the ban already affected the running variable before it is used for treatment assignment, the RDD’s key continuity assumption is violated: municipalities above and below 20 % in 2017 might differ precisely because of the ban. The paper needs to demonstrate that the 2017 second-home share reflects pre-treatment status (e.g., by showing the pre-policy distribution or an alternative running variable measured before 2016). Without this, the identification argument is not credible.

2. **Interpretation of “Conversion” Requires Clarifying the Outcome:** The paper tests whether the change in the second-home share from 2017 to 2025 differs at the threshold, but the policy’s stated objective is to convert *existing* stock. Since the ban only restricted *new* second-home construction, changes in the share may be driven by differential growth in total dwellings rather than conversion of existing second homes. The authors should disentangle whether treated municipalities had differential entry/exit in the stock (e.g., decomposition into numerator vs. denominator changes) and connect this more tightly to the notion of “conversion,” as the current empirical angle may not cleanly capture that concept.

3. **Parallel Trends / Dynamics around the Threshold Are Underexplored:** The RDD rests on the assumption that municipalities just above and below 20 % would have experienced similar trends absent the ban. While placebo thresholds and McCrary tests are informative, the manuscript lacks evidence on the pre-treatment path of the running variable or outcomes near the cutoff. An event-study plot using data from before 2016 (if available) or placebo manipulations using earlier inventories would strengthen the continuity claim. If such data are unavailable, the paper should explicitly acknowledge this limitation and discuss its implications for causal interpretation.

---

**Suggestions**

- **Use Pre-Treatment Running Variable or Demonstrate Predetermined Distribution:** If data on second-home shares before the ban (e.g., 2010–2014 inventories) exist, re-define the running variable using a pre-2016 measure so that treatment assignment is clearly exogenous to the ban. If those data cannot be obtained, consider instrumenting or modeling the 2017 share as a function of the 2015 share to argue that it is effectively predetermined. At a minimum, present evidence (e.g., density plots of pre-2016 shares, comparisons of trends) showing that the 2017 share is an unbiased proxy for the pre-policy status.

- **Clarify What “Conversion” Means in the Data Context:** The text argues that the ban failed to convert second homes into primary residue, yet the outcome is the change in the second-home share. The authors should break down the share into its components (number of second homes vs. total dwellings) so readers can judge whether the null arises because both numerator and denominator move together. A complementary outcome—such as the change in the absolute number of primary dwellings or permanent population—might more directly capture conversion.

- **Explain Sample Construction/Policy Timing More Precisely:** The paper mentions that treatment status is based on the “initial wave” but does not specify whether municipalities crossed the threshold later (due to measurement noise or actual stock changes). Provide a table showing the distribution of second-home shares in each wave around the threshold (e.g., proportion of municipalities crossing above/below over time) to reassure that treatment is stable and that the sharp design is defensible. Also clarify whether municipalities that merged or split are treated consistently.

- **Assess Potential Heterogeneity:** While the main effect is null, heterogeneity analysis could be illuminating. For instance, does the null hold for municipalities with very high second-home shares (well above 20 %) versus those just above the cutoff? Perhaps the ban had different implications depending on whether communities were close to the threshold or far above it. Even descriptive evidence (e.g., plots of changes in second-home shares versus baseline intensity) could help.

- **Discuss Alternative Mechanisms and Policy Implications More Nuanced:** The interpretation section currently leans toward a flow-vs-stock narrative, but the data used (post-implementation shares) make it hard to rule out other dynamics, such as differential investment or amenities. The policy discussion would benefit from incorporating this nuance—perhaps by acknowledging that the ban may have reduced new second-home construction (consistent with Hilber & Schoni) but was insufficient to alter the composition because existing owners face no incentives to change usage. This modesty would make the null finding more credible.

- **Supplement Robustness with Alternative Estimation Approaches:** In addition to local linear RDD, consider implementing a “fuzzy” design if there is any imperfection in enforcement, or a comparison with a DiD around the threshold to see whether the results align. Even a simple IV regression (using the 20 % rule as an instrument for new second-home approvals) could provide context on whether the policy affected the denominators vs. numerators differently.

- **Provide More Information on Standardized Effect Sizes:** Appendix Table A1 mentions standardized effect sizes but leaves “heterogeneous panel” blank. Filling in these rows or removing them would avoid confusion. Also, explain how the “Small positive” etc. classification is constructed and what it implies in terms of policy significance.

These suggestions aim to deepen the causal credibility of the RDD, sharpen the interpretation of the null result, and help the reader understand the policy relevance of the findings.
