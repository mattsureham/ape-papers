# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T14:48:03.189965
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 19975 in / 5470 out
**Response SHA256:** 384290319a50392a

---

This paper studies whether the EU BRRD changed the maturity composition of household deposits, exploiting staggered national transposition across 19 EU countries and using ECB BSI monthly country-level data. The topic is important, the institutional setting is interesting, and the paper is commendably aware of modern staggered-DiD concerns. However, in its current form, the paper is not publication-ready for a top general-interest or AEJ: Economic Policy outlet. The core problems are (i) treatment timing/identification is not yet convincingly tied to the causal estimand the paper wants, (ii) the main inference is fragile given 19 clusters and reliance on analytical standard errors, and (iii) several robustness exercises are aimed at the wrong estimator or do not address the main identification threats.

I think there is a potentially publishable paper here, but it likely requires substantial redesign or reframing rather than incremental polishing.

## 1. Identification and empirical design

### A. The treatment timing is not yet convincingly aligned with the causal claim
The paper’s central design treats **national BRRD transposition** as the treatment date (Sections 2.3, 5.1). But the institutional discussion itself makes clear that there are at least three conceptually distinct “events”:

1. **EU-level BRRD adoption/publication in 2014**
2. **National legal transposition during Dec 2014–Dec 2015**
3. **Common bail-in tool activation on January 1, 2016** (Sections 2.3, 6.5, 7.4)

The paper argues that transposition is the relevant moment because it “signaled” exposure to households. But that is not enough for a causal design in this setting. The problem is that the paper’s own narrative also emphasizes that:
- the bail-in tool became mandatory on a **common date**;
- salient learning may have come from **Italian resolutions in late 2015** and Banco Popular in 2017;
- the event-study response is **gradual** rather than sharply aligned with transposition (Sections 2.2, 3, 6.2, 7.4).

This leaves the design unable to cleanly distinguish:
- effects of country-specific transposition,
- anticipation of common 2016 activation,
- and later pan-European learning from actual resolution episodes.

The paper explicitly acknowledges this in Section 7.4, but that admission materially weakens the causal interpretation of the headline estimate. At present, the design identifies “something changing around a short staggered legislative rollout embedded in a broader common regulatory transition,” not clearly “the effect of national BRRD transposition.”

### B. Short treatment window and no never-treated units sharply limit identification
All 19 countries are treated by December 2015, with treatment concentrated in a narrow 12–14 month window (Sections 2.3, 6.2). This creates several problems:

- The **not-yet-treated comparison group disappears quickly**, so post-treatment effects are identified only at short horizons.
- The CS event study is therefore based on a rapidly shrinking control pool.
- Later dynamic effects are mechanically not identified, yet the paper interprets gradual post-treatment effects in ways that risk overstating what the design can recover.

The paper notes this in the event-study footnote, but the implications are stronger than stated: the “average ATT” is largely a weighted average of early post-treatment comparisons in a very compressed rollout. For a top journal, the paper needs to be much more explicit about the estimand and exactly which group-time cells identify it.

### C. Parallel trends is asserted more than demonstrated
The paper’s case for parallel trends (Section 5.1) is not strong enough.

- “Different legislative processes” is not an empirical argument.
- The event study is visually reassuring, but with only 19 country clusters and a compressed rollout, pre-trend diagnostics are low power.
- More importantly, the paper does not show that **early and late transposers were similar on pre-trends in deposit composition levels or slopes**, nor that transposition timing was orthogonal to pre-existing banking stress, liability structure, or deposit-market trends.

This matters because transposition timing may have correlated with:
- banking sector fragility,
- legal/institutional capacity,
- domestic implementation of Banking Union reforms,
- country-specific interest-rate pass-through,
- or deposit market trends already underway.

The GIIPS exclusion is not enough, and in any case it is implemented only in the TWFE specification (Section 6.5), not the preferred heterogeneity-robust framework.

### D. The intensity design has a stronger economic idea, but weaker identification than presented
The interaction of Post × Uninsured Share (Sections 5.2, 6.3) may be the most interesting part of the paper, but it currently rests on a demanding and insufficiently defended assumption: absent BRRD, countries with high vs. low uninsured shares would have followed parallel trends in deposit composition.

That is a strong assumption because uninsured exposure plausibly proxies for:
- wealth,
- bank competition,
- deposit rate spreads,
- financial sophistication,
- product mix,
- term-deposit culture,
- and exposure to low/negative interest rates.

None of these are controlled for in differential-trend form. With only country and month fixed effects, the identifying variation comes from whether countries with higher uninsured share change differently after treatment. But if high-uninsured countries already had different trends around 2015–2016 due to ECB policy, rate compression, or secular shifts away from term deposits, the interaction estimate is confounded.

