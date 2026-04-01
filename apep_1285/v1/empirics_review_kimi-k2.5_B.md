# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-04-01T23:26:36.740605

---

**Referee Report**

**Manuscript:** "The Missing Boom: Banking Secrecy Reform and Domestic Real Estate Prices in Switzerland"

**1. Idea Fidelity**

The paper deviates meaningfully from the original manifest in ways that weaken the research design. First, the manifest proposed using "share of foreign-controlled banks per SNB banking statistics" as a treatment intensity measure, which would directly capture exposure to foreign-client outflows and AEOI implementation; the paper instead uses NOGA 64 financial services employment share, which measures domestic labor market composition rather than foreign wealth management exposure. Second, the manifest envisioned 12 regions but the paper uses only 8 due to data availability restrictions, raising selection concerns (the excluded regions may differ systematically in ways that affect external validity). Third, the manifest proposed a placebo test using German domestic real estate to test the "Germans repatriating" mechanism; this is omitted, removing a key falsification exercise that would have bolstered the identification strategy.

**2. Summary**

This paper tests whether the 2017 Automatic Exchange of Information (AEOI) reform, which terminated Swiss banking secrecy, generated differential real estate price appreciation in wealth-management hub regions (Zurich, Lake Geneva, Zug) relative to other Swiss regions. Using SNB regional price indices from 2005–2023 in a continuous-treatment difference-in-differences framework with banking employment intensity as the treatment measure, the author finds no statistically significant effect on apartment, house, or rental prices. The null result survives permutation inference and robustness checks, leading the author to conclude that repatriated offshore wealth did not flow into domestic real estate markets.

**3. Essential Points**

*Identification Threats from Macroprudential Policy.* The paper inadequately addresses confounding from Swiss macroprudential measures (AMZB countercyclical capital buffer introduced 2012, tightened 2013–2014) that specifically targeted mortgage lending in "high-risk" markets—precisely the Zurich and Geneva regions that constitute the treatment group. While year fixed effects absorb national trends, they cannot capture region-specific policy effects correlated with banking intensity. The pre-treatment price moderation in high-banking regions (Figure 1, Panel A) may reflect AMZB cooling rather than baseline trends, potentially masking a true AEOI effect or biasing the estimate toward zero. The paper must explicitly model the interaction between macroprudential tightening and banking intensity.

*Measurement Validity and Sample Selection.* Banking employment intensity (NOGA 64) is a noisy proxy for exposure to AEOI-induced wealth repatriation. The mechanism concerns foreign account holders and Swiss residents with undeclared offshore assets, but employment share captures domestic financial sector size rather than foreign-client exposure or undeclared wealth concentration. Moreover, reducing the sample from 12 to 8 regions without discussing which regions are excluded (and why) creates selection bias if data availability correlates with market characteristics (e.g., smaller, thinner markets excluded). The paper should utilize the foreign-controlled bank share measure proposed in the manifest or canton-level SFTA voluntary disclosure data as alternative intensity measures.

*Statistical Power and Interpretation.* With only 8 clusters and cluster-robust standard errors of 1.342 against a mean log-price coefficient of 0.357, the 95% confidence interval spans [-2.27, 2.98] in log points—wide enough to include both a 90% price collapse and a 1,900% increase. The paper interprets this as a "precisely estimated null," but these are uninformative bounds. The leave-one-out analysis reveals the point estimate is entirely driven by Zurich (coefficient flips from +0.357 to -0.642 when Zurich is dropped), indicating fragility rather than precision. Claims about the absence of economic significance should be tempered by explicit power calculations or bounded null interpretations.

**4. Suggestions**

**Address Macroprudential Confounding.** Include region-specific linear time trends or, preferably, interact the post-2017 indicator with indicators for AMZB-affected regions. Alternatively, use a triple-difference design comparing mortgage volumes (directly affected by AMZB) versus cash transactions (unaffected) across regions, though data constraints may limit this.

**Improve Treatment Measurement.** Construct treatment intensity using (a) pre-2017 foreign-client deposit shares by region from SNB banking statistics (as originally proposed), or (b) canton-level SFTA voluntary disclosure counts normalized by population or tax base. If these measures produce similar null results, the finding is more credible. Report which 4 of 12 regions are excluded and demonstrate that results are robust to sample composition or use cantonal data (26 cantons) rather than SNB regions to increase power.

**Reconcile Event-Study Anomaly.** The event study shows a statistically significant spike at $t=0$ (2017) that fully dissipates by $t+1$. Rather than dismissing this as "transient portfolio rebalancing," investigate whether this reflects (a) anticipation effects in late 2016 (shifting the treatment year), (b) differential supply responses in financial centers (faster construction permitting), or (c) composition effects in the index. If the spike is real but temporary, this is evidence of market clearing or supply elasticity rather than absence of demand shocks—an important distinction for policy implications.

**Explore Heterogeneity.** The aggregate index may mask effects at the luxury segment where offshore wealth typically concentrates. If transaction-level data are unavailable, use the regional indices for "high-end" properties (if disaggregated) or exploit cross-sectional variation in building permit values. The null at the mean is consistent with wealth flowing into trophy assets that comprise thin market segments, which would be masked in regional averages.

**Placebo and External Validity.** Implement the omitted German placebo test: if German residents repatriated Swiss holdings, German luxury markets (Munich, Hamburg) should show relative appreciation post-2017. Alternatively, test whether Swiss cross-border commuter regions (Basel, Geneva) show differential effects relative to interior regions, exploiting the CHF appreciation shock as a confound rather than just a control variable. This would validate the identifying assumption that high-banking regions would have followed parallel trends absent AEOI.

**Power Analysis.** Conduct a minimum detectable effect size (MDES) calculation given 8 clusters, showing what log-price effect the design could reasonably detect. If the MDES is large (e.g., >0.5 log points), reframe the conclusion as "we cannot rule out moderate effects" rather than "wealth does not flow into real estate." The current framing overstates the strength of the evidence.

**Clarify Mechanisms.** The discussion notes three explanations for the null (financial asset absorption, tax payments, geographic dispersion) but provides no direct evidence. Even crude bounds—e.g., correlating regional financial asset growth (SNB deposit data) with banking intensity post-2017—would help adjudicate between these mechanisms and strengthen the paper's contribution regarding portfolio allocation.

**Minor:** Standardize the treatment variable (divide by SD) to ease interpretation—current coefficient of 0.357 per unit of employment share (which ranges 0.015–0.062) is difficult to parse. Report the standardized beta or convert to percentage points of price growth per standard deviation of banking intensity.
