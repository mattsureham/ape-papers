# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-04-08T13:49:27.702635

---

# Referee Report: "The Composition Illusion: Anticipatory Bunching and Transaction Value Distortion Around France's 2025 Real Estate Transfer Tax Increase"

## 1. Idea Fidelity

The paper **deviates substantially** from the original idea manifest in several critical dimensions, compromising the promised identification strategy and scope.

*   **Treatment Definition:** The manifest specified **73 treated departments** (with ~20 controls) based on administrative adoption of the DMTO increase. The paper instead defines treatment *empirically*, based on an "anomalous March 2025 rush" (excess March/Feb ratio ≥ 1.15), resulting in only **25 treated departments**. This is a fundamental shift from an analysis of a known policy adoption to a data-driven classification that risks post-treatment bias and severely weakens the causal narrative. The paper does not justify why it abandons the administratively defined treatment variable implied by the manifest.
*   **Missing RDD Component:** The manifest highlighted the **first-time buyer exemption at €250K** (effective June 1) as a central, novel element creating an "embedded RDD." This component is entirely absent from the paper's analysis. This omission represents a significant missed opportunity for sharper identification and limits the paper's contribution to the bunching literature, which often exploits notches and thresholds.
*   **Shift in Research Question:** The manifest emphasized quantifying "welfare costs of anticipated tax increases" and "implications for optimal tax implementation." The paper's discussion is limited to describing a "composition illusion" and its implications for revenue forecasting and market indicators. The deeper welfare and optimal policy analysis is not pursued.

While the paper uses the correct data source (DVF) and examines timing manipulation, its core empirical approach and research questions do not faithfully execute the original, more robust design.

## 2. Summary

This paper documents a significant anticipatory bunching of real estate transactions in March 2025 in French departments that implemented a pre-announced transfer tax (DMTO) increase on April 1, 2025. Using a difference-in-differences design, it finds a 23% transaction surge in treated departments in March, followed by a 38% hangover in April. Its key contribution is highlighting that this surge was **compositional**, disproportionately driven by higher-value transactions, creating a misleading signal of market health.

## 3. Essential Points

The authors must address these three critical issues for the paper to be publishable.

1.  **Endogenous Treatment Assignment Undermines Causal Claims:** The paper's central causal estimate relies on classifying departments as "treated" based on having an *outcome* (an anomalous transaction surge in March 2025). This is a classic case of conditioning on post-treatment variables. A department with a large March surge for reasons *unrelated* to the DMTO (e.g., a local economic shock) would be misclassified as "treated," biasing the DiD estimate. The identification strategy is therefore invalid as presented. **The authors must re-run the analysis using the *administratively defined* treatment indicator** (which departments formally adopted the increase per Article 116). This is the variation promised in the manifest and is essential for a causal interpretation.

2.  **Inadequate Justification for the Compositional "Illusion" Claim:** The paper's title and central thesis hinge on a "composition illusion," but the departmental-level DiD results in Table 2 (Columns 2-4) show **no statistically significant compositional shift** between treated and control groups in March 2025 for mean value or shares above €300K/€500K. The claim is supported only by *national-level* descriptive statistics, which conflate the treatment effect with nationwide seasonality or trends. To sustain the argument, the authors must either: (a) demonstrate a significant *differential* compositional shift in a properly specified DiD model (e.g., testing the share of high-value transactions), or (b) rigorously argue why the national-level shift is causally attributable to the policy despite the null DiD result, perhaps by leveraging the first-time buyer exemption for a regression discontinuity design.

3.  **Missing Pre-Trends and Parallel Trends Assessment:** The paper asserts parallel trends but provides no graphical or statistical evidence (e.g., event-study plots or leads-and-lags model) to support this critical DiD assumption. Placebo tests on earlier years are helpful but not sufficient. **The authors must include a dynamic DiD specification or event-study plot** showing the monthly coefficients for treated vs. control departments in the 12-24 months preceding March 2025. This is a standard requirement for DiD credibility.

## 4. Suggestions

The following recommendations would significantly strengthen the paper.

