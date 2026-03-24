# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-03-23T15:18:02.988871

---

**Referee Report: “The Lottery Lever: Heterogeneous Returns to Consumer-Led Tax Enforcement Across Europe”**

**1. Idea Fidelity**

The paper significantly deviates from the original research plan outlined in the Idea Manifest. While the core research question and staggered DiD identification strategy are preserved, two key elements of the original design are altered or omitted, compromising the intended contribution.

*   **Primary Outcome:** The manifest explicitly states the primary outcome should be the **VAT compliance gap (% of VTTL)** estimated by the EC/CASE consortium. This is the direct, policy-relevant measure of evasion. The paper instead uses **VAT revenue as a share of GDP**. This substitution is a major conceptual shift. VAT/GDP is a noisy outcome conflating compliance changes with shifts in consumption patterns, the structure of the economy, and statutory tax rates. The manifest’s “smoke test” confirmed access to the CASE VAT gap reports, making the non-use of this data puzzling and damaging to the paper’s stated aim of assessing the policy’s effect on the “VAT gap.”
*   **Sample and Treatment Variation:** The manifest lists **10 treated EU member states**, including Malta (adopted 1997). The paper excludes Malta, stating its adoption “predates the sample.” This exclusion discards valuable, long-duration treatment variation. A more appropriate approach would be to start the panel earlier (e.g., 1995) to include Malta’s pre-period or to use methods robust to never-treated units where Malta is always-treated. Its omission without a compelling econometric justification weakens the design.
*   **Data Source:** The paper correctly uses Eurostat for revenue and GDP data. However, it does not engage with the CASE VAT gap data, which was a central component of the original feasibility check and is the standard metric in policy discussions.

The paper pursues a related but distinct question: the effect of receipt lotteries on aggregate VAT revenue intensity. This is a valid question, but it is not the one posed in the original manifest, which was focused squarely on closing the *compliance gap*.

**2. Summary**

This paper provides the first cross-country analysis of VAT receipt lottery programs, exploiting staggered adoption across nine EU states. It finds a precisely estimated null average effect on VAT/GDP but evidence of meaningful heterogeneity: countries with lower baseline VAT/GDP (a proxy for a wider compliance gap) see a significant positive effect, while high-compliance countries see none. The paper concludes that consumer-as-auditor mechanisms are effective only where evasion is initially prevalent.

**3. Essential Points**

The authors must address the following critical issues. Failure to do so would necessitate rejection.

1.  **Justify or Correct the Choice of Primary Outcome.** The decision to abandon the VAT compliance gap (VTTL) for VAT/GDP is the paper’s most significant weakness. The VAT gap is the direct target of the policy and the focus of all related policy reports. The authors must either:
    *   **Re-run the core analysis using the CASE VAT gap estimates** as the dependent variable, as originally intended. This is the strongest solution.
    *   **Provide a rigorous, compelling justification** for why VAT/GDP is a superior or necessary alternative. This justification must directly address the severe limitations of VAT/GDP (e.g., confounding by tax rate changes, consumption basket shifts, GDP volatility) and explain why the VAT gap data is unsuitable (e.g., measurement error, methodological changes). Currently, the paper only mentions the VAT gap data is “model-dependent” in the discussion—an insufficient dismissal.

