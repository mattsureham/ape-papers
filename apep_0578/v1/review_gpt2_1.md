# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-10T14:05:43.493684
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20160 in / 5694 out
**Response SHA256:** b6c5a51e2677224a

---

This paper asks an important and policy-relevant question: whether the post-2015 reintroduction of internal Schengen border controls reduced economic activity in affected border regions. The topic is well suited to a general-interest or policy journal in principle, and the paper’s central empirical instinct is good: naive staggered DiD estimates are likely contaminated by macro confounding, and the author appropriately tries to move beyond off-the-shelf TWFE.

That said, in its current form I do not think the paper is publication-ready. The core problem is that the paper’s preferred causal interpretation is not yet adequately supported by the design actually available in the data. The paper’s own diagnostics repeatedly show that results are highly sensitive to control-group choice, to whether one uses border vs. interior controls, to whether country-by-year fixed effects are included, and to whether inference is conducted at the regional or border-segment level. Those are not just robustness nuances; they indicate that the identifying variation is weak and potentially not credible for the causal claim as stated.

Below I focus on the scientific substance.

---

## 1. Identification and empirical design

### 1.1 The paper’s causal estimand is not cleanly identified with the current comparison groups

The main causal claim is that temporary Schengen internal border controls have little or no effect on regional GDP per capita. But the design combines treated border regions with two very different control groups: untreated border regions and interior regions (Section 3.2; Section 4). This is problematic because the paper itself shows that border and interior regions differ systematically even within country-year cells.

The strongest evidence is in the placebo analysis (Section 5.5; Appendix C): the “border-type placebo” remains significant even with country-by-year fixed effects (“Placebo borders + C×Y FE” = -0.054, s.e. 0.012). This means that, within a country-year, untreated border regions evolve differently from interior regions for reasons unrelated to treatment. Once this is true, specifications that rely heavily on border-vs-interior contrasts are not credible as isolating the effect of border controls.

This matters directly because after adding country-by-year fixed effects, identification comes only from within-country-year differences. But for several treated countries/segments, there are no natural within-country untreated border controls:

- **France**: no untreated French internal border segment in the sample.
- **Sweden**: no untreated internal border segment.
- **Denmark**: no untreated internal border segment.
- **Germany** and **Austria** have some untreated borders, but only a few.

So the country-by-year FE specification is, in practice, often comparing treated border regions to interior regions within the same country-year. The placebo evidence indicates that this comparison is not safe. As a result, the paper cannot simply treat the country-by-year FE estimate in Table 1, col. (6) as the causal benchmark.

### 1.2 The paper overstates what Callaway–Sant’Anna solves here

The paper presents the Callaway–Sant’Anna (CS) estimator as a preferred specification (Abstract; Section 4.2; Table 1 col. 7). CS is appropriate for staggered adoption with heterogeneous effects, but it does **not** solve the central confounding issue here if untreated units are on different country-specific trajectories than treated units. The paper states that CS “partially absorbs” country trends through doubly robust adjustment (Section 5.1), and later says adding country indicators as covariates leaves the CS estimate unchanged (Section 5.5). Neither is persuasive for time-varying national shocks.

Country indicators are time-invariant covariates; they do not absorb country-specific time shocks. If the concern is France vs. Germany vs. Denmark macro trajectories after 2015, including country dummies in CS does not address that. More fundamentally, because many treated countries lack untreated border controls, the CS estimate still leans on cross-country comparisons and/or border-vs-interior comparisons whose validity is doubtful given the placebo evidence.

Thus the current manuscript uses a heterogeneity-robust estimator to address the wrong first-order problem. The main threat is not only staggered-adoption bias; it is lack of a credible counterfactual for treated border regions.

### 1.3 Treatment assignment is coarse relative to actual exposure

Section 2 emphasizes that controls were concentrated at selected crossings and often selectively enforced, with delays of 5–30 minutes and many smaller crossings left uncontrolled. Yet treatment is assigned at the entire NUTS3-region-by-border-segment level (Sections 2.2, 3.2, Appendix A.2) based on whether a region borders the relevant national border.

This introduces substantial exposure mismeasurement:

- Not all border-adjacent NUTS3 regions are equally exposed.
- Large NUTS3 regions may contain little traffic through controlled crossings.
- “France–all borders” is especially heterogeneous, as the paper acknowledges (Sections 2.5, 5.4).

