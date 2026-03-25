# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-25T10:55:30.279461

---

# Referee Report

**Paper:** The Phantom Race: Municipal Tax Competition Without Consequences in Switzerland
**Format:** AER: Insights

## 1. Idea Fidelity

The paper largely pursues the core research question outlined in the Original Idea Manifest: testing the Zodrow-Mieszkowski (1986) prediction that municipal tax competition erodes public goods provision using Swiss *Steuerfuss* variation. The data sources (Zurich *Jahresrechnungen*, STATENT, Steuerfuss panels) align with the manifest. However, there is a significant deviation regarding the **time horizon and sample size**. The Manifest承诺 (promised) a panel from 1995–2024 (~4,000 observations), leveraging 25 years of variation. The submitted paper utilizes a truncated sample from 2012–2017 (~819 observations). This reduction severely impacts statistical power and the ability to detect long-term adjustments in public goods provision. Additionally, the Manifest proposed "canton-year trends" for identification, but the paper employs only year fixed effects (appropriate for a single-canton study, but inconsistent with the multi-canton implication of the original design notes). While the core idea remains intact, the execution falls short of the feasibility parameters established in the proposal.

## 2. Summary

This paper provides a direct empirical test of the foundational tax competition hypothesis that jurisdictions competing for mobile capital will under-provide public goods. Exploiting within-municipality variation in corporate tax multipliers across 140 municipalities in Canton Zurich, the author finds no evidence that tax cuts reduce per-capita spending on education, social welfare, or infrastructure. Furthermore, tax cuts fail to attract significant firm entry. The results suggest that municipal tax competition in Switzerland is a "phantom race"—visible in rate setting but without detectable welfare consequences—challenging the normative case for tax harmonization policies like OECD Pillar Two.

## 3. Essential Points

The paper presents a compelling null result, but three critical issues must be addressed to support the causal claims required for *AER: Insights*:

1.  **Data Truncation and Statistical Power:** The reduction from the proposed 1995–2024 window to 2012–2017 is the most concerning deviation. Six years of data may be insufficient to capture the lagged effects of tax competition on public goods, which often involve multi-year budgeting cycles. The Minimum Detectable Effect (MDE) calculations are helpful, but the short time series raises concerns about whether the null is driven by a lack of long-run variation. The authors must justify why the post-2017 *Jahresrechnungen* data were excluded despite the Manifest confirming access through 2024.
2.  **Endogeneity of Tax Changes:** The identification strategy relies on within-municipality variation, assuming tax changes are exogenous to spending needs conditional on fixed effects. However, Swiss municipalities often adjust tax rates in response to fiscal shocks (e.g., loss of a major employer). If a municipality cuts spending *and* raises rates simultaneously due to a budget deficit, this could bias the coefficient toward zero or positive. The paper acknowledges this but relies on political frictions as a mitigation. A stronger instrument (e.g., neighbor rates as suggested in the Manifest) or a shock-based design is needed to rule out reverse causality.
3.  **Interpretation of "Corporate" Competition:** The paper highlights a 0.995 correlation between corporate and natural-person tax rates. This implies municipalities are not competing specifically for capital but adjusting general fiscal stance. Consequently, the test is not strictly of the Zodrow-Mieszkowski *capital* competition model, but rather of general tax competition. The title and abstract should reflect this nuance to avoid overstating the specific test of corporate tax competition.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's contribution and ensure it meets the high bar for causal inference expected in *AER: Insights*. These suggestions focus on data reconciliation, identification robustness, and narrative refinement.

**Reconcile the Data Timeline**
The discrepancy between the Manifest (1995–2024) and the paper (2012–2017) is the most vulnerable point of the study. *AER: Insights* readers will expect the data to match the feasibility claims.
*   **Action:** Investigate why the *Jahresrechnungen* data were truncated at 2017. If this is due to a structural break in the accounting model (HRM1 vs. HRM2), explicitly document this in a Data Appendix and demonstrate that the 2012–2017 window is consistent. If the data exists comparably through 2024, **you must extend the panel**. Adding 7 years of data would increase observations by ~50%, significantly tightening standard errors and MDEs.
*   **Action:** If extension is impossible, provide a robustness check showing that pre-2012 trends in spending were parallel to post-2012 trends, ensuring the selected window is not cherry-picked to avoid a period where competition effects were visible.

