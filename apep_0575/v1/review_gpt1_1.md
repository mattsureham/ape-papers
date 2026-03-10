# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T14:48:03.188913
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 19975 in / 4967 out
**Response SHA256:** f78a749e0ddcc0a8

---

This paper studies whether the EU BRRD changed the maturity composition of household deposits, exploiting staggered national transposition across 19 EU countries. The topic is important, the institutional setting is potentially attractive, and the paper is commendably aware of recent staggered-DiD concerns. The use of Callaway-Sant’Anna (CS) rather than relying exclusively on TWFE is a real strength. That said, in its current form I do not think the paper is publication-ready for a top field or general-interest outlet. The central concerns are not cosmetic; they go to whether the paper has isolated a credible treatment, and whether the reported inference is strong enough to sustain the headline claim.

My overall view is that the paper contains an interesting empirical pattern, but the causal interpretation remains too fragile. In particular, the treatment timing is conceptually muddled, the identifying variation is very compressed, and the main inference leans on borderline significance with methods that are not adequate for a 19-cluster staggered-adoption setting. The paper would need a substantial redesign of identification and inference to be publishable.

## 1. Identification and empirical design

### 1.1 Is transposition the right treatment?
This is the most important issue in the paper.

The paper defines treatment as national BRRD transposition dates (Sections 2, 5), arguing that these dates are “the relevant moment for household awareness and behavioral response.” But the institutional discussion itself makes clear that the bail-in tool was mandated from **January 1, 2016**, and that the Single Resolution Mechanism also became operational at that time (Section 2.3). This creates a basic ambiguity:

- If the economically relevant shock is **legal salience/awareness**, transposition may be appropriate.
- If the relevant shock is **actual exposure to enforceable bail-in**, then the common activation date in 2016 is the relevant treatment.
- If households responded to **high-profile resolution events** (Italy 2015, Banco Popular 2017), then neither transposition nor the common 2016 date fully captures treatment.

The paper acknowledges this in places (Sections 2.2, 7.4), but it does not resolve it. This is not a minor caveat: it goes directly to whether the staggered adoption design identifies BRRD effects at all. Because nearly all countries in the analysis adopt within a very narrow window (December 2014–December 2015 in the 19-country sample), and because the common bail-in activation date sits immediately after that window, it is hard to distinguish “country-specific transposition effects” from anticipation of a common 2016 regime change.

In other words, the design is much closer to a short-window rollout around a common Europe-wide reform than to a clean staggered policy experiment.

### 1.2 Compressed treatment timing severely limits identification
The regression sample has only 19 countries, all treated by December 2015 (Section 6.2 footnote). That means:

- the not-yet-treated control group disappears quickly;
- the CS ATT is identified off a narrow set of early post-treatment comparisons;
- long-run post effects are not identified using not-yet-treated controls;
- the key dynamic period overlaps almost perfectly with the run-up to the common January 2016 activation date.

This is especially problematic because the event study is interpreted as showing effects beginning 6 months after transposition. For early adopters, that places the response squarely in mid/late 2015, just before the common 2016 implementation and around salient Italian resolution events. The event-study timing therefore does not cleanly validate the transposition interpretation.

### 1.3 Parallel trends are asserted more strongly than established
The paper points to flat pre-trends in the CS event study (Sections 5.1, 6.2). That is useful, but not sufficient here.

Why not?

1. **Low power**: with 19 clusters and staggered timing compressed into one year, the pre-trend test is weak.
2. **Potential differential macro exposure**: countries with larger uninsured shares are systematically different (wealth, banking structure, interest-rate pass-through, product availability). Month fixed effects absorb common shocks, but not heterogeneous responses to QE/negative rates or country-specific banking stress.
3. **Institutional endogeneity**: transposition timing may indeed reflect legislative capacity, but the paper does not convincingly demonstrate that it is orthogonal to bank fragility, supervisory readiness, or national resolution politics.