Classical attenuation is one possibility, but nonclassical bias is also plausible if the most exposed crossings differ systematically from low-exposure border areas. At a minimum, the paper should distinguish adjacency from actual intensity of cross-border interaction pre-treatment (commuting, freight, bridge/tunnel crossings, customs posts, traffic counts, etc.). Right now, treatment is too blunt for the mechanism the paper wants to study.

### 1.4 Timing is only partially coherent at annual frequency

The treatment begins in September/November 2015 for most segments and January 2016 for Denmark–Germany (Section 3.3), but outcomes are annual. The paper acknowledges that 2015 is only a partial-exposure year. That is fine as a caveat, but it has bigger implications than the paper allows:

- Event time 0 is not interpretable as a common treatment period.
- The “2015 cohort” pools units with only 1–4 months of exposure in that calendar year.
- Dynamic treatment profiles at annual frequency will be blurred, especially with only two cohorts and few treated segments.

This does not invalidate the paper, but it substantially weakens the precision and interpretability of dynamic claims.

### 1.5 Spillovers are likely and not well handled

The paper notes spillovers briefly (Section 4.3), but they are likely first-order in this setting. Untreated border regions may gain or lose traffic, commuters, or logistics activity when nearby treated crossings face controls. Interior regions may also be affected through rerouting or national responses. If so, “never-treated” regions are not stable controls in the usual DiD sense.

Given that the untreated border sample is tiny and plausibly affected by displacement, the identifying assumptions need a much fuller discussion and ideally tests based on distance-to-treated-border or border-network adjacency.

---

## 2. Inference and statistical validity

### 2.1 Region-clustered standard errors are not adequate for the main treatment variation

The paper is admirably transparent that there are effectively only six treated border segments (Section 4.4). Once treatment varies at that level, region-clustered standard errors are not appropriate as the main basis for inference. The paper says this, but does not follow through consistently.

Nearly all tables report region-clustered SEs as if they are the main inferential object:

- Table 1
- Table 2
- Event studies
- Segment-specific regressions
- Robustness table

Yet the segment-level randomization inference (RI) result in Section 5.5/Appendix C indicates that the baseline TWFE estimate is **not** statistically distinguishable from chance at the assignment level (p = 0.67). This should fundamentally reframe the paper’s inference, not just appear as one robustness check.

At minimum, assignment-level inference needs to be primary for all main estimands, not only for one TWFE coefficient.

### 2.2 There is a serious internal inconsistency on power and RI results

The manuscript contains a direct contradiction:

- **Abstract**: “Segment-level randomization inference (p = 0.67) confirms that with only six treated border segments, the design lacks power to detect moderate effects.”
- **Introduction**: “First, it is not an artifact of low power. The randomization inference p-value is 0.002...” and then claims detectability is not the issue.

These cannot both be true. The text is mixing region-level and segment-level permutation inference, but the narrative treats them inconsistently. This is not merely a presentation issue; it reflects unresolved uncertainty about what the effective design actually is. Given assignment at the segment level, the p = 0.67 result is the more relevant one.

### 2.3 Inference is especially fragile for heterogeneity and event-study results

The paper reports many segment-specific effects and event-study coefficients with region-clustered SEs:

- Table 2 segment heterogeneity
- Figure 3 / Figure 6 event studies
- Cohort ATT claims

But with only six treated segments and two treatment cohorts, these standard asymptotics are weak. This is especially problematic when the paper uses strong language about “striking heterogeneity” and interprets signs/magnitudes across segments. Those segment estimates may mostly reflect country-level trends, and the uncertainty is understated.

The problem is amplified by multiple testing. The paper highlights isolated significant post-treatment event-study points (e.g., event time +6 in CS, +9 in SA) and some significant long leads, but then downplays them as artifacts. That selectivity underscores the need for simultaneous inference and assignment-level uncertainty, not conventional pointwise confidence intervals.

### 2.4 The CS estimate is reported without inference tailored to few treated groups

The CS estimator in Table 1, col. (7) is reported with analytical SEs. But when the number of treated groups/cohorts is very small, asymptotic approximations are fragile. The paper should provide inference that reflects the small number of treated segments/cohorts—for example, permutation-based inference, placebo reassignments at the segment level, or other finite-sample approaches tailored to the actual assignment mechanism. Without that, the precision of the preferred estimate is overstated.

