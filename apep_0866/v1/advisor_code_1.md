# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-24T21:16:11.547959

---

**Idea Fidelity**

The paper largely adheres to the original idea manifest. It studies the gendered labor-market effects of the shale boom using QWI-ACS data, exploits geological variation in shale exposure, and focuses on male-biased employment shocks with a triple-difference strategy that compares female versus male outcomes across high- and low-mining counties over the boom-bust cycle. The data sources (QWI for sex-by-industry outcomes, ACS for demographics) and the policy motivation (male-dominated mining sector) are all present. However, the paper never fully details how the identification strategy handles the possibility that boom counties were on different gender-specific trajectories before the fracking revolution. The manifest emphasized testing parallel trends and an IV for sex ratios; those diagnostics are only mentioned qualitatively here. Including explicit pre-trend figures or IV checks would better align the paper with the stated approach.

---

**Summary**

Using county-level QWI data for 24 states, the paper implements a triple-difference design to estimate how the male-biased shale boom affected female non-mining employment and earnings relative to men. The main findings are that boom counties saw a significant deterioration in women’s labor-market outcomes relative to men and that these effects persisted through the bust, implying lasting structural change. Placebo checks (healthcare and construction) and a continuous treatment specification support a male-biased demand interpretation.

---

**Essential Points**

1. **Parallel Trends and Pre-Trend Evidence.** The credibility of the triple-difference hinges on the assumption that the female-minus-male trajectory would have evolved similarly in high- and low-mining counties absent the boom. The paper states this assumption but never presents pre-boom event-study estimates, lead coefficients, or graphical evidence of parallel pre-trends. Without this, it is unclear whether the observed differential is driven by the boom rather than pre-existing divergence. Please include pre-treatment event analyses or placebo coefficients for the pre-2006 period to demonstrate that the gender gap evolved similarly prior to the boom.

2. **Treatment Definition and Confounding Shocks.** The treatment is defined by counties with high pre-boom mining employment share, which may correlate with other features (rurality, baseline gender norms, economic volatility) that also affect female employment cycles. The current specification controls only for county and year fixed effects and the Female × Year term, leaving room for time-varying confounders that evolve differently across treated counties. Incorporating county-specific trends, controlling for the share of natural-resource employment outside mining, or showing robustness to propensity-score weighting would strengthen identification and make the comparison more convincing.

3. **Mechanism Validation.** The paper proposes cost-of-living, Dutch Disease, and marriage-market mechanisms but provides no empirical leverage to distinguish among them or even to show that they are quantitatively plausible. While plausibility is useful, the persistently negative effect during the bust could also arise from unobserved amenities or migration decisions driven by broader macro shocks. Consider using ACS sex ratios, housing price series, or industry mix data to provide direct evidence for at least one mechanism. Without such evidence, the “roughneck externality” remains a broad label rather than an empirically supported channel.

If these issues cannot be satisfactorily addressed, the paper’s central causal claims remain insufficiently supported.

---

**Suggestions**

1. **Pre-Trend/Event Study Plots.** Add an event-study-style figure or table showing the evolution of the triple-difference coefficients in years leading up to 2006; include both employment and earnings. Even if the triple-difference does not lend itself neatly to standard event-study plots, you can graph the gender gap in high-mining and non-mining counties separately (or for treated vs. control) to show that they move in parallel pre-boom. This will greatly enhance the reader’s confidence in the identification.

2. **Alternative Control Groups.** Complement the top-quartile treated definition with alternative comparisons. For example, focus on counties within the same state or region that are adjacent to high-mining counties but just below the treatment threshold. Alternatively, use a continuous treatment and show the robustness of results when limiting the sample to rural, similarly sized counties. These comparisons will help alleviate concerns that high-mining counties differ systematically from the rest even after fixed effects.

3. **Covariate Adjustments.** While the fixed effects absorb level differences, adding time-varying controls (e.g., county population growth, baseline industry composition other than mining, federal transfer receipts, or local housing starts) interacted with the boom indicator would help ensure that the results are not driven by other contemporaneous shocks. In particular, controlling for the growth in male mining employment directly might help isolate the gendered effect from overall resource-induced growth.

4. **Mechanism Exploration with Auxiliary Data.** The paper argues for cost-of-living and Dutch Disease channels but does not test them. Consider linking county-level price indexes (if available), housing permit data, or industry employment shares (retail, hospitality, education) to the treatment. If housing costs rose more in high-mining counties and these changes are correlated with female outcome deterioration, it bolsters the mechanism story. Similarly, use ACS marital status data or crime reports to explore marriage-market or safety effects. At the very least, present descriptive evidence on sex ratios and housing costs during the boom to contextualize the proposed channels.

5. **Persistence During the Bust.** The persistence of gendered effects through the bust is interesting but requires further interrogation. Could population inflows (net migration) or the pace of local recovery explain why women did not bounce back? Include a discussion and, if possible, data on migration or housing stock to show whether high-mining counties were fundamentally altered in a way that would keep the female gap wide even after male mining employment shrank. You might also run the analysis restricting to counties where mining declined steeply during the bust to show whether the persistence is localized to the most-affected areas.

6. **Placebo Industries – More Detail.** The placebo checks are a good idea but need more explanation. For the healthcare placebo, report whether the sample composition (e.g., urban-rural mix) differs from the main sample; this would help convince the reader that the lack of effect is informative rather than due to sample selection. Additionally, the construction placebo shows a positive coefficient on the triple interaction—explain whether this is expected (perhaps construction benefited male workers) and discuss why it does not undermine the mechanism.

7. **Gender Gap Measurement.** The gender earnings gap is measured as (male – female)/male. Consider alternative normalizations (e.g., log ratio) or reporting additional statistics such as the share of female employment in non-mining sectors to gauge whether outcomes worsened via intensive (wages) or extensive (employment share) margins. Such nuance would clarify policy implications—for example, whether the fracking boom pushed women out of the labor force entirely or simply depressed their wages.

8. **Clustering Levels and Inference.** The choice of state-level clustering is justifiable given shared policy shocks, but the sample includes hundreds of counties, so it might be valuable to report wild cluster bootstrap or county-level clustered standard errors throughout (not just in robustness) to show that inference is not sensitive to the clustering choice. The fact that county clustering lowers standard errors is good to highlight and discuss what it implies for precision.

9. **Heterogeneous Effects.** The appendix hints at heterogeneity (urban vs. rural) but does not explore it thoroughly. Given that boom impacts probably differ by baseline female labor intensity, educational attainment, or housing supply elasticity, investigating this heterogeneity could strengthen the policy relevance. For example, do the effects concentrate in counties with more service-sector employment? This would help understand where “roughneck externalities” matter most.

10. **Documentation of Data and Code.** Since the analysis depends on extensive QWI and ACS panel data, provide more detail (perhaps in an appendix) on how the sample was constructed, how missing data were handled, and the exact definitions of the treatment and period dummies. Transparency here aids reproducibility and lets readers assess potential sample selection biases.

By addressing these points, the paper would significantly bolster its credibility and deepen its contribution to the literature on gendered consequences of male-biased industrial shocks.