Also, the paper states the uninsured-share measure is from EBA 2015 data and is “predetermined” (Section 4.3), but for early adopters it is measured **after treatment**. Even if slow-moving, this is not ideal, and the paper should not treat it as innocuous without stronger validation.

### E. Sectoral comparison is not a valid exclusion-based placebo
The paper uses corporate deposits as a “within-country test of the exclusion restriction” (Sections 5.1, 6.4). That overstates what the exercise can do.

The paper itself acknowledges that corporates are also affected by BRRD and that the DDD interaction is insignificant. Therefore:
- this is **not** a clean placebo,
- it does **not** test the exclusion restriction,
- and it provides at best weak descriptive context.

The fact that the household–corporate differential is statistically insignificant should substantially temper household-specific mechanism claims.

### F. Outcome choice is compositional, but the empirical strategy does not fully respect that
The dependent variables are deposit shares that sum approximately to one. Yet the paper estimates separate linear models and then mixes robust and non-robust estimators across components:
- overnight: CS/SA emphasized,
- agreed maturity: mostly null,
- redeemable-at-notice: TWFE significant, but only on the reduced 17-country sample.

This makes the compositional interpretation incomplete. A credible claim that households reallocated deposit maturity should show a coherent system-wide shift, not a positive robust effect on one share combined with non-robust evidence on another.

## 2. Inference and statistical validity

### A. The main inference is too fragile for the paper’s current claims
The headline result is:
- CS ATT = 0.67 pp,
- p = 0.041,
- with **analytical standard errors and 19 clusters** (Abstract, Table 2 / robust-estimator table, Section 6.1).

That is not enough for a top outlet. In a 19-cluster panel, relying on analytical/pointwise uncertainty from the `did` package is not persuasive for the main claim, especially when:
- there are no never-treated units,
- treatment is highly compressed,
- and the effect is only marginally significant.

The paper later says a CS multiplier bootstrap gives p = 0.035 (Section 7.4), but this is not shown in the main results table, not integrated into the main inferential framework, and not discussed as the principal basis for statistical significance. It should be.

### B. The large divergence between CS and SA is a major warning sign, not “confirmation”
The paper treats Sun-Abraham as corroborating the CS finding because it has the same sign and is significant. I do not think that is the right interpretation.

The estimates differ by a factor of about **4.6**:
- CS: 0.67 pp
- SA: 3.10 pp

And the paper notes that 83 interactions are dropped due to collinearity (Table 3, Section 6.1, Section 7.3). In a 19-country design, that degree of collinearity means the SA aggregation is unstable and difficult to interpret. This should not be presented as confirmatory evidence. Rather, it indicates the estimand is fragile to implementation and weighting.

At minimum, the paper should add a third modern estimator—e.g. **Borusyak, Jaravel, and Spiess** imputation-based DiD or **de Chaisemartin and D’Haultfoeuille** estimators—to assess whether the main result is robust across modern approaches. Right now, the methodological triangulation increases concern rather than confidence.

### C. Many robustness checks are conducted on the wrong estimator
A recurring problem is that the preferred estimator is CS, but much of the robustness analysis is performed on TWFE:
- leave-one-out,
- GIIPS exclusion,
- randomization inference,
- several placebo checks.

The paper openly acknowledges that TWFE is biased here (Sections 6.1 and 6.5). If so, robustness of TWFE estimates is not informative about robustness of the preferred causal estimate. This is a major mismatch between estimand and robustness design.

### D. Randomization inference on TWFE is not useful evidence for the main claim
The appendix RI exercise permutes treatment timing and re-estimates **TWFE**, then concludes this “underscores the importance” of using heterogeneity-robust estimators. That may be true pedagogically, but it does not validate the paper’s main estimate. A top-journal reader will ask for inference on the actual preferred estimator.

### E. Event-study uncertainty should be interpreted more cautiously
The event-study figures display pointwise 95% confidence intervals. In a setting with few clusters and many leads/lags, this is not a strong pre-trend or dynamic-treatment test. Uniform bands or joint tests are preferable. “All pre-treatment coefficients are insignificant” is not a sufficient pre-trend validation, especially given low power.

## 3. Robustness and alternative explanations

### A. The paper does not adequately rule out alternative macro-financial explanations
The main alternative explanations are substantial and only partially addressed:

1. **ECB QE / negative-rate environment**
2. **Other Banking Union reforms** (SSM, SRM)
3. **Country-specific interest-rate movements / term spread compression**
4. **Actual bank-resolution events and media salience**
5. **Secular substitution from term to overnight deposits during low-rate years**

Month fixed effects absorb common euro-area shocks, but not heterogeneous exposure to those shocks across countries. This is especially problematic for the intensity interaction, where uninsured share could proxy for countries that reacted differently to the low-rate environment.

