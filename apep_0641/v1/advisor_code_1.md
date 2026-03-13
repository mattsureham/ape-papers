# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-13T17:30:54.462276

---

**Idea Fidelity**

The paper largely follows the manifest. It exploits the staggered salary-history ban implementation across 16 states, leverages QWI data at state-industry-sex-quarter resolution, and implements a staggered DiD/DDD setup to assess gender pay compression and heterogeneity across industries and demographics. The key elements—the triple-difference comparing women to men across high-gap versus low-gap industries, the Callaway–Sant’Anna event-study, and the race heterogeneity (Doleac–Hansen-style) exercise—are present. The paper does not, however, engage directly with the county-level variation or policy permutation exercises flagged in the manifest, nor does it substantively use the full suite of outcomes (e.g., firm job creation, turnover) noted there; instead it focuses on state-level aggregates and earnings/hiring/separation rates. This omission should be acknowledged explicitly and, if feasible, rectified or justified.

---

**Summary**

The paper studies the causal effects of state salary-history bans on gender earnings gaps by exploiting staggered adoption across 16 U.S. states and using the QWI state-industry-sex-quarter panel. A triple-difference design reveals that bans compress the gender gap in industries where it was large before the ban but widen it where it was already small, which the author interprets through a statistical discrimination lens. Additional evidence on race-specific earnings and the absence of pre-trends supports the interpretation that removing salary-history information produces heterogeneous effects depending on prevailing industry priors.

---

**Essential Points**

1. **Interpretation of the Triple Difference and Potential Confounding:** The core identifying assumption is that the gender-gap trend differential between high-gap and low-gap industries is parallel across treated and never-treated states. Yet the paper does not show pre-trends for the interaction—or for the high-gap versus low-gap split separately—beyond vague references to flat Callaway–Sant’Anna estimates on the overall gender gap. Without showing that the triple-difference is not being driven by diverging trends within specific industries (e.g., finance in the Northeast versus wholesale in the Midwest), the results remain susceptible to confounding. Provide event-study plots for the interaction term (or otherwise demonstrate parallel trends for high-gap versus low-gap industry differences) and discuss alternative specifications (e.g., industry-specific leads) that address this concern.

2. **Role of Sample Composition and Industry Classification:** The 20% threshold for “high-gap” versus “low-gap” industries is central but under-explained. The results hinge on this binary split, yet the choice appears somewhat arbitrary and not subjected to sensitivity analyses. Clarify how robust the findings are to alternative thresholds (e.g., 15%, 25%) or alternative ways of ranking industries (e.g., imbalanced clustering). This also ties into selection: if high-gap industries are disproportionately concentrated in early adopters or in states with differential economic growth, the triple difference might pick up those patterns. Provide additional robustness checks (e.g., excluding states with idiosyncratic industry mixes, controlling for time-varying state-industry shocks) to ensure the DDD interpretation is valid.

3. **Mechanisms and External Validity of Statistical Discrimination Interpretation:** The paper attributes the negative effects in low-gap industries to statistical discrimination, but the empirical tests (race heterogeneity, null results for an untargeted group) are suggestive rather than conclusive. The narrative assumes that prior salary was a “positive signal” only in low-gap industries, but this is not directly tested. Can the authors show that within low-gap industries (but not high-gap ones) employer reliance on prior pay was higher pre-ban, or that employers’ observable priors (e.g., the female share of employment) aligned with the predicted direction? In the absence of such evidence, the statistical discrimination story remains under-motivated. Strengthen it with additional evidence on employer behavior or by connecting it more directly to observable industry traits.

If further issues are required beyond these three, the paper would carry a serious identification problem and should likely be rejected.

---

**Suggestions**

1. **Disaggregate Event Studies:** The paper currently reports a Callaway–Sant’Anna event study for the overall female-to-male earnings ratio, but the key heterogeneity emerges from comparing high-gap and low-gap industries. Plotting the event-study separately for high-gap and low-gap industries (or their difference) would allow readers to visually assess the validity of the triple-difference. If sample size prevents industry-level plots, aggregate industries into a small number of groups (e.g., top quartile vs bottom quartile by gap) and show the dynamic effects. This would also clarify whether the low-gap negative effect is concentrated around policy implementation or driven by specific states.