### 2.5 Sample counts and windows need clearer statistical accounting

Some sample accounting is coherent, but there are enough moving parts that the reader cannot easily verify which variation identifies which estimate:

- Full panel: 618 regions, 14,999 observations.
- CS balanced sample: 617 regions, 12,340 observations.
- SA sample: 4,582 observations, border-only.
- Trade/transport sample: 4,545 observations, 185 regions.

These shifts are important, especially because some substantive claims depend on selected subsamples. The trade-sector result in particular is not comparable to the main GDP result, and the paper should not place much weight on it without more careful discussion of selection and inferential comparability.

---

## 3. Robustness and alternative explanations

### 3.1 The robustness exercises expose design fragility more than robustness

The paper presents many robustness checks, but collectively they show the estimate is highly unstable:

- baseline TWFE: -0.027
- country×year FE: 0.000
- border-only + country×year FE: +0.057
- border controls only with untreated border controls: +0.022 (insignificant)
- interior-only controls: -0.034
- leave out France: +0.032
- leave out Germany–Austria: -0.083

This is not a story of a robust null. It is a story that the sign and magnitude depend heavily on which comparisons are used. That may still be publishable, but only if the paper is reframed as: **aggregate regional data do not support a well-identified causal estimate because plausible comparison groups yield sharply different answers**. The current framing (“the effect is essentially zero once one absorbs national trends”) goes too far relative to the evidence.

### 3.2 Placebo tests are informative, but not interpreted strongly enough

The placebo results are among the most important findings in the paper:

- fake treatment on unaffected borders is significantly negative;
- fake timing in 2010 is significantly negative under baseline TWFE;
- border-placebo remains strongly significant even with country×year FE.

These results undermine the baseline design much more than the paper admits. They show both:
1. untreated border regions are not interchangeable with treated border regions/internals in simple TWFE;
2. interior regions are poor controls for border regions even within country-year cells.

These placebo results should be central to the identification discussion, not ancillary robustness checks.

### 3.3 Mechanism claims are underidentified

The paper suggests selective enforcement, adaptation, and local employment gains as possible mechanisms (Section 6.1), and interprets the employment increase and trade/transport decline along those lines. But the mechanism evidence is weak.

- Employment increase is only shown in naive TWFE without country×year FE.
- Trade/transport decline comes from a selected sample and cannot be estimated with country×year FE.
- No direct measures of commuting, traffic, delays, retail, tourism, or logistics are used.

Thus the manuscript should distinguish much more sharply between:
- reduced-form aggregate evidence, which is already fragile;
- speculative mechanisms, for which there is little direct empirical support.

### 3.4 External validity is reasonably discussed, but should be sharpened

To the paper’s credit, it repeatedly states that the results apply to the post-2015 “soft” controls, not to full Schengen collapse or hard customs borders (Sections 6.3–6.4; Conclusion). That calibration is appropriate.

However, because the paper’s own identification is weak, even the narrower external claim should be stated cautiously: the analysis suggests no robust effect on annual NUTS3 GDP, but cannot rule out moderate effects, transitory effects, or effects concentrated among highly exposed border corridors.

---

## 4. Contribution and literature positioning

### 4.1 The substantive question is original and potentially important

The paper’s best feature is the topic. There is real value in moving from simulation-based claims about Schengen reversal to empirical quasi-experimental evidence. The attempt to combine Schengen institutional detail with modern DiD tools is promising.

### 4.2 The empirical contribution is currently overstated

The paper says it provides “the first quasi-experimental evidence” and frames the result as a substantive null on the cost of temporary controls. Given the design weaknesses above, that claim should be moderated. The paper’s actual contribution at present is more methodological/substantive cautionary:

- naive estimates confound macro national trajectories with border treatment;
- assignment-level inference is much weaker than region-level inference;
- available regional aggregates may be too coarse to identify the effect cleanly.

That is still useful, but it is not yet a definitive causal estimate.

### 4.3 Literature coverage is decent but a few strands deserve stronger integration

The paper cites the main staggered-DiD papers and some policy-domain references. But it should more directly engage literatures on:
- spatial spillovers/interference in DiD settings;
- few-treated-cluster inference;
- border-region labor mobility/commuting and cross-border integration in Europe;
- treatment-intensity measurement in geographic policy evaluation.

