# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-27T05:00:52.852104

---

**Review of "The Phantom Pollution Drop: How TRI Reporting Rule Changes Manufacture Apparent Emissions Declines"**

**1. Idea Fidelity**

The paper does **not** fully pursue the original idea outlined in the manifest. While it correctly identifies the core problem—reporting rule changes contaminate TRI trends—it executes a severely limited version of the proposed research design.

*   **Identification Strategy:** The manifest proposed a **stacked staggered Difference-in-Differences (CS-DiD)** design across **five distinct reporting rule changes** (1998, 1999/2001, 2014, 2020). This paper, however, analyzes only the **1998 sector expansion** and employs a simple pre/post accounting decomposition and a within-facility comparison of reporting intensity. This is not a credible causal DiD. The "control group" (continuous manufacturers) is used only to establish a counterfactual trend via extrapolation, not in a formal, estimable DiD model that compares *changes* in outcomes between treated and control units.
*   **Data Source:** The paper uses TRI data correctly but ignores the **ambient air quality monitor (AQS) data** specified in the manifest for independent validation. This validation was a key component for distinguishing measurement artifact from real emission changes.
*   **Research Question:** The paper addresses a narrower question: *Did the 1998 expansion mechanically increase reported forms?* It does not provide the broader "correction factors" or "measurement elasticity" for multiple rule changes that the manifest promised, nor does it fully deliver on the promise of quantifying bias for the wider literature.

**2. Summary**

This paper highlights a critical measurement issue: the 1998 expansion of the Toxics Release Inventory (TRI) to seven new sectors caused a sharp, mechanical increase in reported pollution forms. Using simple accounting and within-facility comparisons, it shows this "extensive margin" artifact accounts for a significant share of the reversal in aggregate TRI trends post-1998. The core insight—that administrative data trends can be driven by reporting rules—is important and underscrutinized.

**3. Essential Points (Must Address for R&R)**

The following issues are fundamental and must be convincingly resolved for the paper to be publishable.

1.  **Lack of a Causal Identification Strategy:** The current empirical approach is descriptive accounting, not causal inference. The claim that the observed jump is *caused by* the reporting rule change rests on a visual coincidence and a trend extrapolation. To credibly estimate the causal effect of the rule change, the authors must implement the **stacked DiD design** originally proposed. This requires:
    *   Defining clear treatment and control groups for the 1998 shock (e.g., facilities in newly added sectors vs. observably similar manufacturing facilities not near sector thresholds).
    *   Estimating a two-way fixed effects model: `Y_{ft} = β*(Post_t * Treat_f) + α_f + γ_t + ε_{ft}`, where `Y` could be an indicator for reporting, log(number of forms), or log(releases).
    *   Demonstrating parallel pre-trends. The event-study plot for this specification is the minimal necessary evidence for a causal claim.

2.  **No Validation Against Actual Emissions:** The paper's entire argument is that reported data changed without a change in real emissions. Yet, it provides **no direct evidence** on real emissions. The manifest correctly specified the use of ambient monitor data (EPA AQS) as a validation tool. The authors must:
    *   Link TRI facilities to nearby ambient monitors (e.g., within 1km, 5km).
    *   Test whether the *reported* air releases from newly treated facilities jump in 1998, while the *ambient concentrations* of corresponding pollutants measured at nearby monitors do not. This is the smoking gun for a pure measurement artifact. Without this, the paper remains a compelling correlation but cannot rule out that the rule change coincided with real emission increases in the new sectors.

3.  **Failure to Engage the Full Scope of the Problem:** By focusing solely on 1998, the paper dramatically undersells its contribution and misses the systematic nature of the problem. The abstract, introduction, and discussion imply a general critique of TRI-based research, but the analysis covers only one of several major rule changes. The authors must either:
    *   **Expand the analysis** to at least one other major rule change (e.g., the PBT threshold reductions or PFAS addition) using a credible DiD strategy, demonstrating the generalizability of the measurement artifact.
    *   **Tone down the broader claims** significantly, reframing the paper as a focused case study on the 1998 expansion and its implications for studies spanning that specific year.

**4. Suggestions**

*   **Strengthen the Literature Review and Motivation:** The policy impact is huge. More precisely quantify the problem: Conduct a systematic review or survey of prominent papers in top journals (AER, QJE, JPE, REStat, JEEM) that use TRI data across the 1998 threshold. Briefly summarize their research questions and show how their design could be biased by the extensive margin effect you document. This makes the stakes concrete.
*   **Improve the Descriptive/Accounting Analysis:**
    *   In the decomposition table (Table 2), calculate the new-entrant share not just of *forms* but of total *release quantities* (pounds). This is the outcome most used in the literature. Does the 17-27% form share translate to a similar share of pounds, or are new sectors disproportionately large/small emitters?
    *   Graph the raw data effectively. A figure showing national aggregate forms from 1987-2006, with vertical lines at each rule change (1998, 1999, 2001, etc.), would visually argue for the general problem.
*   **Deepen the Discussion of Implications:**
    *   Provide specific, actionable guidance. What should researchers do? Options include: (a) restricting samples to continuous reporters, (b) including cohort-by-year fixed effects, (c) using release *intensity* (per employee, per output) rather than totals, (d) using ambient data for validation. Discuss the pros/cons of each.
    *   Differentiate between types of bias. For studies of *national* trends, the bias is clear. For studies exploiting *cross-sectional* or *geographic* variation (e.g., environmental justice), the bias depends on whether the rule changes affected regions differentially. Explore this heterogeneity briefly.
*   **Technical Execution:**
    *   The "within-facility verification" is weak. A simple mean difference from 1995 to 1997 is not a robustness check for a 1998 treatment. Use the DiD framework suggested above.
    *   The "heterogeneity" analysis by state reporting intensity is unconvincing and adds little. Replace it with a more meaningful test: e.g., heterogeneity by the predicted propensity of a manufacturing facility to be "similar" to the new sectors.
    *   Ensure the facility-level analysis uses the correct unit of observation. The summary statistics table (Table 1) seems to confuse facilities and forms.
*   **Structure and Narrative:**
    *   The current title and abstract promise more than the paper delivers. Consider a more accurate title, e.g., "The 1998 TRI Expansion and the Measurement of Pollution Trends" until the analysis is broadened.
    *   The paper is short. There is ample room to add the required DiD analysis, validation, and a more nuanced discussion without exceeding journal length limits.

**Overall Assessment:** The paper identifies a very important and plausibly underappreciated problem. In its current form, it is a compelling research note but not yet a complete empirical study suitable for AER: Insights. The **Essential Points** are not minor; they go to the heart of the paper's credibility and contribution. If the authors can implement a credible stacked DiD for the 1998 change (Point 1), provide validation with ambient data (Point 2), and extend the analysis to at least one other rule change (Point 3), the paper would make a significant methodological contribution. Without these additions, the findings remain suggestive but inadequately supported for the claims made.
