# V1 Empirics Check — google/gemini-3-flash-preview (Variant B)

**Model:** google/gemini-3-flash-preview
**Variant:** B
**Date:** 2026-04-02T22:23:09.144561

---

**Referee Report**

**Paper:** *Paper Patents: Do Marginal Patent Grants Create Real Market Value?*
**ID:** idea_2123

---

### 1. Idea Fidelity
The paper follows the original idea manifest with high fidelity. It successfully implements the proposed identification strategy (leave-one-out examiner instrument) and links the USPTO PatEx data to the assignment records in BigQuery as planned. The researcher expanded on the original "Market Transfer" outcome by including "Security Interests" (collateralization), which strengthens the paper’s contribution to the finance and innovation literature. 

One notable deviation from the manifest is the finding regarding entity size. The smoke test in the manifest suggested a "REVERSED" sign for small-entity market transfers (strict examiners' patents trading more), which was interpreted as the market recognizing quality. However, the final paper reports nearly identical IV effects for small and large entities (12.8 pp vs 13.4 pp). While this contradicts the initial smoke test, the paper pivots to a different, equally compelling narrative: that marginal patents are liquid assets regardless of the holder's size.

### 2. Summary
This paper identifies the causal effect of patent grants on secondary market outcomes using a quasi-random examiner assignment instrument. Linking 4.4 million USPTO applications to assignment records, the author finds that a marginal patent grant increases the probability of a market transfer by 13.4 percentage points and a security interest filing by 7.3 points. The core contribution is the finding that even "marginal" patents—whose grant depends on examiner luck rather than clear-cut merits—function as liquid economic assets, challenging the notion that low-quality patents are merely "paper" rights.

### 3. Essential Points

1.  **Selection into Assignment for Abandoned Applications:** A primary concern is how to interpret the 11.6% transfer rate for *abandoned* applications. As the author notes, these transfers must occur during prosecution. However, if an application is being transferred *before* the grant decision, the examiner assignment (treatment) may be endogenous to the transfer (outcome) if certain types of firms or high-value inventions are more likely to be assigned to specific types of examiners. While the art-unit-by-year FEs mitigate this, the paper needs to clarify the timing. Does the instrument predict transfers *post-disposal*? A cleaner outcome would be "Transfer within X years after grant/abandonment" to ensure the exclusion restriction holds.
2.  **The Small Entity "Reversal" Discrepancy:** The manifest suggested that for small entities, strict examiners led to *higher* trade rates (implying quality sorting). The final paper finds no such heterogeneity. Given that this "quality sorting" was the "Bigger Idea" in the manifest, the paper needs to explain why the full sample did not yield this result. Is the lack of heterogeneity because "marginal" patents are, by definition, similarly low-quality regardless of the applicant type? Or is there a measurement issue in how small-entity status is handled?
3.  **Mechanical Exclusion Restriction Violations:** The paper briefly addresses claim breadth but should more formally discuss whether examiner leniency is correlated with other examination features that affect marketability, such as "pendency" (time spent in prosecution). If lenient examiners grant patents faster, the increased trade might be a "time-to-market" effect rather than a "grant" effect. Controlling for pendency or showing it is balanced across the instrument would be a critical robustness check.

### 4. Suggestions

*   **Mechanism: Who is buying?** The BigQuery assignment data includes the names of assignees. While a full categorization of 5 million records is impossible, the author could sample the top 100 assignees for "marginal" patents (those in the high-leniency quartiles). This would provide color on the "Patent Troll" argument—are these patents flowing toward NPEs or toward large aggregator firms like Intellectual Ventures?
*   **The Collateral Channel:** The finding on security interests (IV > OLS) is arguably the most novel part of the paper. This suggests that the "marginal" patent is particularly valuable to firms with fewer outside options for credit. I suggest expanding the discussion on why a "lucky" grant is more useful for collateral than a "high-quality" (inframarginal) grant. Is it because the bank only cares about the binary existence of the right, not its technical merit?
*   **Visualizing the Reduced Form:** The paper would benefit from a binned scatter plot showing the probability of a market transfer (y-axis) against the examiner instrument (x-axis), residualized by the fixed effects. This would provide visual confirmation of the linearity and monotonicity of the relationship.
*   **LATE interpretation:** The paper should emphasize that these are "marginal" patents. If "inframarginal" patents (those any examiner would grant) trade at even higher rates, the 13.4 pp effect is a lower bound on the value of a grant. Conversely, if marginal patents trade *at the same rate* as inframarginal ones, it suggests the market is "quality-blind." A simple comparison of the transfer rates for "obvious grants" vs. "marginal grants" would be highly informative.
*   **Clarify "Employer Assignments":** The data appendix mentions excluding employer-employee transfers. This is excellent. Does the "Market Transfer" variable include intra-firm transfers (e.g., Google Inc. to Google LLC)? Using the `assignee_name` to filter out likely parent-subsidiary transfers would increase the "real market value" signal.
*   **Art Unit Level Clustering:** Ensure that the number of clusters (701) is sufficient for the variations in the instrument. While 701 is generally large enough, the "monotonicity" could be explored at the Technology Center level to show robustness.
