# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant A)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** A
**Date:** 2026-03-14T14:38:27.982393

---

# Referee Report

## 1. Idea Fidelity

The paper largely pursues the original idea from the manifest, but with two notable omissions that weaken the identification strategy. First, the **Scotland OSCR placebo test** is mentioned in the institutional background but never implemented empirically. The manifest explicitly listed this as a key identification test ("Scotland OSCR placebo (different thresholds)"), yet the paper provides no Scottish data analysis. This is a significant gap, as Scottish charities would provide a clean test of whether bunching at £25K/£1M reflects English regulation versus general round-number effects.

Second, the **US cross-country comparison** (idea_0815) referenced in the manifest is absent. While this may be reserved for future work, the manifest positioned it as part of the core identification strategy to test whether "organizational culture, institutional context, or threshold magnitude drives the response."

The 2022 reform test is included but produces puzzling results that are not adequately addressed (bunching at £25K *increases* post-reform from 0.156 to 0.358). The dose-response comparison between thresholds is well-executed and forms the paper's strongest evidence.

## 2. Summary

This paper documents substantial income bunching among UK charities at regulatory compliance thresholds (£25,000 for independent examination; £1,000,000 for statutory audit), using the universe of Charity Commission annual returns (2002–2025). The five-fold difference in bunching intensity across thresholds provides compelling evidence that compliance costs—not round-number psychology—drive the distortion, with important implications for threshold-based regulatory design in the nonprofit sector.

## 3. Essential Points

**(1) The Scotland placebo test must be implemented or convincingly justified as unnecessary.** The manifest identified this as a core identification strategy, and its absence is conspicuous. Scottish charities operate under OSCR with different thresholds, providing a natural control group for testing whether £25K/£1M bunching reflects English regulation versus universal round-number preferences. Without this test, the placebo thresholds at £20K/£30K (Table 4, Panel C) actually *undermine* identification—bunching estimates there (0.16–0.20) are similar to the £25K estimate (0.156), suggesting round-number effects may explain much of the observed pattern. The authors must either: (a) add the Scotland analysis, or (b) provide a compelling argument for why the £20K/£30K placebos are insufficient and why the dose-response at £1M alone identifies the regulatory effect.

**(2) The 2022 reform test results require deeper investigation.** The finding that bunching at £25K *increased* post-reform (0.156 → 0.358) is inconsistent with the compliance-cost avoidance hypothesis and is dismissed too quickly as "sticky" behavior. This could reflect: (a) anticipatory bunching before the reform took effect, (b) confusion about the new rules, (c) data artifacts from the coverage expansion around 2020, or (d) genuine persistence in accounting practices. The authors should: (i) plot event-study style dynamics showing bunching by fiscal year, (ii) examine whether charities just below £25K pre-reform moved to just below £40K or stayed at £25K, and (iii) clarify the timing of fiscal year-ends relative to the March 2023 implementation date. If the reform test cannot cleanly identify migration, this should be acknowledged as a limitation rather than presented as "mixed" evidence.

**(3) The exclusion window sensitivity threatens the main estimates.** Table 4, Panel B shows that bunching estimates turn *negative* at ±5 and ±6 bin exclusions (−0.170 and −0.432). This suggests the counterfactual density is not well-identified—the polynomial fit is highly sensitive to how much data around the threshold is excluded. For AER: Insights, this level of specification sensitivity is concerning. The authors should: (i) report confidence intervals across specifications, not just point estimates, (ii) use the optimal bandwidth selection methods from recent bunching literature (e.g., Cattaneo et al. 2020), and (iii) show graphical evidence that the counterfactual fit is reasonable (residual plots, fitted vs. actual densities). If the £1M estimate is more stable across specifications, this should be emphasized as the more credible result.

## 4. Suggestions

**(1) Strengthen the dose-response interpretation with cost elasticity estimates.** The paper notes that compliance costs differ roughly ten-fold (£500–£2,000 vs. £5,000–£20,000) while bunching differs five-fold (0.156 vs. 0.806). This is suggestive but informal. Consider estimating an implicit elasticity of bunching with respect to compliance costs. Even rough bounds would strengthen the claim that charities are responding to economic incentives. You could also examine whether charities near £1M show more sophisticated avoidance (e.g., timing income across years, splitting into related entities) compared to those near £25K, which would further support the cost-response interpretation.