The statement in Section 2.3 / Section 5.1 that timing reflects “not primarily differences in banking sector fragility” is asserted, not shown.

A stronger paper would provide direct evidence that transposition timing is unrelated to pre-BRRD banking conditions, sovereign stress, or pre-trends in deposit maturity composition.

### 1.4 The sectoral comparison is not a convincing exclusion test
The paper uses non-financial corporate deposits as a within-country comparison (Sections 5.2, 6.4), but correctly notes corporates are also subject to the BRRD. This makes them an imperfect placebo. I would go further: they are not a placebo in the causal-inference sense.

Corporate deposit behavior differs from household behavior for many reasons besides deposit insurance:
- cash management,
- treasury constraints,
- substitution into money market instruments,
- wholesale funding conditions,
- differences in pass-through of rates.

As a result, the absence of a corporate response does not validate the household causal interpretation, and the insignificant DDD does not support household specificity. The paper does admit the DDD lacks power, but some textual claims still overuse this comparison.

### 1.5 Treatment-intensity design is interesting but underidentified
The interaction of Post × Uninsured Share is potentially the most interesting part of the paper. But it is not yet a convincing causal design.

Concerns:
- The uninsured-share measure is from **2015** (Section 4.3), which is post-treatment for many early adopters.
- The measure may proxy for many country characteristics unrelated to bail-in salience: wealth distribution, market structure, savings products, housing wealth, tax treatment, banking concentration.
- With country and month FE, the interaction is identified off differential post-2015 trends in high- versus low-uninsured countries. Without allowing for differential pre-trends by uninsured exposure, this is vulnerable to omitted-trend bias.
- The paper interprets the positive agreed-maturity interaction as “insurance optimization,” but this remains speculative. Aggregate country-level shares cannot distinguish reallocation within banks, across banks, or changes in deposit supply.

The interaction results are not “the most compelling evidence” unless the paper shows:
1. no differential pre-trends by uninsured exposure;
2. robustness to interacting uninsured share with flexible time trends or pre-period-only placebo trends;
3. that the 2015 uninsured-share proxy is not contaminated by the reform itself.

## 2. Inference and statistical validity

This is the second major concern.

### 2.1 Main result depends on borderline significance with weak inference choices
The headline result is a CS ATT of 0.67 pp with **p = 0.041** using **analytical (pointwise) SEs with 19 clusters** (Abstract; Section 6; Table 2). That is too fragile to support the paper’s level of causal confidence.

For a top journal, I would expect:
- multiplier/bootstrap inference for CS as the main reported uncertainty measure;
- simultaneous confidence bands for event studies, not just pointwise bands;
- explicit treatment of small-cluster inference;
- robustness of significance to wild bootstrap or randomization/permutation methods tailored to the preferred estimator.

The paper briefly states in Section 7.4 that a 1,000-iteration multiplier bootstrap gives p = 0.035, but this result is not reported in the main tables and is not integrated into the inferential framework. As written, the paper’s core claim still rests on the analytical p-value.

### 2.2 Inference is inconsistent across estimators
Table 3 compares:
- TWFE with country-clustered SEs,
- CS with analytical SEs,
- SA with country-clustered SEs.

These are not directly comparable inferential objects. In a 19-country design, differences in standard-error construction matter materially. The paper interprets the sign and significance contrast across estimators as evidence of TWFE bias, but some of the contrast may also reflect non-comparable uncertainty procedures and unstable weighting.

### 2.3 The Sun-Abraham estimate appears unstable
The SA estimate is 3.10 pp, versus 0.67 pp for CS—a 4.6x gap (Section 6, Table 3). The paper notes that **83 interactions were dropped due to collinearity**. This is a major warning sign. With so many dropped cells in such a small sample, the SA estimate should not be treated as corroborating evidence. At most, it shows direction. More honestly, it suggests the design is too thin for stable cohort-event decomposition.