### A. Empirical Strategy & Analysis
*   **Use Official Treatment Status:** Obtain and use the official list of the 73 departments that adopted the DMTO increase. Compare the results using this list to the current data-driven approach in a robustness table. This directly addresses the main threat to identification.
*   **Incorporate the RDD:** Reintegrate the analysis of the first-time buyer exemption (€250k threshold effective June 1). Even if June 2025 data is not yet available, this should be framed as a clear avenue for immediate future work and a promised extension of the current draft. Discuss how this would strengthen identification.
*   **Refine Composition Analysis:** Instead of (or in addition to) department-level value quintiles, construct a direct measure of composition. For example, calculate for each department-month the share of transactions above the 80th percentile of that department's 2021-2024 value distribution. Use this as an outcome in the DiD framework to test for a differential compositional shift.
*   **Expand Heterogeneity Analysis:** The manifest suggested using departmental variation "to instrument housing demand elasticities." While perhaps too ambitious for this draft, a more structured heterogeneity analysis could be insightful. Interact the treatment with baseline department characteristics (e.g., median income, urbanization rate, prior price growth) to test which markets are most responsive.

### B. Presentation & Interpretation
*   **Revise the Title and Abstract:** The current title ("The Composition Illusion") overstates the paper's *causal* evidence on composition. Consider a more precise title like "Anticipatory Bunching and Compositional Shifts: Evidence from France's 2025 Real Estate Transfer Tax Reform." The abstract should clearly state the treatment assignment method (empirical vs. administrative) as a limitation.
*   **Clarify the "Illusion" Narrative:** The discussion section is compelling but should more carefully distinguish between descriptive facts (national composition shift) and causal estimates (DiD volume effect). Acknowledge that the causal evidence for a *differential* compositional shift is currently weak.
*   **Discuss Welfare and Revenue Implications More Deeply:** The "Discussion" section touches on forecasting errors. Expand this with a simple back-of-the-envelope calculation: Using the estimated bunching and hangover, what is the net effect on departmental DMTO revenue for Q1-Q2 2025? This would quantitatively underscore the policy relevance.
*   **Improve Table and Figure Readability:**
    *   Add a map of France in the appendix showing treated vs. control departments (both by the paper's definition and, if possible, the official list).
    *   In Table 1, the "Rush Window" panel mixes levels (total transactions) and ratios. Consider presenting treated and control department averages for February and March separately for counts and mean values to improve comparability.
    *   The event-study plot recommended in Essential Point #3 would be a crucial figure.

### C. Data & Robustness
*   **Justify Sample Trimming:** The paper excludes transactions below €5,000 and above €20 million. Provide a histogram of transaction values to justify these cutoffs as excluding clear data errors without affecting the main results.
*   **Test for Spatial Spillovers:** Could buyers in a treated department near a border simply purchase in a control department? Perform a sensitivity analysis excluding border departments or testing for unusual activity in control departments adjacent to treated ones.
*   **Address Seasonality More Rigorously:** The historical March/February ratio is central to the descriptive story. Plot this ratio for 2021-2025 for treated and control groups to visually show the 2025 anomaly. Control for department-specific seasonal patterns in a more flexible way in the DiD (e.g., department-by-month fixed effects).

### D. Literature and Context
*   **Sharpen the Contribution:** The literature review correctly cites Kopczuk & Munroe (2015) and Best & Kleven (2018). To strengthen the novelty claim, more explicitly contrast the institutional setting: a small, uniform rate increase applied at a *decentralized* (departmental) level with optional adoption, versus large, national-level notch or holiday policies. This links directly to the "decentralized tax authority" point in the manifest.
*   **Connect to Salience and Liquidity Constraints:** The interpretation that high-value buyers are more responsive could be due to higher salience (the absolute € saving is larger) or greater liquidity/flexibility (less reliant on mortgage approval timing). The discussion would benefit from explicitly framing the mechanism in these terms, linking to the literature on tax salience (e.g., Chetty, Looney, and Kroft, 2009).

**Overall:** The paper identifies a clear and policy-relevant phenomenon. However, in its current form, the causal claims are severely compromised by endogenous treatment assignment and lack of support for parallel trends. By returning to the administratively defined treatment variable, providing dynamic DiD evidence, and more rigorously analyzing composition, the authors can produce a much stronger and credible contribution. The rich data and clear policy shock provide an excellent foundation for such improvements.