Concrete additions that would improve positioning:
1. **Athey and Imbens (2022), “Design-based analysis in Difference-in-Differences settings with staggered adoption.”** Relevant because the paper’s assignment mechanism is sparse and clustered.
2. **Roth, Sant’Anna, Bilinski, and Poe (2023), “What’s Trending in Difference-in-Differences?”** Already cited generically, but should be used more substantively in discussing trend violations and placebo failures.
3. **Ferman and Pinto (2019)** and related few-cluster inference papers should be more central, not peripheral, since the effective treated-cluster count is tiny.
4. Work on **spatial interference / spillovers in DiD** should be cited, because untreated borders and interior regions may be indirectly affected.

I would also encourage more direct engagement with empirical work on intra-European cross-border commuting and local labor markets, since that is the most plausible channel through which “soft” controls might matter.

---

## 5. Results interpretation and claim calibration

### 5.1 The paper overstates confidence in a null effect

The manuscript often interprets the country×year FE estimate and the CS estimate as showing the effect “vanishes” or is “precisely estimated at zero” (Abstract; Section 5.1; Section 6.1). That is too strong.

Given:
- few treated segments,
- poor untreated-border support within treated countries,
- significant placebo differences between border and interior regions even with country×year FE,
- coarse annual exposure measurement,
- and highly specification-sensitive estimates,

the correct conclusion is weaker: **the paper does not uncover a robust, design-insensitive negative effect on annual regional GDP; however, the available aggregate design cannot credibly pin down a tight causal null**.

### 5.2 The interpretation of the trade/transport effect is not sufficiently disciplined

The paper highlights the -8.4% trade/transport GVA result as meaningful even while acknowledging the small, selected sample and lack of country×year FE. As written, the manuscript gives this estimate too much prominence relative to its credibility. In a top-journal paper, that result would need:
- a clearly stated selected-sample interpretation,
- stronger evidence of comparability,
- and preferably a design that removes national sectoral shocks.

Absent that, it should be presented as suggestive only.

### 5.3 The segment-specific estimates should not be given quasi-structural meaning

The paper interprets the Germany–Austria, France, and Austria–Hungary estimates as evidence of heterogeneity, but then immediately says they likely reflect country-level trajectories. I agree with the latter. Therefore the former should not be emphasized as substantive treatment heterogeneity. With current identification, Table 2 mostly documents that segment-level treated areas are embedded in countries with different macro paths.

### 5.4 Contradictions in the text need substantive resolution

Beyond the RI contradiction noted above, the manuscript oscillates between three narratives:
1. the baseline negative effect is statistically real but not causal;
2. the preferred estimate is essentially zero;
3. the design lacks power to detect moderate effects.

All three cannot simultaneously be the headline. The paper needs a tighter and more coherent scientific claim.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the identification strategy around credible within-country border comparisons, or explicitly downgrade the causal claim
- **Issue:** Current identification relies too much on border-vs-interior and cross-country comparisons that the placebo tests show are problematic.
- **Why it matters:** This is the central threat to causal interpretation.
- **Concrete fix:** Re-estimate the main design using only untreated border regions as controls where feasible, ideally within-country. If some treated countries have no untreated border controls, be explicit that those segments are not credibly identified in a border-only DiD. Consider reporting estimands separately for countries/segments with plausible untreated-border comparators, rather than forcing a pooled ATT.

#### 2. Make assignment-level inference the default, not a robustness appendix item
- **Issue:** Region-clustered SEs are not valid as the primary inferential basis with six treated border segments.
- **Why it matters:** A paper cannot pass without valid inference.
- **Concrete fix:** For every main estimand, provide inference based on the actual assignment structure: segment-level RI/permutation inference, and if possible complementary few-cluster methods. Relegate region-clustered SEs to secondary status.

#### 3. Resolve the contradiction between “not low power” and “design lacks power”
- **Issue:** The paper alternates between region-level RI (p = 0.002) and segment-level RI (p = 0.67) without a coherent inferential framework.
- **Why it matters:** This undermines confidence in the empirical interpretation.
- **Concrete fix:** Decide which level corresponds to the actual treatment assignment (segment) and structure the narrative around it. If the segment-level RI is primary, the paper must plainly say that the design has limited power at the relevant level.