**(2) Address the data coverage discontinuity more thoroughly.** The paper notes a sharp increase in observed returns from ~15,000 to ~155,000 per year around 2020, attributed to "changes in the Charity Commission's data publication practices." This is a potential threat to identification, especially for the reform test which relies on pre/post comparisons. I recommend: (i) plotting the time series of total returns filed by year to show the discontinuity visually, (ii) contacting the Charity Commission for documentation on the coverage change, (iii) showing that the *distribution* of income (not just the count) is stable pre/post-2020 away from thresholds, and (iv) considering whether the main results should be restricted to 2015–2019 for consistency, even at the cost of sample size.

**(3) Improve the heterogeneity analysis.** Table 3 shows striking variation by charity purpose (religious charities show much stronger bunching), but the interpretation is speculative. Consider testing whether this heterogeneity correlates with observable characteristics: average charity size, proportion of volunteer staff, geographic location (urban vs. rural), or age of the charity. Religious organizations may bunch more not because compliance costs are higher relative to income, but because they have less professional accounting capacity or stronger community pressure to appear "small." Adding even one or two additional dimensions of heterogeneity would strengthen the mechanism story.

**(4) Clarify the "missing mass" interpretation.** The paper notes that missing mass above £25K (523 charity-years) exceeds excess mass below (237), consistent with "diffuse missing mass." This is an important observation that deserves more attention. Where did the displaced charities go? Are they spread across £25K–£50K, or do some exit the register entirely? A figure showing the full density with the counterfactual overlay (not just bin counts in tables) would help readers assess the fit. Also consider whether some charities may be splitting into multiple entities to stay below thresholds—a form of avoidance that bunching alone cannot detect.

**(5) Discuss external validity and policy implications more carefully.** The conclusion recommends "sliding-scale requirements" as an alternative to threshold-based regulation. This is reasonable, but the paper should acknowledge potential trade-offs: sliding scales increase administrative complexity, may create compliance uncertainty, and could reduce the clarity of regulatory obligations. Also consider whether the observed bunching is welfare-reducing. If charities are forgoing socially valuable activities to stay below thresholds, the distortion is costly. But if they are simply reclassifying income or timing donations, the real resource cost may be small. A brief discussion of the welfare implications would strengthen the policy relevance.

**(6) Technical presentation improvements.** Several tables would benefit from confidence intervals rather than just standard errors. Figure references are missing—the paper describes visual patterns (density drops, bunching masses) but does not include actual distribution plots, which are standard in bunching papers. Adding 2–3 key figures (income density around each threshold with counterfactual overlay; time series of bunching estimates; heterogeneity by purpose) would significantly improve readability. Also, the abstract claims "988,043 annual returns" but Table 1 shows 765,564 charity-years for 2015–2024—clarify the sample definitions.

**(7) Consider a bounds approach to the reform test.** Given the ambiguous reform results, consider framing the £25K and £1M cross-sectional comparison as the primary identification, with the reform as supplementary evidence. The dose-response across thresholds is actually the cleanest test in the paper, as it does not rely on time-series variation that could be confounded by the coverage change. Reframing the paper around this cross-sectional identification would be more honest about what the data can credibly identify.

**(8) Engage more deeply with the nonprofit-specific literature.** The paper cites Yildirim (2018) on New York nonprofits but could engage more with the UK charity literature on compliance and reporting. Are there prior studies documenting manipulation of charity accounts? How do these results compare to evidence from other jurisdictions (e.g., Calabrese 2021 on US state audit mandates)? A more thorough literature review would help position the contribution and clarify what is genuinely new about the UK setting.

---

**Overall Assessment:** This is a promising paper with a clear research question and substantial data. The dose-response evidence across thresholds is compelling and likely sufficient for publication with revisions. However, the identification strategy would be significantly strengthened by implementing the Scotland placebo test, addressing the specification sensitivity more rigorously, and providing a more honest assessment of what the reform test can (and cannot) identify. With these improvements, the paper would make a valuable contribution to the bunching and nonprofit regulation literatures.

**Recommendation:** Revise and Resubmit