### B. Placebo timing test is too narrow
The publication-date placebo is useful but insufficient. The more concerning anticipation issue is not EU-wide publication in June 2014; it is anticipation of:
- country-specific transposition,
- the common Jan 2016 activation date,
- and salient resolution episodes.

The paper should show richer lead patterns and perhaps interact leads with uninsured share. Right now, the no-anticipation claim is stronger than warranted.

### C. Mechanism claims are not well separated from reduced-form evidence
To the paper’s credit, it often uses cautious language (“suggestive,” “one interpretation”), but at several points it still leans too heavily into “insurance optimization.” That mechanism is not directly tested. The agreed-maturity interaction could also reflect:
- cross-country differences in term-deposit pricing,
- bank liability management,
- product reclassification,
- or changing composition of depositors/banks.

Without depositor-level or bank-level evidence, the mechanism claims should be further dialed back.

### D. External validity and sample selection need more discussion
The estimation sample excludes five countries for missing maturity breakdowns and three for incomplete coverage (Section 4.1, Appendix A). The paper does not do enough to assess whether excluded countries differ systematically in transposition timing, banking structure, or uninsured-share distribution. Since the sample is only 19 countries, exclusions may materially shape the estimand.

## 4. Contribution and literature positioning

The paper’s contribution is potentially meaningful: depositor-side responses to bail-in regimes are underexplored, and the institutional setting is relevant. The paper is also right to emphasize modern staggered-DiD methods.

That said, the literature positioning could be strengthened in two directions:

### A. Methods literature
The paper should engage more fully with the current DiD literature beyond CS/SA/Goodman-Bacon. At minimum, it should discuss and likely implement:
- **Borusyak, Jaravel, and Spiess (2024, AER)** on imputation/event studies
- **de Chaisemartin and D’Haultfoeuille (2020, AER)** on TWFE with heterogeneous treatment effects
- work on pre-trend testing and low-power diagnostics, e.g. **Roth (2022, AER: Insights)**

These are directly relevant given the paper’s compressed treatment timing and weak pre-trend diagnostics.

### B. Policy/domain literature
The paper cites useful bank resolution and deposit insurance references, but the discussion would benefit from more direct engagement with:
- depositor discipline / depositor behavior under bank risk,
- resolution credibility and depositor expectations,
- and liability-structure adjustments under resolution regulation.

I am not insisting that the domain literature is deficient, but the contribution would be sharper if the paper clarified more explicitly what prior papers have and have not learned about depositor reallocation under bail-in risk.

## 5. Results interpretation and claim calibration

### A. The conclusions should be more conservative
The current title, abstract, and conclusion imply stronger evidence than the paper delivers. The main estimate is:
- small,
- marginally significant,
- dependent on analytical SEs with 19 clusters,
- and not stable in magnitude across estimators.

This is not yet a result on which one can confidently build policy claims about funding stability.

### B. Magnitude interpretation is somewhat overstated
The conversion of a 0.67 pp share effect into roughly €43 billion of overnight deposits (Section 7.1) is mechanically correct only under strong assumptions and gives the estimate more practical concreteness than its uncertainty supports. Given the identification and inference concerns, I would not foreground aggregate-euro magnitudes.

### C. The paper sometimes relies on unsupported contrastive interpretations
Examples:
- “TWFE produces attenuated and sign-reversed estimates” — plausible, but the paper does not actually provide a decomposition or weight analysis for this specific application.
- “The intensity-interaction results provide the paper’s most compelling evidence” — perhaps, but they are also the most vulnerable to omitted differential trends.
- “Corporate deposits show no corresponding effect” — true descriptively, but the paper should emphasize that the formal difference is not statistically distinguishable.

### D. The compositional story is not fully coherent across outcomes
If overnight share rises because households seek liquidity, one expects offsetting declines elsewhere. Yet:
- agreed-maturity effects are mostly null on average,
- redeemable-at-notice significance comes only from TWFE on a smaller sample,
- intensity effects point the other way for high-uninsured countries.

That may be economically interesting, but it means the paper should present a more explicitly heterogeneous and less unified behavioral story.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

**1. Rework the treatment-timing design.**  
**Why it matters:** The paper does not cleanly identify the effect of national transposition versus common activation and later resolution salience. This is the core causal issue.  
**Concrete fix:** Reframe the design around one clearly defended treatment concept. Possibilities:
- a common January 2016 event with cross-sectional exposure heterogeneity;
- or a staggered-transposition design limited to very short horizons and clearly interpreted as a legal-salience effect;
- or a stacked-event approach around transposition with tightly bounded windows.
Whichever path is chosen, the paper must explicitly justify why that timing maps to depositor incentives.