### 2.4 Event-study inference is inadequate
The paper states that pre-treatment coefficients are insignificant and “flat.” But with this design, a formal pre-trend assessment should include:
- joint tests, not only visual inspection / individual insignificance;
- simultaneous bands;
- reporting how many leads are effectively identified and with what support;
- perhaps binned event times to avoid sparse-cell noise.

Given the quick exhaustion of not-yet-treated controls, late post-treatment event times are weakly or not identified. The paper notes this in a footnote, but the main text still draws dynamic conclusions (“gradual increase”) more strongly than the design warrants.

### 2.5 Randomization inference is applied to the wrong estimator
Appendix B presents randomization inference for TWFE only and uses the null result to underscore TWFE bias. That does not help validate the preferred estimate. If the preferred estimator is CS, the paper should provide design-based inference for that estimator or for a statistic tightly linked to the main claim.

### 2.6 Sample sizes and outcome coherence
The sample sizes are clearly reported and mostly coherent. That is a strength. However:
- the redeemable-at-notice series is only available for 17 countries;
- the three shares are parts of a composition, and estimated separately;
- one should be careful that interpretations across outcomes respect the adding-up constraint.

This is not fatal, but the paper should more explicitly reconcile the estimated changes across the three shares. For example, the intensity estimates imply a large decline in agreed-maturity main effect and offsetting positive interaction, while overnight moves the other direction. A more systematic compositional accounting would help.

## 3. Robustness and alternative explanations

### 3.1 Robustness is too focused on TWFE
The robustness appendix relies heavily on TWFE exercises (leave-one-out, GIIPS exclusion, RI on TWFE). But the paper’s central methodological claim is that TWFE is biased here. Once that claim is accepted, robustness exercises based on TWFE are of limited value.

The paper needs robustness checks built around the **preferred identification strategy**, not the rejected one.

### 3.2 Alternative explanations are not fully addressed
Key alternatives include:

1. **Common 2016 bail-in activation**
   - already discussed above;
   - likely first-order.

2. **ECB QE / negative-rate environment**
   - month FE absorb common levels, but not heterogeneous pass-through across countries with different banking structures.
   - countries with more uninsured deposits may also have different term-deposit pricing responses.

3. **Banking-union bundle effects**
   - SSM (Nov 2014), SRM (Jan 2016), EDIS discussions, national resolution communications.
   - The paper acknowledges this, but the empirical strategy does not disentangle BRRD from the broader regulatory package.

4. **Salient resolution events**
   - Italy 2015 and Banco Popular 2017 plausibly changed depositor beliefs.
   - These events are treated more as mechanism narrative than as competing treatments.

5. **Interest-rate incentives**
   - The “insurance optimization” story relies on term-deposit yield spreads, but no data on rate spreads are shown.
   - Without this, the mechanism is speculative.

### 3.3 Placebo tests are not sufficiently probative
The publication-date placebo (Appendix C) is useful but limited:
- it is estimated in a pre-period-only sample;
- it is not shown for the preferred CS framework;
- it tests one anticipation channel, but not anticipation of the common 2016 activation;
- it does not address differential trends by uninsured exposure.

A stronger set of placebo/falsification tests would include:
- pseudo-treatment dates in earlier years;
- placebo outcomes less likely to be affected by bail-in salience;
- pre-period trend interactions with uninsured share;
- country-specific linear trends and/or exposure-specific trends.

### 3.4 Mechanism claims exceed the evidence
The paper is often appropriately cautious (“suggestive,” “one interpretation”), but the intensity result is repeatedly framed as evidence of “insurance optimization.” This remains conjectural. Aggregate country-level maturity shares cannot identify:
- deposit splitting across banks,
- within-household below-threshold optimization,
- search for yield,
- bank-side product repricing,
- substitution driven by bank funding demand.

At present, the paper establishes at most heterogeneous reduced-form changes in aggregate deposit composition by country exposure, not the mechanism behind those changes.

## 4. Contribution and literature positioning