2.  **Address the Exclusion of Malta and the Treatment of Cancellations.** The sample construction requires justification and robustness checks.
    *   **Malta:** The paper must test the sensitivity of results to including Malta. If the panel cannot be extended back to 1997, the authors should apply estimators (e.g., the Callaway & Sant'Anna estimator used) that can incorporate an “always-treated” unit or clearly state this as a limitation, discussing its potential impact on external validity.
    *   **Cancellations:** The manifest highlighted cancellations as a key source of “reversal tests.” The paper’s test (Table 3, Column 1) is underpowered and conflated with COVID-19. The authors should perform a more structured analysis: (a) cleanly test for a *reversal* effect (i.e., a negative \(\beta\) when `Lottery` switches from 1 to 0) in the full DiD specification, and (b) present an event study centered on cancellation dates for the subset of countries that cancelled. If the data is too noisy, this should be stated clearly as a limitation, not presented as a tested result.

3.  **Clarify and Strengthen the Heterogeneity Analysis.** The finding of heterogeneous effects is the paper’s key contribution but is currently underspecified.
    *   **Mechanism:** The proxy “baseline VAT/GDP” is used but not validated. The authors should directly test if the effect is stronger in countries with a *higher estimated VAT compliance gap* (using CASE data) pre-adoption. This directly tests the “compliance frontier” hypothesis.
    *   **Specification:** Table 3, Column 3 interacts treatment with a time-invariant “Low baseline” indicator. This is a static split. The authors should demonstrate robustness to: (a) using a continuous, time-varying measure of the VAT gap (or another evasion proxy), and (b) using the interacted DiD estimator (e.g., `did_multiplegt` or `jackknife` in Stata) to formally test for effect heterogeneity by this pre-treatment characteristic.
    *   **Alternative Explanations:** Rule out that the heterogeneity is driven by other program features (e.g., prize size, integration with e-invoicing) correlated with baseline compliance. A table summarizing program characteristics by country would be informative.

**4. Suggestions**

*   **Improve Power and Precision Discussion:** The paper correctly notes limited power. Quantify this further. Calculate the Minimum Detectable Effect (MDE) for the main specification. Given the MDE is likely around 0.5-0.6 pp (as suggested), the significant heterogeneous effect of 0.54 pp is at the boundary of detectability. This should be discussed transparently as a constraint on the analysis.
*   **Refine the Event Study Interpretation:** The event study shows effects growing over 8+ years. The authors correctly caution about compositional bias. They should supplement this by showing the cohort-specific average treatment effects (from the Callaway & Sant'Anna estimator) to visualize how effects evolve for different adoption cohorts. This can help distinguish between a true dynamic effect and a cohort-selection effect.
*   **Enrich the Institutional Background:** Table 2 is helpful. Expand this into a more detailed appendix table documenting key program features: prize pool size (as % of VAT revenue or per capita), registration method (app, SMS, paper), whether linked to digital invoicing (e.g., Portugal), and duration. This context is crucial for interpreting the pooled ATE.
*   **Strengthen the Parallel Trends Discussion:** The event study pre-trends are reassuring. Provide additional evidence: (a) a placebo test using a lead of the treatment indicator, (b) a comparison of pre-treatment trends in VAT/GDP between early vs. late adopters (e.g., following Rambachan & Roth, 2023), or (c) a discussion of observable confounders (e.g., were adopters also more likely to implement other anti-evasion measures concurrently?).
*   **Deepen the Discussion & Policy Implications:**
    *   Reconcile the null average effect more thoroughly with Naritomi (2019). Discuss differences in prize intensity, enforcement context (São Paulo vs. EU nations), and baseline evasion levels.
    *   The policy implication is currently “target low-compliance countries.” Make this more operational. Using the estimates, provide a back-of-the-envelope cost-benefit analysis. If a 0.54 pp GDP increase in VAT revenue costs `X` million euros in prize money and administration, what is the rough rate of return? This would greatly enhance the policy relevance.
    *   Discuss the potential for heterogeneous effects *within* countries (e.g., on small vs. large retailers), even if unestimatible here, to guide future research.
*   **Presentation and Robustness:**
    *   **Table 1:** The Callaway & Sant'Anna (CS) estimate in Column 3 of Table 1 is presented oddly (“---” for FEs and Observations). Report the CS ATT clearly, with the number of effective observations/groups used.
    *   **Standard Errors:** With only 26 clusters, cluster-robust standard errors may be biased. Report wild cluster bootstrap p-values for the key specifications (Cameron, Gelbach, & Miller, 2008) as a robustness check.
    *   **Placebo Test:** The income tax placebo is sensible. Consider adding another placebo: a non-VAT indirect tax (e.g., excise duties), which should also be unaffected by the lottery.
*   **Conclusion:** The conclusion should be refined to reflect that the paper finds no average effect on **VAT revenue intensity**, with conditional effects based on **baseline revenue levels**. If the analysis is revised to use the VAT gap, the conclusion would be much stronger and directly address the question in the title.

**Overall:** The paper tackles an important, novel question with a credible staggered DiD design and finds a compelling heterogeneity story. However, its divergence from the planned outcome measure and some analytical choices significantly undercut its potential contribution. Addressing the three essential points is mandatory for publication. The suggestions, if implemented, would substantially improve the paper’s rigor, clarity, and policy impact.
