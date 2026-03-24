# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-17T22:52:03.701934

---

## 1. **Idea Fidelity**

The paper pursues the core idea in the manifest: bunching of nonprofit revenues around the IRS Form 990 / 990-EZ threshold using the EO BMF, with a placebo at \$50,000. That said, it misses two of the strongest elements of the original design.

First, the manifest’s most compelling identification feature was the 2010 reform moving the threshold from \$100,000 to \$200,000. The paper does not actually implement that design. Instead, it uses a current cross-section of the BMF and interprets bunching at \$100,000 as “legacy” behavior. That is not a credible substitute for demonstrating migration of bunching from \$100K pre-2010 to \$200K post-2010.

Second, the manifest proposed using cross-state variation in audit/disclosure rules to separate federal filing incentives from state compliance incentives. The paper does not do this in a serious way. The brief split between “high-regulation” and other states is too ad hoc to support the decomposition claim.

So the paper is faithful to the broad question, but it leaves the best identification strategies largely unrealized.

## 2. **Summary**

This paper argues that nonprofits bunch just below the \$200,000 gross receipts threshold to avoid filing the full Form 990 rather than Form 990-EZ, interpreting this as revealed preference over disclosure/compliance costs. Using the EO BMF cross-section, it reports significant excess mass below \$200,000, no significant bunching at \$50,000, and stronger responses among smaller and religious organizations.

The topic is interesting and potentially publishable. But in its current form, the paper overstates what the data and design can support.

## 3. **Essential Points**

1. **The data/design do not support the paper’s strongest causal claims.**  
   The BMF cross-section is not an annual panel, and the paper acknowledges this. But that limitation is much more serious than the text suggests. Without annual returns by filing year, you cannot credibly show that bunching migrated from \$100K to \$200K after the 2010 reform, nor can you distinguish current behavior from stale reporting patterns, filing lags, or compositional artifacts. This is the central weakness.

2. **The mechanism is misstated, and one confound is ignored.**  
   The paper repeatedly describes the threshold as creating an asymmetric *public disclosure* regime, but both Form 990 and Form 990-EZ are public information returns. The real discontinuity is in reporting detail and compliance burden, not public-versus-private disclosure. In addition, the filing rule is based on both gross receipts and assets. Since organizations above either threshold file the full 990, bunching in receipts alone is confounded by the asset threshold unless the analysis carefully restricts or conditions on assets.

3. **The bunching estimates are too specification-sensitive to be persuasive as currently presented.**  
   The normalized excess mass varies from 0.63 to 1.65 across polynomial order and from 1.20 to 3.48 across exclusion windows. That is not reassuring robustness; it suggests the estimate is highly dependent on functional-form choices. The imbalance between excess mass below (941) and missing mass above (269) is also a warning sign. Some imbalance is possible, but this degree of mismatch, combined with a wide and unstable excluded region, points to counterfactual misspecification rather than clean local manipulation.

## 4. **Suggestions**

The paper can be improved substantially, and I would encourage the authors to narrow the claim and strengthen the design rather than abandon the project.

First, **reframe the contribution more modestly**. Right now the title, abstract, and introduction claim an estimate of the cost of “financial disclosure,” but the design really identifies a response to a more demanding filing regime. Call it a response to **filing complexity/compliance burden**, not to disclosure in a broad sense. That change would make the paper both more accurate and more defensible. It would also remove the need to argue that 990-EZ is somehow not public, which is incorrect.

Second, **deal seriously with the two-dimensional filing rule**. The 990-EZ applies only below both the receipts and asset thresholds. This matters a lot. At minimum, the main analysis should be restricted to organizations safely below the asset threshold, so that the gross-receipts threshold is the operative margin. Better still, show separate bunching estimates for organizations far below, near, and above the asset threshold. If the effect is really about the revenue filing threshold, it should be strongest where assets do not independently force filing of the full 990. The current asset heterogeneity table is suggestive but not a substitute for aligning the sample with the actual rule.

