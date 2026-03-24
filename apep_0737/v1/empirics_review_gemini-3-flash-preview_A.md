# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-03-22T15:13:20.971850

---

This review evaluates the paper "Fear of Ten Billion: Bunching Evidence on the Regulatory Costs of Dodd-Frank" according to the standards of a top-tier economics journal (AER: Insights style).

### 1. Idea Fidelity
The paper aligns closely with the original idea manifest. It successfully implements the Kleven-Waseem (2013) polynomial bunching framework using FFIEC Call Report data (RCFD2170). Crucially, it executes the proposed "de-bunching" test following the 2018 EGRRCPA, which was identified as a key novel contribution. The identification strategy—using pre-Dodd-Frank data as a temporal counterfactual and utilizing placebo thresholds—faithfully follows the design parameters laid out in the manifest.

### 2. Summary
The paper provides the first formal bunching estimation of the $10 billion regulatory threshold in U.S. banking, documenting a 55% excess mass of banks just below the cliff post-2010. By exploiting the 2018 EGRRCPA as a natural experiment that removed stress-testing requirements but kept interchange fee caps, the author identifies the Durbin Amendment as the primary driver of growth-constraining behavior. The results quantify the significant shadow cost of size-based regulation and suggest that discrete policy "notches" create substantial distortions in the bank size distribution.

### 3. Essential Points
1.  **Persistence of the Counterfactual:** The Kleven-Waseem approach assumes the counterfactual distribution is smooth. However, the banking industry underwent massive consolidation and a "search for yield" environment between the pre-period (2001–2009) and post-period (2011–2017). The paper must more aggressively address whether the "true" counterfactual distribution (absent regulation) shifted in a way that mimics bunching—for instance, if the mid-sized bank business model became less viable generally, pushing banks to either stay small or merge into much larger entities ($>$ $50B).
2.  **The "Trailing Average" Problem:** As noted in Section 2, the threshold is often enforced based on a four-quarter trailing average. The current bunching estimation uses quarterly snapshots. If banks "window-dress" for one quarter but exceed the limit on an average basis, the $\hat{b}$ estimate might be overstating the actual avoidance of regulation. The author should re-run the primary specification using the 4-quarter moving average of assets as the running variable to ensure the results track the actual regulatory trigger.
3.  **Bootstrapping and Cross-Sectional Size:** The year-by-year estimates in Table 5 show massive standard errors in certain years (e.g., 2013, 2021). This suggests the cross-section of banks near the $10B mark in a single year might be too thin for stable polynomial fitting. The paper should consider using a "pooled" rolling window or a different smoothing technique (e.g., constrained spline) to ensure the dynamic results are not driven by a few idiosyncratic bank exits or entries in the $9.5B–$10.5B range.

### 4. Suggestions

**Institutional Detail and Mechanism**
*   **Asset Composition:** The paper mentions banks manage size through loan sales or securitization. It would significantly strengthen the paper to show *how* they bunch. Do banks just below $10B hold higher ratios of liquid assets or engage in more secondary market loan sales compared to the counterfactual? This moves the paper from "documenting a gap" to "explaining a behavior."
*   **Merger Dynamics:** Is the bunching driven by organic growth suppression or by M&A behavior? One might expect a "donut hole" in M&A where no one wants to acquire a bank that puts the survivor at $10.1B. Checking if the probability of being an acquirer drops discontinuously at the threshold would be a high-value addition.

**Empirical Refinements**
*   **The EGRRCPA Test:** The finding that bunching fell by half after 2018 is the most interesting part of the paper. I suggest expanding Section 5.1 to discuss the "composition" of the regulatory cost more formally. If the $10B notch is a bundle of $Cost_{CFPB} + Cost_{Durbin} + Cost_{StressTest}$, and EGRRCPA removed $Cost_{StressTest}$, you can arguably back out the relative weights of these costs.
*   **Bin Width Sensitivity:** In Table 4, the $\hat{b}$ estimate for $100M bins (0.848) is significantly higher than for $250M bins (0.549). This often indicates that the bunching is very "sharp" (right at the limit). I recommend producing a figure showing the raw density with $100M bins to see if there's a spike at $9.9B.
*   **Standard Errors:** Given that banks appear in the data multiple times, clustering by bank is correct. However, you should also consider two-way clustering by Bank and Quarter to account for macro-prudential shocks that affect all mid-sized banks simultaneously.

**Formatting and Presentation**
*   **Visualizing the Counterfactual:** The paper lacks the classic bunching plot (the "Kleven-Waseem plot") showing the histogram of actual data overlaid with the fitted polynomial. This is the "money shot" for any bunching paper and is essential for convincing the reader that the polynomial fit is reasonable.
*   **Table 1 (Summary Stats):** Add a column for "Net Interest Margin" or "Return on Assets" to Table 1. This would allow a quick check of whether the banks near the bunching zone are fundamentally different (more or less profitable) than those further away.
*   **The McCrary Test:** While the $t$-stat is high, McCrary tests can be sensitive to binning. Report the bin size and bandwidth used for the local linear regression in the table notes.

**Minor Points**
*   The abstract mentions a "55 percent more banks" figure, but the DiB estimate is 63%. Be consistent about which number is the headline result.
*   Ensure the "Total Assets" definition (RCFD2170) is consistent across the 2001–2024 period, as Call Report definitions occasionally shift. (Specifically, check for the treatment of disallowed deferred tax assets or intangible assets which were modified by Basel III implementation).