**Strengthen the Identification Strategy**
The current Two-Way Fixed Effects (TWFE) design is vulnerable to time-varying confounders (e.g., local economic shocks). The Manifest mentioned an instrument using neighbor rates (Parchet 2019); this should be elevated from a mention to a core robustness check.
*   **Action:** Implement the "neighbor rate" instrument. Construct a measure of the weighted average tax rate of bordering municipalities. Use this as an instrument for the own-municipality rate. This isolates variation driven by competitive pressure rather than internal fiscal stress. If the IV results match the OLS null, the causal claim is much stronger.
*   **Action:** Consider a "border discontinuity" approach. Compare municipalities on the border of Canton Zurich (exposed to inter-cantonal competition) vs. interior municipalities. If tax competition matters, border municipalities should show stronger effects. A null result here would be even more convincing evidence against the Z-M hypothesis.
*   **Action:** Address the "fiscal stress" confounder directly. Control for municipal debt levels or unemployment rates in the main specification. If tax hikes are driven by high debt, omitting debt biases the coefficient. Including these controls ensures the *Steuerfuss* coefficient captures competition rather than crisis management.

**Refine the Mechanism and Narrative**
The finding that corporate and personal rates move in lockstep (0.995 correlation) is scientifically valuable but complicates the "Corporate Tax Competition" narrative.
*   **Action:** Reframe the contribution. Instead of claiming to test *corporate* tax competition specifically, position the paper as testing *municipal fiscal autonomy* more broadly. The question becomes: "When municipalities lower overall tax burdens, do they cut services?" This aligns better with the data reality.
*   **Action:** Deepen the revenue analysis. The paper finds no effect on tax revenue. This is the key mechanism: if revenue doesn't fall, spending shouldn't either. Decompose revenue into corporate tax, personal tax, and transfers. If corporate tax revenue falls but transfers increase (fiscal equalization), this explains the spending null. Explicitly testing the equalization channel would add significant policy value, as it suggests institutional designs can neutralize competition effects.
*   **Action:** Clarify the "Lockstep" finding. Is this legal constraint or political choice? If municipalities *cannot* set divergent rates easily, then tax competition is institutionally constrained. This is a major finding for policy design. Add a paragraph in the Institutional Background explaining whether there are political or legal barriers to decoupling these rates.

**Enhance Policy Implications for AER: Insights**
*AER: Insights* requires clear, actionable policy takeaways. The current discussion on OECD Pillar Two is good but could be sharper.
*   **Action:** Quantify the welfare implication. If tax competition does not reduce public goods, what is the cost? Is it purely administrative compliance costs? Or is there no cost? A clear statement on the *efficiency* of decentralization would resonate with policymakers.
*   **Action:** Discuss the role of Fiscal Equalization. Switzerland has strong inter-municipal transfer systems. If these systems insulate spending from tax base volatility, then the lesson for OECD Pillar Two is that *harmonization* might be less important than *equalization mechanisms*. This is a nuanced but critical distinction for international tax policy.

**Formatting and Presentation**
The current LaTeX structure resembles a standard article rather than an *AER: Insights* piece.
*   **Action:** Tighten the text. *Insights* papers are typically shorter (often under 5,000 words). Condense the Institutional Background and Data sections. Move detailed variable construction to an online appendix.
*   **Action:** Visualize the "Null." Instead of just tables, include an event study figure showing coefficients around tax changes with confidence intervals. Visual evidence of a flat pre-trend and flat post-trend is more persuasive for a null result than table coefficients alone.
*   **Action:** Ensure the Abstract highlights the *mechanism* (why the null exists), not just the null itself. The "lockstep" finding is as important as the spending result.

**Final Thought on Contribution**
The paper has the potential to be a significant contribution if the data limitations are resolved. A well-identified null result on tax competition is rare and valuable. However, the current sample size (6 years) leaves too much doubt about whether the effect exists but is undetected. By extending the data, strengthening the instrument, and clarifying the "general vs. corporate" tax narrative, this paper could definitively settle the question for the Swiss context and offer broader lessons for fiscal federalism. I encourage the authors to undertake these revisions before final submission.
