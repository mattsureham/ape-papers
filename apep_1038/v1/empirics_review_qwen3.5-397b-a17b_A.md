# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-27T04:50:10.335259

---

# Referee Report

**Manuscript:** The Phantom Pollution Drop: How TRI Reporting Rule Changes Manufacture Apparent Emissions Declines
**Journal:** AER: Insights

## 1. Idea Fidelity

The paper partially pursues the original idea outlined in the manifest but deviates significantly in its empirical execution and scope. The manifest proposed a **Stacked CS-DiD across five reporting rule changes** (1998, 1999, 2001, 2014, 2020) using **EPA AQS ambient monitors** for external validation. The submitted paper focuses exclusively on the **1998 sector expansion**, replaces the Stacked DiD with an **accounting decomposition and paired t-test**, and entirely omits the AQS validation data. While the core research question (measurement artifacts in TRI) remains intact, the identification strategy is weaker than proposed, and the claim that "actual emissions" did not change relies on institutional assumption rather than the empirical validation promised in the design parameters.

## 2. Summary

This paper quantifies the measurement artifact introduced by the EPA's 1998 Toxics Release Inventory (TRI) sector expansion, which mechanically increased reporting forms by approximately 20% without necessarily changing underlying pollution. Using an accounting decomposition of aggregate form counts and within-facility trend analysis, the author demonstrates that the reversal in declining TRI trends during the late 1990s is driven by the extensive margin of new reporters. The study warns researchers that aggregate TRI trends spanning regulatory boundaries conflate administrative changes with environmental progress.

## 3. Essential Points

1.  **Identification Strategy Mismatch:** The Introduction claims a "difference-in-differences design with facility and year fixed effects," but the Empirical Strategy and Results sections deliver an accounting decomposition and a simple paired difference test. There is no regression-based DiD estimator presented, no standard errors clustered at the appropriate level, and no control group comparison in a regression framework. This inconsistency undermines the causal language used throughout the text. The authors must either implement the claimed DiD specification (comparing treated sectors to control sectors over time) or revise the language to reflect the descriptive/accounting nature of the current analysis.
2.  **Missing External Validation (AQS):** The original design prioritized comparing TRI self-reports against EPA AQS ambient monitors to verify that "actual emissions" remained stable while reported forms jumped. This validation is absent. Without it, the central claim—that the trend reversal is a "phantom" artifact rather than a real pollution increase in newly covered sectors—rests on the assumption that the new sectors did not simultaneously increase production. Including AQS data near affected facilities is critical to distinguish between *measurement error* and *real economic activity shifts* in the newly covered industries.
3.  **Scope Reduction:** The manifest proposed exploiting five distinct regulatory shocks to establish a general paradigm of administrative measurement contamination. The paper analyzes only the 1998 shock. While the 1998 expansion is the largest, omitting the 1999 PBT, 2001 Lead, and 2020 PFAS changes limits the generalizability of the "correction factors" promised in the contribution. At minimum, the authors should acknowledge whether the 1998 artifact is unique in magnitude or representative of subsequent rule changes, perhaps through a brief appendix analyzing the 2001 or 2014 shocks using the same decomposition method.

## 4. Suggestions

The following recommendations are intended to strengthen the empirical rigor and alignment with the AER: Insights format. Implementing these changes will significantly improve the credibility of the identification strategy and the utility of the paper for the broader environmental economics community.

**Formalize the Empirical Strategy**
Currently, the paper oscillates between calling the design a "difference-in-differences" and an "accounting decomposition." For an *Insights* paper, precision is paramount. I recommend specifying a canonical DiD regression equation in Section 4, even if the primary result is the decomposition. For example:
$$ Y_{ist} = \beta \cdot \text{TreatedSector}_s \times \text{Post1998}_t + \gamma_s + \delta_t + \epsilon_{ist} $$
where $Y_{ist}$ is the log of reported releases or form counts for facility $i$ in sector $s$ at time $t$. This allows you to estimate $\beta$ with proper inference (clustered standard errors at the facility or sector level) rather than relying solely on aggregate residuals. If the data does not support a full regression (e.g., due to missing pre-period data for new sectors), explicitly state that the design is a "quasi-experimental accounting decomposition" rather than DiD to avoid confusing reviewers familiar with standard causal inference templates.

