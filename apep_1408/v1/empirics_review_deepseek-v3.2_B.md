# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-04-07T22:28:14.736834

---

# Referee Report: "The Substitution Mirage: Voluntary Coca Eradication, Payment Windows, and Reversion in Colombia's Peace Zones"

## 1. Idea Fidelity

The paper deviates **significantly** from the original research plan. The **Original Idea Manifest** proposed to study how PNIS enrollment reallocated agricultural labor toward formal crops and reduced illegal agricultural employment. The primary data source was to be DANE's Encuesta Nacional Agropecuaria (ENA) panel, with agricultural wage bills and farm formality as key outcomes. The identification strategy centered on using pre-PNIS coca intensity as a quasi-instrument and a Callaway-Sant'Anna staggered DiD.

**This paper does not pursue that idea.** Instead, it investigates a related but distinct question: whether PNIS caused a lasting reduction in coca cultivation at the municipality level. The core data source is satellite coca detection data, not the ENA agricultural labor surveys. The outcomes are coca area and eradication events, not labor reallocation or formality. While the empirical strategy uses modern staggered DiD methods (Sun-Abraham, Callaway-Sant'Anna), it does not implement the proposed dose-response design using coca intensity as a continuous treatment, nor does it execute the planned matching or within-PDET comparisons. The paper is a well-executed analysis of PNIS's effect on coca cultivation, but it is not the study described in the manifest.

## 2. Summary

This paper provides the first causal, municipality-level evaluation of Colombia's PNIS voluntary coca substitution program. Using a panel of satellite coca detection data (2001–2023) and heterogeneity-robust difference-in-differences estimators, it finds that PNIS produced no aggregate lasting reduction in coca cultivation. The analysis reveals a dynamic "substitution mirage": a temporary reduction followed by a significant surge in coca area around two years post-enrollment, with effects reverting to zero by year four. The paper makes a valuable contribution by rigorously assessing a cornerstone policy of the 2016 Peace Accord and highlighting the challenges of transient payment schemes in altering deep-rooted illicit economies.

## 3. Essential Points

The authors must address these three critical issues to establish the paper's credibility and contribution:

1.  **Reconcile the Executed Study with the Proposed Research Agenda:** The disconnect between the proposed study of *labor reallocation* and the executed study of *coca cultivation* is a major issue. The paper must explicitly reframe its contribution. The introduction and abstract should clearly state that the research question is the effect of PNIS on coca cultivation levels, not labor markets. The authors should justify why this is a first-order question (which it is) and directly acknowledge the shift from the original plan, perhaps in a footnote or data/methods section. The current paper implicitly positions itself as a test of PNIS's core objective, which is valid, but this needs to be stated upfront and coherently.

2.  **Confront the Pre-Trends and Identification Challenge More Directly:** Figure 1 (the event study) shows clear positive pre-trends. The authors correctly note this likely reflects the "peace dividend" boom concentrated in future PNIS areas, making a finding of zero effect conservative. However, this significantly complicates identification. The parallel trends assumption in levels is violated. The authors should go beyond the Callaway-Sant'Anna pre-test (p=0.55) and the Rambachan-Roth sensitivity analysis. They should formally test for pre-trends in growth *rates* (not levels) and consider modeling strategies that account for these differential pre-existing trajectories, such as including municipality-specific linear time trends or using synthetic control methods for key municipalities/departments. The robustness of the "mirage" pattern (the spike at t+2) needs to be demonstrated net of these pre-trends.

3.  **Strengthen the Mechanism and Policy Discussion:** The paper documents a compelling pattern—compliance, surge, reversion—but the evidence for the proposed mechanisms ("payment-compliance cycle," "within-municipality displacement") is indirect. The authors must do more to probe and distinguish between these mechanisms. Can the eradication event data be disaggregated to see if voluntary eradication spiked in PNIS areas at t=0? Are there household survey or case study data to cite regarding replanting behavior? The policy discussion in Section 7 is good but should be more tightly integrated with the empirical results. For instance, the wave heterogeneity finding (Wave 1 showed marginal effects) directly supports the "implementation matters" point but is under-emphasized. The conclusion that "payment windows create compliance windows" is well-supported; the leap to what "would work" is more speculative and should be tempered or more explicitly linked to the heterogeneity results.

## 4. Suggestions

Below are constructive suggestions for improving the paper's analysis, presentation, and impact.

### A. Empirical Analysis & Robustness
*   **Explore Alternative Specifications for Pre-Trends:** In addition to your robustness checks, estimate your main model with municipality-specific linear or quadratic time trends. This is a demanding specification but would help account for the diverging pre-period paths. Similarly, report results from a stacked regression estimator, which can be more robust to heterogeneous treatment effects in the presence of non-parallel pre-trends.
*   **Deepen the Mechanism Analysis:**
    *   Use your linked eradication data more powerfully. Create an outcome variable for *voluntary* eradication hectares (if method codes allow) and test if PNIS caused an immediate spike. The discrepancy between TWFE and CS estimates for total eradication is fascinating; delve deeper into this. Does the "surge" in total eradication post-2018 coincide with the Duque policy shift? Plot national totals alongside your treatment coefficients.
    *   The "within-municipality displacement" story is plausible but untested. If data permits, examine the variance of coca cultivation within PNIS municipalities over time. A increase in variance post-treatment could be consistent with some households eradicating and others expanding. Alternatively, cite qualitative or journalistic evidence of this behavior.
    *   Interact treatment with baseline municipal characteristics beyond coca intensity (e.g., poverty rate, road density, presence of armed groups post-FARC) to explore heterogeneous effects that might inform mechanisms.
*   **Refine the Dose-Response Analysis:** The original idea proposed using pre-treatment coca intensity as a continuous measure. Your Figure 6 is a start, but consider a more formal analysis: instead of just plotting within PNIS municipalities, run a difference-in-differences model where "treatment intensity" is the continuous share of families enrolled or baseline coca per capita, interacting with post. This could speak to whether the program had more bite where it was more intensive.

### B. Presentation & Narrative
*   **Sharpen the Abstract and Introduction:** The abstract's final sentence is excellent. The introduction should mirror this clarity, immediately framing the paper as a test of PNIS's *core goal*: reducing coca cultivation. The "substitution mirage" is a strong framing device; use it consistently.
*   **Improve Graphical Communication:**
    *   Figure 1 (Event Study): Add a horizontal line at zero. Consider using a connected scatter plot for the point estimates to make the temporal pattern even clearer. The y-axis label should explicitly state "IHS(Coca Hectares)".
    *   Figure 2 (Raw Means): This figure is less informative given the large level differences. Consider replacing it with a plot of the *difference* in means (PNIS mean - Non-PNIS mean) over time, which would better visualize the divergence/convergence pattern.
    *   Figure 4 (Cohort Dynamics): Ensure the legend clearly defines Wave 1 vs. Wave 2. The narrative about implementation quality hinges on this figure; make it as clear as possible.
*   **Structure the Results Section:** The current flow jumps between estimators. Consider a clearer structure: First, present the main event study (Sun-Abraham). Second, show the aggregated ATT from Sun-Abraham, TWFE, and CS in a table, discussing their (dis)agreement. Third, present the heterogeneity by wave. Fourth, present the secondary outcome (eradication) and the puzzle of the estimator discrepancy. This would improve narrative coherence.

### C. Context and Contribution
*   **Clarify the Literature Contribution:** The literature review correctly notes the focus on forced eradication. You should more sharply contrast your null finding on *voluntary* substitution with the typical findings from the forced eradication literature (e.g., Mejía & Restrepo find effects but with displacement). Your contribution is not just "first causal evaluation" but also "shows that even a well-intentioned voluntary program failed to achieve its goal, highlighting the profound challenge of the coca economy."
*   **Expand the Discussion of Limitations:** The current limitations section is good. Add a point about measurement: satellite data may miss small, dispersed coca plots, especially if farmers get better at hiding them. Also, discuss the potential for spillovers: did PNIS in one municipality push coca cultivation into neighboring non-PNIS municipalities? A simple spatial spillover test (e.g., treating neighbors of PNIS municipalities as another group) could be informative.
*   **Policy Implications:** Connect your findings more directly to ongoing policy debates in Colombia. Your results provide empirical support for critics who argued PNIS was insufficient. Discuss what your analysis implies for the current policy mix of sporadic voluntary eradication and renewed forced eradication. Should payments be longer? Tied to land use titling? Integrated with PDET more closely? Your findings can inform these questions.

**Overall,** the paper has a strong empirical core, uses appropriate modern methods, and tackles a critically important policy question. Its main weakness is the misalignment with its original proposal, which can be corrected through reframing. With the revisions suggested above, particularly a more direct engagement with the pre-trends challenge and a deeper exploration of mechanisms, this paper can become a significant contribution to the literature on illicit crops and post-conflict development.
