# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-04-09T14:38:57.554051

---

**Referee Report: “The Inspector Lottery That Isn't: Small-Sample Bias in Examiner Leniency Designs Applied to England's Planning Appeals”**

**1. Idea Fidelity**
The paper significantly deviates from the original, ambitious research plan outlined in the Idea Manifest. The manifest proposed a full-scale instrumental variables (IV) analysis to estimate the causal effect of planning appeal decisions on **local housing supply, property prices, and development activity**. The identification strategy was centered on using inspector leniency as an instrument for appeal success, with the ultimate goal of informing high-stakes housing policy.

The submitted paper, however, abandons this primary research question. Instead, it becomes a methodological cautionary tale about the failure of the leniency instrument in a small sample. While it uses the same data source (PINS portal) and constructs the proposed instrument, it does not proceed to the second-stage housing outcomes. The core contribution shifts from estimating a policy-relevant causal parameter to demonstrating a statistical problem (small-sample bias/mean reversion). The paper is therefore a partial execution—it tests the first stage of the proposed design but does not pursue the original economic question.

**2. Summary**
This paper constructs a novel dataset of English planning appeals and extracts inspector identities from decision letters. It attempts to implement an examiner leniency IV but finds a negative and weak first stage, which it attributes to small-sample bias because inspectors handle too few cases in the sample. The paper’s key contribution is a practical demonstration of the data requirements necessary for credible examiner designs, rather than an estimate of how appeal outcomes affect housing supply.

**3. Essential Points**
The following critical issues must be addressed for the paper to be considered for publication:

**1. Fundamental Mismatch Between Stated and Executed Research Contribution.**
The introduction and abstract frame the paper as a contribution to understanding housing supply constraints (“Why this matters for housing”). Yet, the analysis stops at the first stage of the IV. The paper does not deliver on its promised policy relevance. The authors must either:
*   **Substantially reframe** the paper as a purely methodological contribution, explicitly stating that the original housing question cannot be answered with the current data and focusing entirely on the lessons for examiner designs, or;
*   **Execute the original design** by scaling data collection to the full population (~100,000 cases, as noted in the manifest) to achieve a credible first stage and then estimate the second-stage effects on housing outcomes (completions, prices). The current sample of 860 cases is acknowledged as insufficient; the manifest itself outlined a feasible path to the full data.

**2. Claims of External Validity and Policy Relevance Are Unsupported.**
The conclusion claims the setting “is promising for future work” and that the “ ‘inspector lottery’ is real,” suggesting policy implications for inspector capacity and decision consistency. These claims are not supported by the presented evidence. The documented negative first stage and flat monotonicity pattern do not demonstrate a real-world “lottery”; they demonstrate statistical noise. The positive “lagged leniency” result is suggestive but presented only in the text without a corresponding table or rigorous test against alternative explanations (e.g., time-varying case composition). To make credible claims about inspector heterogeneity, the authors must provide robust, within-cell evidence of persistent styles using a sufficiently large sample.

**3. Inadequate Discussion of Alternative Explanations for First-Stage Failure.**
The paper attributes the negative first stage solely to small-sample mean reversion. While plausible, this is not rigorously distinguished from other institutional explanations that could violate the exclusion restriction or monotonicity. For instance:
*   **Strategic Assignment:** The balance tests on *observed* characteristics are reassuring but not definitive. Could PINS assign tougher cases (e.g., those against stronger local plans) to more lenient inspectors in an attempt to *balance* outcomes? This would induce a negative causal link between true leniency and the current case’s outcome.
*   **Case Complexity & Specialization:** The cell definitions (case type × year) may be too coarse. If inspectors specialize in complex sub-types within “Planning Appeals” and complexity predicts dismissal, residual correlation could be negative.
The paper needs a more thorough discussion that rules out these alternatives with institutional knowledge and robustness checks (e.g., testing for assignment correlates using the full set of inspector credentials extracted from PDFs).

**4. Suggestions**
*   **Reframe the Paper:** The most coherent path may be to recast the paper as “The Minimum Data Requirements for Examiner Designs: A Case Study from England’s Planning Inspectorate.” The title, abstract, and introduction should be rewritten to foreground the methodological contribution. The housing context becomes the motivating example rather than the primary subject.
*   **Deepen the Methodological Analysis:**
    *   Conduct a formal simulation or derive the theoretical bias of the leave-one-out estimator under a DGP with a true positive effect but few cases per examiner. Quantify the “minimum N per examiner” needed in this context.
    *   Compare alternative instrument constructions beyond leave-one-out (LOO), such as a “split-sample” approach where leniency is estimated on a randomly selected half of each inspector’s cases. Does this mitigate the mean reversion?
    *   Present the “lagged leniency” results in a main table with full regression output, standard errors, and a discussion of its validity as a measure of persistent style.
*   **Improve Data Presentation & Transparency:**
    *   **Table 1 (Summary Stats):** Distinguish between the full scraped sample (2,227 cases), the sample with inspector IDs (1,625), and the analysis sample (860). Show how allow rates and case composition change at each step to assess selection.
    *   **Table 2 (First Stage):** The current panel B is not a balance test *within cells*. Run and report regressions of the leniency score `Z` on case characteristics (filing lag, householder indicator), conditional on the full set of fixed effects used in the first stage. This tests quasi-random assignment directly.
    *   **Data Availability:** Commit to publishing the replication code and the constructed dataset of inspector-case linkages, as this is a valuable secondary contribution.
*   **Strengthen the Institutional Details:**
    *   Provide a citation or official documentation for the claim that assignment is “workload-based” and nationally pooled. A footnote from a PINS procedural guide would suffice.
    *   Discuss the potential for appellant learning or selection. If developers can predict inspector tendencies over time (via lagged leniency), might they adjust their appeal submissions? This could affect the interpretation of both the failed LOO instrument and the lagged measure.
*   **Clarity and Precision:**
    *   The abstract states “I construct a novel case-level dataset of 2,227 English planning appeals decided by 720 inspectors,” but the analysis uses 860 cases and 198 inspectors. Clarify this discrepancy.
    *   In Section 4 (Design), formally state the exclusion restriction and monotonicity assumption for the *intended* IV, and discuss how their potential violation relates to the observed first-stage failure.
    *   **Appendix Table:** The current appendix table appears to contain repeated rows. It should be corrected and could be better used to show the monotonicity pattern (allow rate by leniency quintile) or the lagged leniency results.

**Overall Assessment:** The paper identifies a real and important practical problem in a novel setting. However, in its current form, it is an incomplete research note. It successfully demonstrates a problem but does not complete the proposed economic analysis or fully mature into a self-contained methodological contribution. The authors have a clear choice: significantly scale the data effort to pursue the original, impactful question, or pivot decisively to a sharp methodological paper with a more limited scope. I lean towards recommending the latter as a more feasible revision, provided the analysis is deepened as suggested above.
