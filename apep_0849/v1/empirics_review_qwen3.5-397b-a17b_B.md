# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-24T15:51:45.770874

---

1. **Idea Fidelity**

The paper largely adheres to the core conceptual framework outlined in the manifest: exploiting Taiwan's 2010 transition from sector-targeted to uniform R&D tax credits to evaluate innovation incentives. However, there are significant deviations from the specific identification strategy and data parameters established in the feasibility check. First, the data volume differs substantially; the manifest confirmed ~30,000 patent *applications* via BigQuery, whereas the paper claims ~190,000 utility *patents* (grants). Given that grants are a subset of applications, this six-fold increase requires explanation (e.g., inclusion of all assignees vs. inventors, or a broader definition of "Taiwan-based"). Second, the manifest highlighted examiner-level data (office actions, examiner leniency IV) as a key feasibility advantage for causal identification; the paper drops this entirely in favor of aggregate class-year counts. Third, the placebo countries shifted from Israel/Singapore (manifest) to Israel/South Korea (paper), and the pre-period extended back to 2003 (manifest: 2005). While the core research question remains intact, these deviations affect the reproducibility and the strength of the causal claim originally deemed "READY."

2. **Summary**

This paper investigates whether sector-targeted R&D tax credits are necessary to sustain innovation at the technology frontier, using Taiwan's 2010 policy shift as a natural experiment. Using a difference-in-differences design on USPTO patent data, the author finds that removing preferential credits for strategic sectors (like semiconductors) did not reduce patenting volume or quality, suggesting such subsidies may be inframarginal for frontier firms. The results contribute to the industrial policy debate by suggesting uniform credits may be as effective as targeted ones for mature industries.

3. **Essential Points**

1.  **Data Integrity and Definitions:** The discrepancy between the manifest's feasibility check (30,239 applications) and the paper's analysis sample (190,000 patents) is critical. If the manifest's BigQuery check was accurate for the relevant subset, the paper's sample size suggests a different population (e.g., including non-Taiwanese subsidiaries or all assignees). The author must reconcile these numbers to ensure the treatment group accurately reflects firms affected by the Taiwanese Industrial Innovation Act (IIA).
2.  **Missing Examiner-Level Identification:** The manifest explicitly identified examiner-level variation (leniency IV, office action severity) as a feasible and novel identification strategy to control for USPTO-side supply shocks. The paper drops this in favor of standard class-year aggregates. Given that USPTO examination rigor can vary over time and affect grant rates independently of tax policy, omitting the examiner dimension weakens the causal claim that the *policy* drove the change rather than examination trends.
3.  **Control Group Validity Post-GFC:** The paper uses 2003–2013, encompassing the Global Financial Crisis (GFC). Strategic sectors (semiconductors) are highly cyclical and may have recovered differently than non-strategic controls post-2009, independent of tax policy. The parallel trends assumption relies on non-strategic classes being a valid counterfactual for strategic classes during a global supply chain shock. The current controls may not adequately absorb differential cyclical recovery rates.

4. **Suggestions**

The following recommendations are intended to strengthen the paper's empirical rigor and alignment with the promising identification strategy outlined in the original proposal.

**Reconciling Data and Sample Construction**
The most pressing issue is the data discrepancy. The manifest's smoke test indicated ~30k applications, while the paper analyzes 190k patents.
*   **Clarify Unit of Analysis:** Explicitly state whether the unit is applications or grants. If grants, explain why the volume exceeds the manifest's application count (e.g., did the manifest restrict to specific art units?). If the 190k figure includes patents where Taiwan is merely one of multiple assignee locations, this may dilute the treatment effect, as foreign partners might not benefit from Taiwanese tax credits. Restricting to patents where the *primary* assignee is Taiwanese would sharpen the treatment definition.
*   **Verify Treatment Exposure:** The IIA affects Taiwanese tax liabilities. Ensure the sample excludes patents filed by Taiwanese firms' foreign subsidiaries (e.g., TSMC USA) that might not claim the Taiwanese R&D credit. A robustness check limiting the sample to patents with inventors located in Taiwan would help confirm the policy mechanism is actually binding on the observed units.

**Restoring Examiner-Level Variation**
The manifest identified examiner data as a key feasibility advantage. Re-incorporating this would significantly boost the paper's contribution to the *AER: Insights* audience, who value clean identification.
*   **Examiner Fixed Effects:** Even if not using the leniency IV, include examiner fixed effects (or art unit × year FE) to absorb supply-side variation in patent difficulty. If the same examiners are reviewing Taiwanese patents before and after 2010, examiner FE can control for changing rigor in specific technology classes (e.g., if semiconductor examination became easier in 2010 independently of tax policy).
*   **Office Action Analysis:** The manifest proposed using office action severity. Even a simplified version—such as the share of applications receiving a first-action rejection—could serve as a quality proxy. If tax credits were driving marginal low-quality patents, we might expect rejection rates to rise post-2010 even if volume stays constant. This would add nuance to the "null effect on quality" claim.

**Strengthening the Control Group and GFC Controls**
The 2008–2009 financial crisis complicates the pre-post comparison.
*   **Sector-Specific Trends:** Semiconductors are notoriously cyclical. Non-strategic controls (e.g., mechanical instruments) may not share the same cyclicality. Consider adding a global semiconductor demand index (e.g., semiconductor sales data) as a control variable to ensure the "recovery" in patenting isn't just the global tech cycle rebounding.
*   **Refined Control Group:** Instead of all non-strategic classes, consider a control group of technology classes that are similar in R&D intensity but were not SUI-designated. This reduces the risk that "strategic" classes are simply high-growth tech classes while "non-strategic" are low-growth legacy classes.
*   **Event Study Visualization:** The text mentions flat pre-trends, but the visual event study plot is not included in the provided text. Ensure the final manuscript includes the event study graph with confidence intervals. Given the G