#### 4. Reassess the role of CS as preferred estimator
- **Issue:** The manuscript implies CS addresses national trend confounding, which it does not.
- **Why it matters:** The preferred estimate may be presented as more credible than it is.
- **Concrete fix:** Either incorporate time-varying country controls in a design where they are meaningful, or stop presenting CS as solving the principal confounding problem. Clarify that heterogeneity-robust staggered DiD solves one problem, not the main one.

#### 5. Reframe the conclusion to match the evidence
- **Issue:** The current conclusion is too confident about a null effect.
- **Why it matters:** Claim calibration is central for publication readiness.
- **Concrete fix:** Recast the main finding as: naive negative estimates are not robust to better controls and assignment-level inference; aggregate annual regional data are insufficient to identify a stable causal effect of these controls.

### 2. High-value improvements

#### 6. Strengthen treatment measurement with exposure intensity
- **Issue:** Border-adjacency is a very coarse proxy for treatment.
- **Why it matters:** Mismeasurement likely attenuates or distorts effects.
- **Concrete fix:** Construct exposure measures using pre-treatment cross-border commuting intensity, major controlled crossings, traffic volumes, bridge/tunnel dependence, or distance to treated crossing points. Show dose-response patterns rather than only binary treatment.

#### 7. Address spillovers explicitly
- **Issue:** Untreated border and interior regions may be indirectly affected.
- **Why it matters:** Spillovers violate standard DiD comparisons.
- **Concrete fix:** Add analyses by distance to treated border segments, exclude adjacent potentially affected controls, or model spillover rings. Even reduced-form evidence would help.

#### 8. Narrow the substantive focus of secondary outcomes
- **Issue:** Employment and sectoral results are currently too weakly identified to support mechanism discussion.
- **Why it matters:** They distract from the main design challenge.
- **Concrete fix:** Either strengthen these analyses with more credible control structures/inference or explicitly label them exploratory and de-emphasize them.

#### 9. Clarify which comparisons identify each specification
- **Issue:** It is hard to tell how much weight comes from interior vs border controls, and from which countries.
- **Why it matters:** Transparency about identifying variation is essential in staggered DiD with sparse treatment support.
- **Concrete fix:** Provide decomposition tables: by country, by segment, by control type, and by estimator support.

### 3. Optional polish

#### 10. Report simultaneous inference and fewer highlighted event-study points
- **Issue:** The discussion highlights isolated dynamic coefficients despite noisy endpoints and multiple testing.
- **Why it matters:** Avoids over-reading noisy dynamics.
- **Concrete fix:** Emphasize joint pre-trend tests and simultaneous bands, and reduce narrative attention to single event-time estimates.

#### 11. Tighten literature framing around what the paper actually learns
- **Issue:** The current contribution claim is broader than warranted.
- **Why it matters:** Better positioning improves credibility.
- **Concrete fix:** Frame the paper as a cautionary empirical assessment of how difficult it is to identify the local aggregate effects of “soft” border frictions with regional annual data.

---

## 7. Overall assessment

### Key strengths
- Important and timely policy question.
- Good institutional background and clear motivation.
- Awareness of modern staggered DiD concerns.
- Honest presentation of several diagnostics that, to the author’s credit, reveal weaknesses in naive TWFE.
- Useful emphasis on the difference between “soft” identity checks and full hard-border reversion.

### Critical weaknesses
- No clearly credible counterfactual for treated border regions in several countries.
- Heavy reliance on control groups that the paper’s own placebo tests show are problematic.
- Main inference is not aligned with the actual treatment-assignment level.
- Preferred estimator (CS) is asked to solve a confounding problem it does not solve.
- Conclusions overstate confidence in a null effect relative to the fragility of the design.

### Publishability after revision
I do not think this is close to acceptance at a top general-interest journal or AEJ:EP in its current form. However, I do think there is a potentially publishable paper here if the empirical strategy is rebuilt and the claim is reframed more modestly. The most promising path is to turn the paper into a more disciplined analysis of what can and cannot be learned from regional aggregate data about these Schengen controls, with inference and identification anchored at the segment level and with much sharper attention to untreated-border comparators and exposure intensity.

DECISION: REJECT AND RESUBMIT