**Implement the AQS Validation**
The manifest correctly identified that self-reported data cannot validate itself. To confirm the "phantom" nature of the drop, you must show that ambient pollution levels did not jump in 1998 in areas where new TRI facilities appeared.
*   **Action:** Merge TRI facility locations with the nearest EPA AQS monitors (PM2.5, SO2, NOX) for the years 1995–2001.
*   **Test:** Run a DiD where the outcome is ambient concentration. If TRI reports jump 20% but ambient concentrations remain flat (or follow the pre-trend), you have direct evidence that the TRI jump is administrative, not physical.
*   **Visualization:** Add a figure plotting aggregate TRI releases against an index of ambient pollution concentrations around the 1998 break. A divergence here would be a powerful visual for an *Insights* paper.

**Expand the Scope or Reframe the Contribution**
The claim that "Every paper studying pollution trends across TRI rule-change dates is potentially biased" implies a comprehensive correction. Analyzing only 1998 weakens this universal claim.
*   **Option A (Expand):** Apply the same accounting decomposition to the 2001 Lead Rule and 2014 Electronic Mandate. Even if the effects are smaller, showing consistency across multiple administrative shocks strengthens the "general paradigm" argument.
*   **Option B (Reframe):** If data for later shocks is too complex, narrow the contribution to "The 1998 TRI Expansion Artifact." Adjust the Abstract and Introduction to focus on this specific historical episode as a case study in administrative measurement error, rather than promising correction factors for all TRI rule changes.

**Clarify the "Actual Emissions" Claim**
The paper states: "The rule moved the measurement boundary, not the pollution." This is technically an assumption. It is possible that the newly covered sectors (e.g., electric utilities, mining) were simultaneously expanding production in the late 1990s.
*   **Suggestion:** Add a paragraph in the Discussion acknowledging this limitation. Use economic context (e.g., employment data in mining/utilities from BLS) to argue whether production was stable during this window. If production was stable, the assumption holds; if not, the artifact is a mix of measurement and real activity. Nuance here will protect the paper from criticism that it conflates reporting coverage with emission intensity.

**Improve Data Transparency and Replicability**
As an empirical paper using administrative data, replicability is key.
*   **Code:** Provide the code used to query the EPA Envirofacts API and construct the balanced panel. Since API endpoints can change, archive the raw CSV extracts used for the study in a repository (e.g., Harvard Dataverse or OSF).
*   **Variable Definitions:** In the Data section, explicitly define how "incumbent" is coded. Is it based on facility ID stability? What about facility closures or mergers? A brief note on how facility identifiers were harmonized over time would add robustness.

**Refine Visualizations for Policy Impact**
AER: Insights papers benefit from highly accessible visuals.
*   **Figure 1:** Currently, Table 2 shows the trends. Convert this into a time-series figure showing Total Forms vs. Incumbent Counterfactual. Shade the gap between the two lines post-1998 to visually represent the "phantom" volume.
*   **Figure 2:** Map the new sectors. Show where the 2,000 new facilities are located geographically. This helps environmental justice researchers understand where the measurement bias is concentrated (e.g., are these facilities in low-income areas?).

**Strengthen the Literature Connection**
The Introduction cites Hamilton (1995) and Greenstone (2004). Deepen this connection in the Discussion.
*   **Specific Bias:** Quantify the potential bias in a specific famous result. For example, if a paper estimates a 10% decline in pollution post-regulation using TRI data spanning 1998, how much of that is your artifact? Providing a concrete "bias correction" example (e.g., "Studies spanning 1995–2005 should adjust aggregate trends downward by X%") would make the paper immediately useful to practitioners.

**Minor Writing and Structure Edits**
*   **Abstract:** The abstract mentions "Using a difference-in-differences design," which contradicts the body. Change this to "Using an accounting decomposition and facility-level trend analysis."
*   **Section 3 (Data):** The summary statistics table lists "Reporting facilities" as 22,976 for 1995 and 22,431 for 1997, but the text mentions 75,669 forms in 1997. Clarify the unit of observation in the table notes (is it facility-year or form-year?). Consistency here prevents confusion about the sample size.
*   **Conclusion:** The final sentence ("Administrative data measures what it is designed to measure...") is strong. Consider adding a call to action for journal editors to require measurement validation checks in papers using administrative data.

By addressing the identification mismatch, adding external validation, and clarifying the scope, this paper can serve as a definitive methodological caution for environmental economists. The core insight is valuable; ensuring the empirical proof matches the claim will maximize its impact.
