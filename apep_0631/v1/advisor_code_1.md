# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-13T16:13:04.445033

---

**Idea Fidelity**

The paper is faithful to the manifest. It leverages the continuous measure of SALT exposure constructed from the 2017 IRS SOI zip-code data, uses the Zillow ZHVI as the primary outcome, and deploys a continuous-treatment difference-in-differences design around the two federal tax shocks (TCJA cap in 2018 and OBBB reversal in 2025). The key idea of testing symmetry in capitalization by comparing the two shocks is front and center. The paper also discusses the salient threats emphasized in the manifest—differential trends across high-SALT zip codes and confounders such as metro-level shocks—and implements the preferred metro-by-month fixed effects. The data sources, coverage, and the focus on reversal/”sticky capitalization” are all consistent with the original plan.

---

**Summary**

This paper studies how the 2018 SALT deduction cap (TCJA) and its 2025 partial reversal (OBBB) affected zip-code level house prices, using a continuous measure of SALT exposure and a difference-in-differences design. The author finds that each \$10,000 of SALT above the \$10,000 cap reduced house prices by roughly 3.2 percent, effects that emerged quickly and persisted through 2025. Crucially, the 2025 reversal produced no offsetting appreciation, leading to the conclusion that capitalization is asymmetric—housing prices fall when tax subsidies are removed but do not rebound when the subsidy is restored.

---

**Essential Points**

1. **Confounding from Other Components of the TCJA and Aggregate Housing Shocks.** The identification strategy relies on cross-sectional SALT exposure differences, but the TCJA included many simultaneous federal tax changes (income tax rate cuts, standard deduction doubling, mortgage interest cap, etc.) that also varied with income and thus SALT exposure, and contemporaneous housing supply/demand shocks (post-2018 credit cycles, pandemic, interest rate normalization) may differentially affect high-SALT, high-income zip codes. The current specification does not include time-varying controls for income distributions or economic growth, nor does it exploit any direct source of variation isolating SALT. Without further justification or robustness (e.g., controlling for zip-level time trends in income or placebo reform years), the causal interpretation of the SALT bite coefficient as a pure effect of the SALT cap is not credible.

2. **Symmetry Test is Underpowered and Risks Mechanical Bias.** The reversal test compares the TCJA and OBBB coefficients and rejects $\beta_{\text{TCJA}} + \beta_{\text{OBBB}} = 0$ based on seven months of post-OBBB data, during which housing prices also faced macro headwinds (rising mortgage rates, cooling demand). Because these macro shocks equally hit all zip codes, they should be absorbed by time fixed effects; however, if high-SALT markets continue to experience slower recoveries for reasons unrelated to SALT (e.g., remote work preferences, higher propensity to rent), the rejection of symmetry may be driven by insufficient post-treatment time rather than true stickiness. The paper must either extend the post-OBBB window once more data are available or provide a convincing argument (with placebo analyses) that the short window is sufficient to rule out symmetric adjustment.

3. **Mechanisms and Migration Evidence Not Integrated Into Identification.** The paper invokes sorting lock-in, anchoring, and anticipation of the 2030 sunset to explain the asymmetry, yet the empirical analysis does not incorporate any of these margins. Without integrating migration or household compositional changes into the model, the interpretation that the asymmetry reflects stickiness rather than differential shocks or measurement artifacts remains speculative. For instance, migration flows reported from IRS SOI could be used in a structural way (e.g., instrumenting SALT exposure with migration-adjusted populations) or at least show that zip codes with larger outflows correspond to the ones showing the most “stickiness”. At minimum, the paper should demonstrate that the asymmetry is not simply an artifact of continuing outmigration unrelated to the 2025 policy.

If additional critical points are necessary, the paper should not proceed in current form.

---

**Suggestions**

