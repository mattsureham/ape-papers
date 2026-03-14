# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-14T19:21:38.945314

---

**Idea Fidelity**

The paper largely follows the original manifesto. It focuses on the 75% Housing Delivery Test threshold, uses annual HDT rounds, and links them to DLUHC PS2 planning statistics to study approval rates through a regression discontinuity framework. The manuscript reports both non-parametric (rdrobust) and parametric estimates, addresses manipulation via McCrary, and deploys placebo outcomes and cutoffs as described. That said, the implementation diverges in two notable ways: (1) the analysis is restricted to four HDT rounds (2020–2023) rather than the six rounds noted as feasible in the manifest, and (2) housing starts, which were mentioned as an outcome of interest, do not appear in the empirical results. The focus is therefore narrowed to approval rates, missing the originally stated ambition to connect to housing starts. These missing pieces should be acknowledged and, if data limitations justify them, briefly explained in the paper.

---

**Summary**

The paper exploits the 75% HDT threshold as a sharp regression discontinuity to estimate the causal impact of the “presumption in favour of sustainable development” on planning approval rates for major dwelling applications. Using four HDT rounds (2020–2023) and quarterly planning statistics, it finds a point estimate of an 8–10 percentage point increase in major dwelling approval rates for councils below the threshold, with no similar discontinuity in householder applications or placebo cutoffs. Robustness checks include bandwidth variation, donut specifications, and year-by-year estimates.

---

**Essential Points**

1. **Clarify Interpretation and Statistical Precision.** The main non-parametric estimate is statistically insignificant (p=0.16) yet the discussion emphasizes the “real” effect. The paper should carefully qualify claims to avoid overstating results and clarify the implications of imprecision. Consider presenting both the bias-corrected RDD with optimal bandwidth and the parametric version as complementary evidence, while clearly explaining the inferential uncertainty.

2. **Explain Sample Restriction and Treatment Timing.** The manuscript omits the 2018–2019 HDT rounds and does not explicitly state why housing starts were dropped from the empirical analysis. Please justify the sample restriction to 2020–2023 (e.g., because the 75% presumption was not in force earlier) and explain why earlier rounds are excluded. Similarly, provide clarity on why housing starts cannot be estimated: is data unavailable, or is the causal link too distal? Transparency on deviations from the original scope strengthens credibility.

3. **Address Potential Sorting Due to Consequences Beyond the Presumption.** While the presumption is the sharp policy change at 75%, HDT also triggers buffers and action plans at higher thresholds. These consequences could differ for LAs just above 75% versus further above, potentially confounding the RD if outcomes are affected by proximity to other sanctions. The authors should discuss whether any adjacent thresholds (e.g., the 85% action plan trigger) could influence planning behavior near 75% and, if necessary, control for them (e.g., by including covariates for being near other thresholds or restricting the sample further). Without this, the pure presumption effect may be conflated with broader HDT signaling.

---

**Suggestions**

1. **Discuss Statistical Power Transparently.** With an effective sample of about 270 observations near the cutoff, power is low. The paper already notes this but could benefit from a formal discussion—perhaps via minimum detectable effects or a power curve—to contextualize the non-significance. Presenting confidence intervals in terms of practical magnitudes (e.g., how many additional approvals per year) would help readers understand whether the estimates rule out policy-relevant effects.

2. **Elaborate on Mechanisms Beyond Approval Rates.** The theoretical narrative emphasizes the presumption’s effect on the burden of proof. Consider presenting additional descriptive evidence, such as appeal outcomes, referral to planning inspectors, or time to decision, to support the mechanism that councils change behaviour rather than developers selectively apply. If such data are unavailable, acknowledge the limitation and suggest it as an avenue for future work.

3. **Strengthen Placebo Interpretations.** The householder placebo is useful but could be complemented by another outcome (e.g., commercial applications or refusals) or by examining whether refusals decrease while approvals increase, which would more directly test the “burden of proof” channel. Even a falsification test using sectors outside the presumption’s scope would bolster confidence. If data limitations preclude this, briefly explain why the chosen placebo is the most appropriate alternative.

4. **Clarify the Link Between the HDT Score and the Planning Window.** The outcome window is “the four subsequent quarters” after each HDT publication; however, the timing of the HDT (published in January/February) and the implementation of the presumption in decision-making may not align perfectly with quarters. Explaining why four quarters are chosen, and whether there is any lag structure (e.g., does the effect emerge immediately or only after the first quarter), would strengthen the design description. If possible, show graphical evidence (e.g., plotting approval rates against time relative to HDT publication) to justify the selected window.

5. **Include a Visualization of the RD.** The paper currently lacks a figure showing the regression discontinuity for the main outcome (major dwelling approval rate). A standard RD plot with binned averages and fitted lines would greatly aid readers’ intuition about the discontinuity’s magnitude and shape, and would complement the numerical tables.

6. **Discuss External Validity Carefully.** The HDT targets the worst-performing councils, and results may not generalize to councils closer to the threshold or to policy regimes without such a presumption. The conclusion should temper claims about “enough power to change overall housing delivery” by noting the narrow treated population and the fact that the HDT is a penalty applied only to underperforming councils.

7. **Consider Including Housing Start/Delivery Outcomes in Future Work.** Although the manifest mentioned housing starts and the paper does not cover them, it would be helpful to briefly explain the data limitations (e.g., insufficient cross-sectional or time-series variation in starts) and to suggest how future work might link approval behaviour to realized housing delivery. If housing completions are not yet observable for the treatment period due to construction lags, say so explicitly.

8. **Report Raw Means Above and Below the Cutoff.** In addition to the RD estimates, a table showing average approval rates just below and just above 75% (perhaps within a narrow bandwidth) would provide context for the estimated discontinuity and help readers assess the magnitude independently of modeling choices.

9. **Address Clustering and Serial Correlation More Directly.** The analysis clusters standard errors at the LA level, but the number of treated vs. control LAs near the cutoff is small. Consider reporting wild-cluster bootstrap p-values or showing that inference is not qualitatively altered when clustering is omitted (and explaining why clustering is still preferred). This reassures readers about the robustness of the statistical inference.

10. **Situate Findings Within Policy Debates.** The discussion touches on the broader federalism debate, but could benefit from explicitly connecting results to upcoming reforms (e.g., LURA 2023, NPPF 2024). For instance, if the presumption’s effect is modest but real, what does that imply for proposed reforms that adjust the threshold or how the presumption is implemented? Tying back to current legislative discussions would enhance policy relevance.

11. **Clarify the Use of Parametric vs. Non-Parametric Specifications.** The paper refers to a parametric regression with year fixed effects as confirming the direction and magnitude of the effect. It would help to specify the functional form (linear in HDT score? Quadratic?), clarify whether the parametric regression includes all observations within the optimal bandwidth or the full sample, and discuss why year fixed effects are necessary/beneficial. This transparency prevents readers from seeing the parametric result as a “specification search” rather than a structurally motivated check.

12. **Improve the Presentation of the Standardized Effect Sizes.** The appendix reports standardized effects but does not explain why negative coefficients are interpreted as “large negative” despite being in percentage point units. A brief explanation that the HDT running variable is reversed (treatment for HDT<75) would help, and the appendix could illustrate how these standardized effects relate to policy-relevant benchmarks (e.g., what magnitude would be “meaningful” for the national housing target).

By addressing these points, the authors can strengthen the empirical credibility, policy relevance, and clarity of their study without fundamentally altering the core contribution.