The topic is potentially publishable: depositor responses to resolution regimes are underexplored, and linking bail-in rules to liability maturity composition is interesting. The paper also appropriately cites the modern staggered-DiD literature.

That said, the contribution relative to prior work needs sharper positioning on two fronts.

### 4.1 Policy-domain literature
The paper cites some relevant BRRD/bail-in work, but the literature review could better connect to:
- depositor discipline and uninsured deposit behavior;
- bank funding structure under resolution regimes;
- depositor responses to insurance thresholds and guarantee changes.

Concrete papers to consider adding/discussing:
- Martinez Peria and Schmukler on depositor discipline in crisis settings;
- Iyer and Puri / Iyer et al. on depositor responses and bank runs;
- Egan, Hortaçsu, and Matvos (already cited) should be more directly connected to uninsured-deposit competition;
- literature on deposit reallocation under guarantee reforms or bank risk salience.

### 4.2 Methodological positioning
The paper cites Callaway-Sant’Anna, Sun-Abraham, and Goodman-Bacon, but should also discuss:
- de Chaisemartin and D’Haultfoeuille on staggered DiD and weighting/pathologies;
- Borusyak, Jaravel, and Spiess on imputation-based DiD/event studies.

Given the instability between CS and SA here, it would be especially useful to benchmark an imputation estimator.

## 5. Results interpretation and calibration of claims

### 5.1 The paper is mostly careful, but still somewhat over-claims relative to evidence
The abstract and conclusion are more cautious than the body, which is good. Still, some claims should be toned down:

- “The intensity-interaction results provide the paper’s most compelling evidence” (Section 6.3) is too strong given the lack of trend-interaction validation and the post-treatment intensity measure.
- “The CS estimator… tells a different story” (Section 6.1) is fair descriptively, but not enough to conclude the causal sign is established.
- Policy implications in Section 7.5 go beyond the empirical support. The estimated average effect is tiny, unstable across estimators, and only marginally significant.

### 5.2 Magnitude instability is a major interpretive problem
The paper acknowledges the 0.67 pp vs. 3.10 pp gap. I agree with the authors that this warrants caution. But the paper still proceeds as if the CS estimate is the credible magnitude. I am not convinced. Given:
- 19 clusters,
- compressed treatment timing,
- dropped SA interactions,
- common 2016 shock,
the paper has not yet demonstrated stable identification of either sign or magnitude beyond “there may be a modest positive average effect on overnight shares.”

### 5.3 The corporate null should not be interpreted as confirming household specificity
The paper eventually concedes lack of power and the non-placebo nature of corporate deposits. That should be moved forward and emphasized more strongly. As it stands, the discussion risks implying more evidentiary value than Table 4 supports.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

1. **Rebuild the treatment-timing argument**
   - **Why it matters:** The core causal interpretation hinges on whether transposition is the correct treatment rather than the common January 2016 activation or salient resolution events.
   - **Concrete fix:** Re-estimate the design around alternative treatment definitions:
     - national transposition date,
     - common January 1, 2016 activation date,
     - event-study interactions around salient resolution events,
     - possibly a stacked/event-specific design.
     Show which timing assumption is actually supported.

2. **Provide valid main inference for the preferred estimator**
   - **Why it matters:** A p-value of 0.041 from analytical SEs with 19 clusters is not sufficient.
   - **Concrete fix:** Make bootstrap/multiplier inference the main reported uncertainty for CS; report simultaneous confidence bands for event studies; include wild-cluster/bootstrap sensitivity where possible; avoid leaning on pointwise analytic significance.

3. **Address differential trends in the treatment-intensity design**
   - **Why it matters:** Post × Uninsured may be capturing differential macro trends rather than treatment heterogeneity.
   - **Concrete fix:** Add pre-trend/event-study versions of the exposure interaction; test for pre-period exposure-specific trends; include robustness to country-specific trends and flexible interactions with pre-treatment characteristics.

