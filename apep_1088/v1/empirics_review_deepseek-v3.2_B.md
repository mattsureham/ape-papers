# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-27T17:58:53.381089

---

**Referee Report:** *No Ceiling in Sight: Testing Whether IRS Disclosure Thresholds Constrain Nonprofit Growth*

**1. Idea Fidelity**
The paper significantly deviates from the original research idea outlined in the manifest. The core intent was to exploit the *2010 threshold reform* as a natural experiment. The identification strategy was to compare the *post-2010 growth trajectories of pre-reform "bunchers" below $100k* (the treated, whose incentive to suppress revenue was removed) to the trajectories of organizations that were in the $100k-$200k range pre-reform and filed the full Form 990 without avoidance (the control). This is a clean, dynamic test of whether the *old* disclosure requirement constrained growth.

The submitted paper abandons this strategy. Instead, it analyzes the *new* $200,000 threshold post-2010, looking for static bunching and conducting a DiD comparing organizations "near" the new threshold to mid-sized controls. This shifts the research question from "Did the *removal* of a disclosure requirement unleash growth?" to "Does the *existence* of a disclosure requirement constrain growth?" While related, these are distinct questions requiring different empirical designs. The paper's current design lacks a clear, policy-driven source of variation in treatment intensity; the "constrained" vs. "control" groups are defined by static revenue bands, not by their behavioral response to a policy change. Consequently, the paper misses the key element of the original identification strategy, which was the central strength of the proposed idea.

**2. Summary**
This paper tests the "compliance ceiling" hypothesis by examining whether the IRS Form 990 filing threshold at $200,000 causes nonprofits to suppress revenue growth to avoid more burdensome disclosure. Using a panel of nonprofits from 2011-2022, it finds no statistically significant evidence of bunching at the threshold and null effects on revenue growth in difference-in-differences and event-study analyses. The authors conclude that, at this margin, disclosure costs are not large enough to distort organizational growth.

**3. Essential Points**
The following critical issues must be addressed for the paper to make a credible causal contribution.

**3.1. Flawed and Underpowered Identification Strategy.** The empirical design does not adequately identify a causal effect. The DiD specification (Equation 1) compares organizations with baseline revenue of $170k-$220k to those with $120k-$160k, labeling the former "constrained" and the latter "control." This assignment is not based on a clear, exogenous change in treatment status. The parallel trends assumption is particularly dubious: organizations on a growth path to cross $200k are inherently different from those stable in the mid-range. The event study in Table 3 shows noisy pre-trends but does not convincingly validate this assumption. The analysis essentially compares different-sized organizations, conflating lifecycle growth differences with threshold effects. The original idea's design—exploiting the 2010 reform's removal of an incentive for a specific set of bunchers—was a more credible approach to causality.

**3.2. Sample Size and Power Are Insufficient for a Null Result.** The analysis sample of 1,396 organizations, with only ~200 in the primary "treated" group (near $200k), is too small to draw definitive null conclusions. The confidence intervals are wide (e.g., the DiD coefficient on log revenue is -0.040 with a 95% CI of [-0.164, 0.085]). The authors cannot rule out economically meaningful negative effects (e.g., a 10-15% suppression of revenue). A persuasive null finding requires demonstrating high statistical power to detect a plausible effect size. The paper should include a power calculation based on the minimum effect size of policy interest (e.g., a 5% or 10% growth suppression) to contextualize its inability to reject the null.

**3.3. Inadequate Exploration of Mechanisms and Heterogeneity.** The paper cursorily dismisses potential mechanisms (compliance cost, technological change, disclosure aversion) without testing them. If the goal is to understand *why* no effect is found, these mechanisms should be investigated empirically. For example:
*   **Compliance Cost:** Can the incremental cost of Form 990 vs. 990-EZ be quantified (e.g., via surveys of tax preparers)? Does the null result hold for subgroups where this cost might be a larger share of budgets (e.g., all-volunteer organizations)?
*   **Technology:** Is the null driven by organizations filing electronically? A test comparing effects before and after the widespread adoption of e-filing (circa 2016) could be informative.
*   **Disclosure Aversion:** The test of the revenue-expense gap is a good start, but more direct tests are needed. Do organizations near the threshold show different patterns in the specific items that become disclosable (e.g., officer compensation, related-party transactions)?

**4. Suggestions**
*Note: The following suggestions presume the authors wish to salvage the current research question (effect of the $200k threshold). A more fundamental and recommended revision would be to re-orient the paper to execute the original, more causal idea from the manifest.*