1. **Strengthen the Parallel Trends and Identification Arguments.** 
   - Show event-study plots with metro-by-month fixed effects (the preferred specification) to demonstrate pre-trend balance there, not only with zip-by-month FE. With the intensive margin of SALT bite, trends may differ at the metro level, so the robustness of pre-treatment coefficients in the preferred specification needs to be documented.
   - Consider including time-varying zip-level controls such as employment growth, mortgage rates, or local tax changes, perhaps via interactions of SALT bite with county-level macro trends, to rule out that the coefficient is capturing other reforms correlated with SALT exposure.
   - Explore a plausible instrument (e.g., historical tax structures or geography) to triangulate the effect of SALT, or define a “donut” sample that excludes the most extreme zip codes (e.g., top 1%) to avoid undue leverage by very affluent areas, then check whether the effect persists.

2. **Address Confounding from the Standard Deduction and Other TCJA Changes.**
   - The placebo analysis in Table 5 (column 3) shows a marginally significant effect for zip codes below the cap, which is attributed to the standard deduction’s increase. This points to other TCJA components affecting housing prices. Explicitly control for the value of the standard deduction or the share of itemizers in each zip to isolate SALT effects; alternatively, exploit heterogeneity in the share of itemizers to partial out those other channels.
   - Use IRS SOI data to construct the share of returns claiming SALT per zip and interact it with the post period. If the main effect disappears once conditioning on the itemizer share, this would weaken the causal argument and should be acknowledged.

3. **Clarify and Justify the Reversal Test Given the Limited Post-OBBB Window.**
   - A seven-month post-OBBB window is short; describe whether housing market reactions to prior tax reforms have materialized within similar time frames. If possible, cite prior literature or present placebo tests (e.g., using phased-in treatments such as the 2017 reform’s announcement) to justify the assumption that housing prices should have responded measurably within seven months.
   - Consider looking at leading indicators such as listing prices, contract activity, or mortgage applications (if available) to detect early signs of reversal. If these leading indicators also show no rebound, it bolsters the argument for sticky capitalization; if not, it undermines the claim.
   - Provide heterogeneity analysis across zips with low vs. high property turnover. Sticky capitalization might be less plausible in markets with high transaction volumes; if the asymmetry is concentrated in low-turnover areas, that nuance should be highlighted.

4. **Integrate Migration Mechanisms and Provide Direct Evidence.**
   - The paper mentions IRS SOI migration flows but does not use them empirically. Incorporate migration outcomes (either as additional dependent variables or through triple-difference specifications) to show whether high-SALT zips experiencing price declines also lost residents and whether those losses persisted post-OBBB.
   - Show that the asymmetry persists even after controlling for net migration in each zip. If migration explains the drop but not the lack of reversal, that strengthens the interpretation of stickiness. If migration fully explains the asymmetry, the conclusion should be tempered.

5. **Refine Standard Errors and Inference.**
   - While state-clustered standard errors are appropriate for the main specification, the switch to zip-level clustering in Table 5 suggests substantial intra-zip correlation. Consider two-way clustering (state and time) or a wild-cluster bootstrap to ensure the Wald test for symmetry is not driven by few clusters.
   - Because treatment intensity varies continuously, consider estimating robust standard errors via the Conley spatial autocorrelation adjustment or randomization inference to account for spatial spillovers across adjacent zip codes, especially in metropolitan areas where prices may co-move.

6. **Elaborate on the Role of Anticipation and Sunset Clauses.**
   - The OBBB cap is scheduled to revert in 2030, which may suppress appreciation due to uncertainty. Formalize this by interacting the SALT bite with indicators for the cap being potentially temporary (e.g., a near-term sunset) or using market expectation data (if available) to justify that rational agents would discount the reversal.
   - Alternatively, document that the reversal was unexpected (confirmed by media coverage) so that anticipation effects are minimal. This addresses the concern that markets still priced in future sunsets rather than the current policy change.

7. **Expand the Discussion of External Validity and Policy Implications.**
   - The conclusion currently states that temporary tax policy has permanent housing effects. Support this with a more nuanced discussion about the timescale over which “permanent” is credible and whether other reforms (e.g., property tax caps at the state level) show similar ratchets. This helps contextualize the policy relevance without overstating the findings.

By addressing these points, the paper would defend the credibility of its identification, provide richer evidence on underlying mechanisms, and strengthen the claims about asymmetric capitalization.