4. **Resolve or substantially downgrade the SA corroboration claim**
   - **Why it matters:** With 83 dropped interactions, the SA estimate is too unstable to present as confirmation.
   - **Concrete fix:** Either (i) add an imputation-based staggered estimator (e.g., Borusyak-Jaravel-Spiess) and compare results, or (ii) demote SA to a fragile sensitivity check and stop presenting it as corroborating magnitude.

5. **Demonstrate exogeneity/plausibility of transposition timing**
   - **Why it matters:** The identification argument currently rests on assertion.
   - **Concrete fix:** Show correlations (or lack thereof) between transposition timing and pre-treatment bank fragility, sovereign spreads, crisis exposure, deposit growth, and pre-trends in maturity shares.

### 2. High-value improvements

6. **Use pre-treatment intensity data or justify 2015 exposure more convincingly**
   - **Why it matters:** The uninsured-share measure may be post-treatment for early adopters.
   - **Concrete fix:** If earlier EBA/DGS or related coverage data exist, use pre-2015 values. Otherwise, provide evidence of stability using multiple years and show results are unchanged.

7. **Reframe the sector comparison**
   - **Why it matters:** Corporate deposits are not a clean placebo.
   - **Concrete fix:** Present this as a suggestive contrast only; do not treat it as an exclusion restriction test. If possible, add better placebo outcomes/sectors.

8. **Develop mechanism evidence or scale back mechanism claims**
   - **Why it matters:** “Insurance optimization” is plausible but currently speculative.
   - **Concrete fix:** Either add supporting evidence (e.g., term-vs-overnight rate spreads, bank account proliferation, cross-bank deposit fragmentation if available) or reframe as a hypothesis rather than interpretation.

9. **Report support/weighting diagnostics for the CS estimates**
   - **Why it matters:** With rapid treatment saturation, effective comparisons may be very limited.
   - **Concrete fix:** Show which cohorts and event times identify the ATT, the distribution of weights, and how results change when restricting to horizons with sufficient untreated support.

10. **Add more credible falsification tests**
   - **Why it matters:** Existing placebo checks are limited.
   - **Concrete fix:** Use pseudo-reform dates in earlier years; placebo outcomes not directly tied to maturity restructuring; exposure-placebo interactions in the pre-period.

### 3. Optional polish

11. **Clarify compositional implications across the three shares**
   - **Why it matters:** Separate regressions on shares that sum to one can obscure accounting consistency.
   - **Concrete fix:** Add a simple table reconciling implied reallocation across categories, or estimate a compositional/system framework as a supplement.

12. **Calibrate policy discussion more conservatively**
   - **Why it matters:** Policy implications currently outrun the precision and identification strength.
   - **Concrete fix:** Emphasize that the paper documents suggestive portfolio reallocation under one interpretation of BRRD timing, rather than established effects on financial fragility.

## 7. Overall assessment

### Key strengths
- Important and timely policy question.
- Potentially interesting institutional setting.
- Good awareness of modern staggered-DiD issues; not relying solely on TWFE is a major plus.
- Clear acknowledgment of several limitations.
- The treatment-intensity heterogeneity angle is promising.

### Critical weaknesses
- The treatment itself is not cleanly defined: transposition vs. common 2016 activation vs. salient resolution events.
- Identification relies on a narrow stagger window with quick exhaustion of controls.
- Main inference is too fragile for the claim: 19 clusters, analytical SEs, pointwise event-study bands.
- The SA “confirmation” is unstable due to massive collinearity/dropped interactions.
- Robustness is overly TWFE-centric despite the paper’s own argument that TWFE is biased.
- Mechanism claims are stronger than the aggregate data can support.

### Publishability after revision
I do not think the paper is close to acceptance at a top journal in its current form. However, I do think there is a potentially salvageable paper here if the authors substantially rework the identification strategy and the inferential framework. The most promising path is to treat this as a careful, more modest paper on depositor behavior around BRRD implementation/activation, with much stronger timing tests and substantially more conservative causal claims.

DECISION: MAJOR REVISION