**4.1. Revise the Empirical Design to Improve Causal Credibility.**
*   **Adopt a Regression Discontinuity (RD) Framework:** The cleanest test of the $200k threshold's effect is a sharp RD design, comparing organizations just below vs. just above the threshold in a given year, while controlling flexibly for the running variable (revenue). This is more robust than the current DiD as it relies on a local continuity assumption rather than parallel trends across heterogeneous groups. The bunching analysis is a related but distinct test; an RD would directly estimate the effect of crossing the threshold on future growth.
*   **Refine the DiD, If Retained:** Define treatment more dynamically. Consider an "at risk" cohort design: track organizations that are, for example, between $150k and $190k in year *t*, and compare the future growth of those that cross $200k by *t+1* (and thus become treated) to those that do not. Use propensity score matching to balance the two groups on pre-period characteristics. This better approximates a treatment defined by crossing the threshold.
*   **Leverage the 2010 Reform for the $200k Analysis:** The paper mentions the reform but does not use it to study the *new* threshold. The creation of the $200k threshold in 2010 itself was a policy shock. A possible DiD could compare organizations just above and below $200k *after* 2010 to organizations around a placebo threshold (e.g., $300k) before and after 2010. This would use the reform's introduction as the source of variation.

**4.2. Expand Data and Analysis to Bolster Power and Robustness.**
*   **Drastically Increase Sample Size:** The ProPublica data covers millions of filings. There is no justification for analyzing only 1,396 organizations. The sample should encompass the full universe or a very large random sample of organizations in the relevant revenue ranges ($50k-$500k) over the 2005-2022 period (to include pre-reform years for context). This will provide the power necessary for precise null estimates and credible subgroup analyses.
*   **Conduct a Comprehensive Power Analysis:** Prior to presenting results, report ex-ante power calculations. What is the minimum detectable effect (MDE) given the sample size and variance? Is the study powered to detect the effect sizes suggested by prior literature or that would be meaningful to policymakers?
*   **Add Robustness Checks:** The paper needs a battery of robustness tests: varying bandwidths for the "near threshold" definitions, using different polynomial orders in the bunching estimator, employing alternative clustering for standard errors (e.g., state-year), controlling for time-varying covariates (NTEE sector trends, state economic conditions), and using winsorized instead of trimmed outliers.

**4.3. Deepen the Discussion of Mechanisms and Context.**
*   **Quantify Compliance Costs:** The discussion of costs being "trivial" is speculative. Integrate evidence. Cite or conduct a simple analysis of tax preparer fees for Form 990 vs. 990-EZ. Relate this cost to the average budget of a $200k organization.
*   **Test for Heterogeneous Effects:** The null average effect may mask opposing effects for different types of organizations. Test for heterogeneity by:
    *   **Organizational capacity:** Organizations with high vs. low assets, or with vs. without paid staff.
    *   **Sector:** Arts organizations might be more sensitive to disclosure of donor lists than food banks.
    *   **Governance:** Organizations with high insider compensation might be more averse to the full 990's Schedule J.
*   **Discuss the $100k Threshold Literature:** Engage directly with papers that *did* find bunching at the pre-2010 $100k threshold. Why might the $200k threshold be different? Is it solely scale, or did e-filing and software truly change the cost structure? This historical contrast is a key part of the story.

**4.4. Improve Presentation and Narrative.**
*   **Clarify the Research Question:** The introduction should clearly state whether the paper is testing the effect of the threshold's *existence* or the *removal* of an earlier threshold. The current text is ambiguous.
*   **Visualize Key Results:** The bunching results in Table 1 need to be accompanied by the standard bunching figure—a histogram of the revenue distribution with the polynomial counterfactual overlaid. The event study results in Table 3 should be presented as a coefficient plot with confidence intervals over time.
*   **Reconcile with the Original Idea:** In the introduction or a discussion section, briefly acknowledge the original planned design and justify the methodological pivot, explaining why the current design is preferred or necessary. This demonstrates scholarly reflexivity.
*   **Policy Implications:** Expand the discussion on threshold design. If costs are trivial at $200k, should the threshold be raised higher to reduce compliance for more organizations? Or does the lack of bunching suggest that disclosure itself, not the preparation cost, is the salient factor for regulators?

**Overall,** the paper addresses an interesting and policy-relevant question but falls short in its execution. The causal evidence is weak, the null result is underpowered, and the analysis lacks depth. By fundamentally revising the identification strategy, significantly expanding the data and power, and rigorously testing mechanisms, the authors could produce a much stronger contribution. As it stands, the paper is not yet ready for publication but has a clear pathway for major revision.
