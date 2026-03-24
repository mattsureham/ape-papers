# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant A)

**Model:** deepseek/deepseek-v3.2
**Variant:** A
**Date:** 2026-03-23T13:29:10.831056

---

**Review of “The Complementarity Dividend: Quarterly Evidence on How H-1B Restrictions Hurt Native Workers”**

**1. Idea Fidelity**

The paper partially pursues the original idea outlined in the “Idea Manifest” but deviates in several key respects, resulting in a mismatch between the proposed research question and the executed empirical analysis.

*   **Research Question Shift:** The manifest explicitly focuses on measuring **“HOW FAST native workers... adjust”** to H-1B supply shocks, with novelty claimed from using **“QWI QUARTERLY frequency”** to trace **“adjustment quarter by quarter.”** The submitted paper, however, is primarily a study of the **level effect** (the sign and magnitude of the impact) on native worker outcomes, with the quarterly aspect relegated to a secondary, underdeveloped role. The title change from “Quarterly Anatomy of H-1B Restrictions” to “The Complementarity Dividend” signals this shift from dynamics to a static test of the complementarity hypothesis.
*   **Identification Strategy:** The manifest’s proposed “Shift-Share DID with Quarterly Dynamics” is implemented in the paper. However, the core DDD specification uses a single `Post` dummy, which averages effects over a long post-period (2003Q4–2012Q4). This obscures the very quarterly dynamics the original idea aimed to illuminate. While an event-study is presented, it is only for the employment outcome and its results (showing a temporary *positive* blip) are not reconciled with the main negative earnings finding.
*   **Data & Outcomes:** The paper correctly uses the QWI data at the described granularity. However, it does not fully exploit the data’s potential to answer the “how fast” question. The analysis of hires (`HirA`, `HirN`) and separations (`Sep`) is cursory and not integrated into a coherent narrative about the sequence and speed of adjustment.
*   **Conclusion:** The paper fails to deliver on its originally promised contribution: providing the **first evidence on adjustment speed** using quarterly data. Instead, it provides another (albeit well-identified) piece of evidence on the level effect, leaning into the complementarity vs. substitution debate. This is a valuable contribution, but it is not the one promised.

**2. Summary**

This paper exploits the 2004 H-1B cap reduction as a natural experiment to estimate the effect of skilled immigration restrictions on native workers. Using a triple-difference design with quarterly, county-level data, it finds that the cap cut reduced quarterly earnings and separations for young native workers in professional services within counties more exposed to the shock. The author interprets these results as evidence for complementarity between skilled immigrants and natives.

**3. Essential Points**

The following critical issues must be addressed for the paper to be suitable for publication.

**1. The empirical analysis does not match the core research question of adjustment speed.** The paper’s main specification collapses the post-treatment period into a single `Post` dummy, which estimates an average treatment effect over nearly a decade. This entirely forfeits the claimed contribution of using **quarterly** data to measure **speed**. The event-study in Table 3 is a start but is incomplete and puzzling. It shows only the employment outcome, which the main results find to be imprecisely estimated. Where are the event-study dynamics for earnings and separations—the outcomes with significant results? The positive employment blip around `t+2` and the subsequent reversion to zero require explanation. Do earnings show a similar delayed response and persistence? The paper must recenter its analysis on dynamic specifications (e.g., distributed lag models, cumulative effect plots) to credibly answer “how fast” adjustment occurs.

**2. The mechanism linking H-1B restrictions to negative native earnings is under-theorized and potentially inconsistent with the results.** The paper argues for a “complementarity dividend,” implying that restricting H-1B visas reduces native worker productivity. However, the observed reduction in *separations* is difficult to square with a standard negative productivity shock, which typically increases separations (layoffs/quits). The author offers a “hoarding” explanation, but this is speculative and not derived from a clear model. Could the results instead reflect a *reduction in labor demand* in high-tech counties post-2004? If firms could not hire complementary H-1B workers, they may have scaled back hiring (*HirA* is negative) and investment, reducing labor demand and putting downward pressure on wages and turnover. The paper must more rigorously develop and test the proposed mechanism, perhaps by linking to firm-level outcomes (e.g., investment, patenting) or distinguishing between quits and layoffs in separations data if available.

**3. The identification strategy is vulnerable to confounding from the 2008 financial crisis and its heterogeneous impact.** The post-period extends deep into the Great Recession (2007Q4–2009Q2). The crisis disproportionately affected finance and professional services and likely had a larger impact on younger, less-experienced workers. If high-tech counties were also more financially integrated or had different crisis exposure, this could bias the DDD estimates. The paper includes state-by-quarter fixed effects, but this only controls for state-level business cycles, not for county-level heterogeneity in crisis severity correlated with pre-2004 tech intensity. The author must either (a) shorten the sample period to end in 2007Q3 (before the crisis) to ensure a clean post-period, or (b) conduct a robust placebo test using the 2008 crisis as a fake treatment for a period *before* the H-1B shock, or (c) explicitly control for time-varying county-level shocks (e.g., using Bartik-style instruments).