**2. Upgrade inference for the main estimator and make it the basis of all claims.**  
**Why it matters:** The current headline depends on marginal significance with 19 clusters and analytical SEs.  
**Concrete fix:** Report, in the main table, cluster-robust bootstrap or multiplier-bootstrap inference for the CS estimate; if feasible, use wild-bootstrap or randomization-based inference tailored to the preferred estimator. Present confidence intervals, not just p-values. If significance weakens, recalibrate claims accordingly.

**3. Conduct robustness on the preferred estimator, not TWFE.**  
**Why it matters:** TWFE robustness does not validate a CS headline estimate.  
**Concrete fix:** Replicate key checks—leave-one-out, GIIPS exclusion, alternative treatment windows, anticipation leads, sample restrictions—using CS or another heterogeneity-robust estimator.

**4. Address differential-trend concerns in the intensity design.**  
**Why it matters:** Post × Uninsured may capture pre-existing differences in trend by country characteristics rather than BRRD exposure.  
**Concrete fix:** Add:
- pre-trend/event-study interactions by uninsured-share bins or continuous exposure,
- region-specific or exposure-specific linear trends,
- controls/interactions for baseline deposit structure, income/wealth, term-spread proxies, banking concentration, and crisis exposure,
- ideally a pre-period falsification showing high- and low-uninsured countries were not already diverging.

**5. Add at least one additional modern DiD estimator.**  
**Why it matters:** The wide CS–SA divergence signals instability.  
**Concrete fix:** Implement BJS/imputation or de Chaisemartin–D’Haultfoeuille as another benchmark. If estimates continue to vary widely, the paper must foreground that instability.

### 2. High-value improvements

**6. Clarify the estimand and weighting in the CS results.**  
**Why it matters:** With all countries treated quickly, the ATT is a weighted average over a narrow set of identified cells.  
**Concrete fix:** Report cohort-specific and horizon-specific contribution weights, number of identified cells by horizon, and how much of the overall ATT comes from each cohort/window.

**7. Strengthen institutional evidence linking transposition to household awareness.**  
**Why it matters:** The core timing assumption is behavioral awareness at transposition.  
**Concrete fix:** Add evidence from media coverage, Google Trends, national communications, or legal implementation details showing that households plausibly learned at transposition rather than only at common activation or actual resolutions.

**8. Treat the corporate comparison as descriptive, not as an exclusion test.**  
**Why it matters:** Corporate deposits are also treated.  
**Concrete fix:** Rewrite that section to make clear it is a noisy comparison group with different incentives, not a placebo. If possible, find a more credible unaffected or less-affected outcome.

**9. Improve treatment of compositional outcomes.**  
**Why it matters:** The three shares are jointly constrained.  
**Concrete fix:** At least show that the preferred robust estimates imply coherent adding-up across outcomes. Ideally, estimate the main question using log-ratios or another compositional-data approach as a robustness check.

**10. Tighten mechanism claims.**  
**Why it matters:** Insurance optimization remains conjectural.  
**Concrete fix:** Reframe it as a hypothesis unless supported with additional evidence, such as cross-country term spread data, bank product rates, or micro evidence.

### 3. Optional polish

**11. Report all main results with confidence intervals and effect-size comparability.**  
**Why it matters:** Given fragility, intervals are more informative than stars.  
**Concrete fix:** Add 95% CIs to the main result table and discuss economically relevant bounds.

**12. Provide a country-level descriptive appendix on sample selection.**  
**Why it matters:** The 19-country sample is selective.  
**Concrete fix:** Compare included vs. excluded countries on transposition timing, uninsured share, euro-area status, and pre-period deposit composition.

**13. If retaining TWFE discussion, show an actual decomposition.**  
**Why it matters:** The claim of negative weighting is currently asserted, not demonstrated for this application.  
**Concrete fix:** Include a Goodman-Bacon decomposition or equivalent.

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Interesting institutional setting.
- Good instinct to avoid naïve reliance on TWFE in staggered adoption.
- Transparent discussion of some limitations.
- The intensity heterogeneity idea is promising and potentially more informative than the average effect.

### Critical weaknesses
- Treatment timing is not convincingly linked to the causal estimand.
- Main inference is fragile with only 19 clusters and analytical SEs.
- Preferred-estimator results are not subjected to the main robustness exercises.
- CS and SA magnitudes differ dramatically, suggesting instability.
- The most compelling result (intensity interaction) is also highly vulnerable to omitted differential trends.
- Mechanism and policy claims run ahead of what the evidence can currently support.

### Publishability after revision
I do not think this paper is close to acceptance in its current form. However, I do think it could become a serious paper if the authors redesign the empirical strategy around a more defensible treatment concept and rebuild inference/robustness around the preferred estimand. That is a large revision, not a minor one.

DECISION: REJECT AND RESUBMIT