2. **Industry Definition Transparency:** Provide a table listing all 20 industries with their exact pre-ban gender gap, treatment classification (high or low), and sample weight. Mention whether industries that span multiple NAICS codes (e.g., 44-45 retail) were aggregated and how. Additionally, note why the 20% threshold was chosen (e.g., median gap, natural break) and, in the appendix, show results for alternative splits (including a continuous measure of the pre-ban gap interacted with treatment). This will reassure readers that the core finding is not threshold-dependent.

3. **Address Spillovers or Anticipation:** States that adopted bans may have experienced labor market adjustment before the law took effect (public debates, compliance planning). Discuss whether anticipation effects could bias estimates (e.g., early adopters may have already signaled compliance). The event-study can be extended to include leads beyond the pre-treatment periods to test for such anticipation. If leads are significant, consider shifting the effective treatment date or adjusting the specification.

4. **Robustness to Alternative Control Groups:** The main results rely on never-treated states as the control group. Provide robustness checks using alternative comparison groups, such as late adopters (using a stacked DID) or only geographically proximate states (e.g., within Census divisions). Relatedly, implement a border-county robustness check as mentioned in the manifest: compare treated counties to neighboring non-treated counties, which helps mitigate concerns about state-level confounders and better isolates local policy effects.

5. **Link Hire/Separation Results to Mechanism:** Columns (3) and (4) of Table 3 show small positive effects on hiring and separation in high-gap industries but are not fully interpreted. Discuss whether increased hiring is consistent with the removal of a search frictions barrier or a sign of sorting (women moving toward high-gap industries). Similarly, the separation rate increase could signal higher turnover due to job switching or dissatisfaction. Consider analyzing whether the hires/separations are concentrated in certain demographic groups or industries to make the narrative more concrete.

6. **Explore Heterogeneity Across Cohorts:** With seven implementation cohorts and a range of states, one could test whether earlier adopters (Delaware, Oregon) had different effects than later ones (Colorado, Rhode Island), perhaps due to complementarities in enforcement or labor market tightness. This could clarify whether results are driven by particular states or generalize across policy environments. If data permit, include a cohort-by-cohort figure or regression to check for such variation.

7. **Detail Data Aggregation Decisions:** The data appendix mentions aggregating county-level records to the state level. Explain the aggregation procedure (e.g., are counties weighted by employment? Are suppressed cells imputed?). Clarify whether any states are dropped due to sparse industries or confidentiality suppression, and how that might affect the comparability of treated and control units. If some industries are missing in certain states or quarters, describe how you deal with that missingness (e.g., sample restriction, interpolation).

8. **Quantify Aggregate Welfare Implications Carefully:** The discussion interprets the heterogeneous effects in terms of policy implications. To strengthen this, include an aggregate counterfactual (e.g., weighted average of high-gap and low-gap effects) to demonstrate whether the overall wage gap narrowed or widened. Also discuss whether the net effect depends on the sectoral employment share of women, making clear the limitations of translating the DDD results into welfare statements.

9. **Clarify Race Analysis Sample:** The race heterogeneity section is compelling but concise. Provide more details on the race sample (which racial groups are included, how race is measured, any missingness), the exact specification used (same DDD or separate DiD), and whether the pre-trends hold. Including a short table with ATT estimates for Black, Hispanic, and White workers would make this section more transparent.

10. **Supplement with Alternative Outcomes:** The paper highlights earnings and hiring/separation, but the manifest referenced job creation and turnover. If data are available, briefly explore those outcomes to see whether salary history bans affect firm-level dynamics, which could provide additional support for the barrier-removal vs. discrimination story. Even if results are null, reporting them would enrich the narrative.

11. **Discuss External Validity and Policy Implications:** The policy lesson is that the same intervention can have opposite effects depending on industry structure. Expand this discussion by noting which industries (in terms of employment shares or policy significance) fall into each category, and whether policymakers should combine salary history bans with other policies (e.g., mandated pay disclosures) in low-gap industries to avoid backfiring. Also, acknowledge any limitations from using state-level data (e.g., inability to observe firm-level compliance or actual salary-history usage).

12. **Ensure Reproducibility:** Given the immense QWI dataset, provide more detail on how the data were processed (e.g., code used, whether weighted by employment) so that future researchers can replicate the figures and tables. Mention whether the DuckDB scripts or processed data will be shared, and include references to the manifest’s Azure asset paths if possible.

Implementing these suggestions would make the paper’s identification strategy and empirical findings more transparent and persuasive while enhancing its contribution to the literature on salary history bans, statistical discrimination, and policy design.