**4. Suggestions**

*   **Reframe the Paper:** The most coherent path is to fully embrace the original idea. Retitle the paper to focus on “dynamics” or “adjustment speed.” Rewrite the introduction and abstract to highlight the quarterly innovation and the policy relevance of the *timing* of effects (e.g., “If adjustment is complete within four quarters, short-run costs are minimal…”).
*   **Expand Dynamic Analysis:**
    *   Present full event-study graphs for **all key outcomes** (Earnings, Sep, HirA, Emp) with 95% confidence intervals. Discuss the pattern: Do earnings effects appear immediately or with a lag? Do separations fall before or after earnings decline?
    *   Estimate **cumulative effect** functions to show the total impact over time.
    *   Report **half-life of adjustment** or test for the quarter when effects stabilize.
    *   Consider a more flexible distributed lag model instead of the binary `Post` dummy for the main results.
*   **Strengthen Mechanism Tests:**
    *   **Sectoral Reallocation:** The industry heterogeneity table (Table 4) is promising but crude. A more convincing test would be a **worker flow analysis**. Using QWI, can you show that separations from NAICS 54 in high-tech counties lead to hires in NAICS 62 (Healthcare)? Construct a county-level “reallocation rate.”
    *   **Task-Based Framework:** If complementarity is task-based (Peri and Sparber, 2009), can you find proxies for “communication-intensive” vs. “technical” task intensity at the industry-occupation level (using O*NET) and show that effects are stronger for natives in communication-intensive roles?
    *   **Interpret Separations:** Decompose separations into quits and layoffs if the data permits. A complementarity shock might reduce *quits* (fewer outside options), while a demand shock might increase *layoffs*.
*   **Address Robustness and Validity More Thoroughly:**
    *   **Pre-Trends:** The event-study shows concerning pre-trends at `t-8` and `t-7`. Argue why these are not a threat (e.g., dot-com bust effects that stabilized by 2003). Consider a more formal test, like estimating a linear pre-trend and showing it is insignificant.
    *   **Placebo Tests:** The placebo on Mining is good. Extend this by running the DDD on all non-H-1B-intensive sectors (e.g., a “pooled placebo” sector) and showing the distribution of coefficients centers on zero.
    *   **Alternative Specifications:** Test if results are robust to (1) using MSA instead of county, (2) using a Bartik shift-share instrument based on national H-1B growth and initial local industry composition, (3) clustering at the county or MSA level (46 state clusters may be too few).
    *   **2008 Crisis:** As stated in Essential Point 3, this is a major threat. The most straightforward solution is to **end the sample in 2007Q3**. This sacrifices statistical power but ensures identification clarity. If you keep the full sample, you must add an explicit analysis of crisis confounding.
*   **Improve Presentation and Narrative:**
    *   **Abstract:** The abstract overstates the precision of the employment result (“directionally negative but imprecise” is more accurate than “lowered employment”).
    *   **Theory Section:** Add a simple conceptual framework diagramming the potential channels (complementarity vs. labor demand) and their predicted effects on earnings, hires, and separations.
    *   **Results Flow:** Reorganize Section 5 to lead with the dynamic event-study results, then present the static DDD as a summary measure. The current order buries the novel dynamics.
    *   **Standardized Effects:** The SDE table in the appendix is useful. Integrate a discussion of economic magnitude into the main text. A 4.1 log-point earnings effect per unit of tech share is difficult to interpret. Convert it to a more intuitive metric: e.g., “Moving from a county at the 25th percentile of tech share to the 75th percentile is associated with a X% reduction in relative earnings growth for young workers.”
*   **Minor Points:**
    *   The “Binary” robustness check in Table 5 is uninformative as presented. A binary (Q4 vs. Q1) specification loses substantial variation. Consider instead a continuous treatment winsorized or in deciles.
    *   The note for Column 3 in Table 5 (“the triple interaction is absorbed by fixed effects”) is unclear. Does the model not converge, or is the coefficient literally zero? Explain.
    *   The literature review could more directly engage with the specific papers mentioned in the manifest (Doran et al. 2022 QJE, Peri et al. 2015) and clarify how this paper’s quarterly, county-level approach adds to them.
    *   Ensure all variables (e.g., `TechShare`) are clearly defined in the text, not just in table notes.

**Overall Assessment:** The paper has a strong and credible identification strategy at its core, leveraging a clear policy shock and rich data. However, in its current form, it does not fulfill its proposed contribution of elucidating *quarterly adjustment dynamics*. The authors have the necessary data and design to do this. By refocusing the paper on dynamics, rigorously addressing the mechanism and the 2008 crisis confound, and improving the analysis and narrative as suggested, this could become a compelling and novel contribution. In its present state, it is a well-executed but incremental study that misses its most innovative angle. **Major revisions are required.**
