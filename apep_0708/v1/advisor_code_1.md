# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-16T23:01:00.693647

---

**Idea Fidelity**

The paper adheres closely to the manifest idea. It exploits the 1924 Johnson-Reed Act as a plausibly exogenous shock to the supply of immigrant domestic servants and tests whether the resulting contraction in household labor lowered, rather than raised, native women’s labor force participation (the Cortes-Tessada channel “in reverse”). The data source (IPUMS MLP 1920–1930 linked panel of native-born white women), Bartik-style exposure measure (county share of Southern/Eastern European immigrants), outcome (change in occupation participation via OCCSCORE), and decomposition by marital status are all present and central to the empirical work. The paper could, however, more explicitly tie several robustness exercises—non-movers, urban/rural splits, and the placebo pre-period—to the key identification assumptions articulated in the manifest.

---

**Summary**

This paper examines how the 1924 Johnson-Reed Immigration Act’s collapse in Southern/Eastern European immigration affected native-born white women’s labor force participation between 1920 and 1930. Using 7.65 million linked individual records, the author shows that women in counties with higher exposure to restricted immigrant origins experienced *smaller* gains (even declines) in participation, driven by drops in domestic service employment, particularly for unmarried women. The results are interpreted as historical evidence that immigrant domestic servants complemented native women’s market work through household production, mirroring the Cortes-Tessada mechanism in the reverse direction.

---

**Essential Points**

1. **Identification and Omitted County-Level Dynamics:** The exposure measure is county-level immigrant share in 1920, and the paper relies on state fixed effects plus individual controls to isolate the quota effect. But counties with large S/E immigrant populations also had distinct industrial trajectories, local policies, or shocks (e.g., manufacturing growth/decline, local labor demand shifts, or earlier reforms) between 1920 and 1930 that may affect native women’s LFP independently of immigration quotas. Without county fixed effects or pre-period trends beyond the 1910–1920 average, it is difficult to rule out such confounding. Consider exploiting within-county changes (e.g., interacting exposure with year dummies) or directly controlling for county-level economic time trends (manufacturing employment, wage growth, etc.) to bolster the parallel trends assumption.

2. **Interpretation of the Bartik Exposure as the Act’s Causal Shock:** The paper interprets the coefficient on the 1920 immigrant share as the effect of the 1924 restriction. But this share reflects *pre-existing* levels of immigrants, not the actual decline induced by the restriction. Thus, the exposure interacts both with quota tightness and with unrelated historical factors. A stronger design would construct an instrument (e.g., predicted quota reductions based on 1920 immigrant origin composition and the 2% rule relative to 1890 shares) or use the differential drop in immigrant inflows implied by the Act to scale the exposure, clarifying why high-share counties experienced larger *reductions* in domestic service. Otherwise, the results risk conflating structural differences across counties with the treatment effect.

3. **Lack of Direct Link Between Exposure and Immigration Flows/Services:** The mechanism rests on the disappearance of immigrant domestic servants, yet the analyses never show that restricted-origin inflows or stocks actually fell more in high-exposure counties. Moreover, the domestic service mechanism is inferred from declines in the domestic service dummy rather than from actual immigrant labor measures. Provide evidence (even from aggregate census or municipal records) that domestic service employment fell particularly sharply in high-exposure counties due to immigration restriction, perhaps by linking changes in the number of *foreign-born* women in domestic service or by showing that cities with the largest S/E quotas saw the largest net decline in immigrant domestic workers between censuses.

If these issues remain unresolved, the causal narrative—that the quota itself induced the observed LFP patterns via the domestic service channel—remains suggestive but not fully convincing.

---

**Suggestions**

- **Refine the Exposure Measure:** The paper currently uses the 1920 share of S/E European immigrants, but the treatment variation is driven by the interaction of this share with the quota reduction. Construct a clearer measure of the quota shock, for example by calculating each county’s *predicted* reduction in immigrant inflows based on the 1920 composition and the national quota formula (2% of 1890 foreign-born by origin). This would differentiate between counties that *lost* more immigrant domestic servants due to the Act and those that merely had larger immigrant populations to begin with.

- **Strengthen the Counterfactual via Pre-Trends:** The placebo 1910–1920 analysis is helpful but limited. Consider showing event-study–style trends (perhaps grouping counties into exposure quartiles and plotting mean LFP changes across multiple decades, if data allow) to demonstrate parallel trends. Alternatively, add interacted time trends or county-specific linear trends to address concerns about differential pre-existing trajectories. This would be especially important given the non-trivial placebo effect for unmarried women, where the paper concedes a 40% potential contribution of pre-trends.

- **Explore Heterogeneity by Local Economic Structure:** Because the domestic service channel plausibly operates differently across urban/rural or industrial vs. agricultural counties, interacting exposure with local economic characteristics (e.g., manufacturing share, presence of high-income households likely to hire servants, or female employment in other sectors) could provide deeper insights. Do the negative effects concentrate in counties where domestic service was a large share of total female employment? Is there variation by occupational structure (service vs. manufacturing) that aligns with the household production story?

- **Clarify the Mechanism with Immigrant-Specific Data:** The mechanism section would benefit from showing how much the immigrant domestic service labor force shrank in high-exposure counties. If linkable data exist, track the number of *foreign-born* women in domestic service across censuses by county exposure, or, if unavailable, leverage aggregate IPUMS data or historical city directories to document the decline. Additionally, consider examining whether native women *substituted* into other sectors (or out of the labor force entirely) once domestic service evaporated, perhaps by inspecting changes in occupational distributions beyond OCCSCORE.

- **Address Measurement and Sample Selection Concerns:** The paper notes that the OCCSCORE-based LFP measure may miss informal work and that the MLP disproportionately links literate individuals. It would be useful to show robustness to alternative LFP definitions (e.g., just using any reported occupation, self-reported “worked for pay,” or restricting to certain occupational categories) to ensure that measurement error is not driving the negative coefficients. Also, provide a brief balance table comparing linked vs. unlinked women by key demographics to assess the generalizability of the findings.

- **Discuss Alternative Mechanisms More Explicitly:** The negative effect on unmarried women could partly reflect that these women were the domestic servants whose jobs disappeared, rather than being penalized through the household production channel. The paper mentions this, but a more explicit decomposition—e.g., estimating the effect separately for unmarried women who worked in domestic service in 1920 vs. those who didn’t—would help distinguish supply-side (job loss) versus complementarity effects.

- **Contextualize the Magnitudes:** While the standardized effect sizes table is useful, translating the coefficient into more intuitive terms (e.g., “a county moving from the 20th to the 80th percentile of exposure saw a 1.5 pp smaller increase in married women’s LFP, equivalent to 55% of the national increase”) in the main text would help readers gauge economic significance.

Overall, the paper addresses an important and novel historical question with a massive and rich data set. Addressing the identification and mechanism concerns above would greatly strengthen the argument that the 1924 Act reduced native women’s labor force participation through the domestic servant channel.