Third, **replace the cross-sectional “legacy bunching” argument with real time variation if at all possible**. This is the paper’s largest missed opportunity. If you can obtain annual Form 990/990-EZ microdata or annual BMF snapshots with filing-year information, you should directly estimate bunching around \$100K before 2010 and around \$200K after 2010. A simple event-study style figure showing the density around the old and new thresholds by year would be far more convincing than the current cross-sectional placebo discussion. If such data are impossible to assemble, then the paper should stop leaning on the reform as if it had been used for identification.

Fourth, **rethink inference and robustness in a way consistent with the bunching literature**. Because this is essentially the universe, classical sampling uncertainty is not the main issue; specification uncertainty is. The Poisson bootstrap over bin counts is not obviously the right object here, especially when the main concern is sensitivity to polynomial order and excluded range. I would suggest:
- reporting a full grid of estimates over polynomial orders and bandwidth/excluded-region choices,
- showing the implied counterfactual fits graphically,
- implementing the standard excess-mass/missing-mass balancing logic more transparently,
- and, ideally, using procedures closer to those in the canonical bunching literature rather than a simple parametric perturbation.

A seasoned reader will care much more about whether the estimate is stable under reasonable counterfactuals than about whether the reported \(t\)-statistic is 3.9 versus 3.2.

Fifth, **show the distribution visually and let the reader judge the local nature of the response**. The paper reports some informative numbers, but this is a design where figures matter enormously. I would want:
1. a histogram around \$200K with the fitted counterfactual overlay;
2. analogous figures for \$50K and \$100K;
3. figures by asset group;
4. and, if possible, a manipulation window chosen by visual plus formal criteria rather than imposed somewhat mechanically.

At present, the large increase in estimated \( \hat b \) as the window expands suggests the “bunching mass” may not be local. A graph would clarify whether there is a true spike just below \$200K or a broader left-skewed distribution that the polynomial fit is struggling to capture.

Sixth, **interrogate plausibility of magnitudes more carefully**. The paper says 941 organizations bunch, about 0.7% of those in the \$100K–\$300K range. That is not implausibly large in level terms, but the normalized excess mass of 1.5 is substantial, and the heterogeneity estimates are very large: \( \hat b = 5.45 \) for religious organizations and a negative \( \hat b \) for large-asset organizations. Those subgroup patterns could be real, but they also look like what one gets from thin-cell estimation plus unstable counterfactuals. I would report subgroup histograms, subgroup counterfactual fits, and raw bin counts around the threshold for each heterogeneity split. Otherwise the mechanism claims outrun the evidence.

Seventh, **drop the McCrary-style mean-comparison test** or demote it sharply. Comparing average counts in the ten bins below and above the threshold is not a substitute for a density discontinuity test and, in this context, adds little beyond the bunching exercise itself. It may even be misleading because it conflates local bunching with broader shape differences in the distribution.

Eighth, **clarify what “manipulate reported revenue” means**. The paper oscillates between misreporting, timing, and real activity responses. Those are economically different mechanisms. If organizations can defer receipts, accelerate expenses, split activities across affiliates, or simply manage the recognition of gross receipts, that is different from literal misreporting. The paper should use more careful language unless it has evidence of accounting manipulation specifically.

Ninth, **make the state-regulation analysis concrete or drop it**. The current exercise is too rough to support the interpretation offered. If you keep it, define the state rules clearly, motivate the grouping ex ante, and report a proper interaction framework rather than two summary estimates. Better yet, use known state charitable registration/audit thresholds from prior work and ask whether bunching at \$200K is attenuated where state reporting already imposes similar fixed costs.

Finally, **tighten the paper around one result**. The strongest version of this paper is not “we estimate the implicit cost of nonprofit disclosure.” It is: *there is credible evidence of behavioral response to the Form 990 filing threshold, concentrated among organizations for which fixed filing burdens are likely to matter most.* That is a clear and economically meaningful result if established carefully. The current draft reaches for more than the design can support and, as a result, weakens an otherwise promising idea.

My overall assessment: promising topic, good institutional motivation, but the present draft is not yet AER: Insights-ready. The paper needs a more credible identification strategy, a more accurate statement of mechanism, and a more disciplined bunching implementation.
